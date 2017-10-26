rm(list=ls())
library(rgdal)
library(raster)
library(rgeos)
library(Rainfall)
mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/forPaper/"
ndvipath <- paste0(mainpath,"/ndvi")
auxpath <- paste0(mainpath,"/auxiliary")
shppath <- paste0(mainpath,"/shp")
outpath <- paste0(mainpath,"/modeldat")
setwd(auxpath)
template <- projectRaster(raster("cloudmask_201306161200.tif"),
                          crs="+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

load(paste0(ndvipath,"/dataset_withNDVI.RData"))
dataset <- dataset[complete.cases(dataset$ndvi),]
shp <- readOGR(paste0(shppath,"/WeatherStations.shp"),"WeatherStations")
dem <- getData("alt",country="ZAF",mask=FALSE)[[1]]
#writeRaster(dem,"dem.tif")
tmean <- getData('worldclim', var='tmean', res=2.5)
tmean <- mean(crop(tmean,dem))/10
writeRaster(tmean,"Tmean.tif")
prescum <- getData('worldclim', var='prec', res=2.5)

prescum <- crop(prescum,dem)
precmax <- max(prescum)
precmax_month <-precmax
values(precmax_month) <- NA
for (i in 1:ncell(precmax)){
  if (is.na(precmax[i])){next}
  val <- which(prescum[i]==precmax[i])
  precmax_month[i]<- val
}
seasonality <- precmax_month
seasonality[precmax_month%in%c(1,12)] <- 1
seasonality[precmax_month%in%c(2)] <- 2
seasonality[precmax_month%in%c(3:5)] <- 3
seasonality[precmax_month%in%c(6:11)] <- 4



prescum <- sum(prescum)
writeRaster(prescum,"Prec.tif")
writeRaster(seasonality,"PrecSeason.tif")
biomes <- raster("biome.tif")


fill.na <- function(x, i=13) {
  Mode <- function(x) {
    x <- x[!is.na(x)]
    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
  }
  if( is.na(x)[i] ) {
    return( Mode(x))
  } else {
    return( x[i] )
  }
}
#biomes <- focal(biomes, w = matrix(1,5,5), fun = fill.na, 
#            pad = TRUE, na.rm = FALSE )
dem <- focal(dem, w = matrix(1,5,5), fun = fill.na, 
            pad = TRUE, na.rm = FALSE )
#writeRaster(biomes,"biome.tif",overwrite=TRUE)
writeRaster(dem,"dem.tif",overwrite=TRUE)

#6,8=Grassland,forest = 1
#1,7 = Savanna,wüste =2
#2,3,5 Karoo , Albany thicket =1
#4,16 Fynbos  ->coastal =3
biomes_agg <- biomes
biomes_agg[values(biomes)%in%c(6,8)] <- 1
biomes_agg[values(biomes)%in%c(1,7)] <- 2
biomes_agg[values(biomes)%in%c(2,3,5)] <- 1
biomes_agg[values(biomes)%in%c(4,16)] <- 3
writeRaster(biomes_agg,"Biome_agg.tif",overwrite=TRUE)

#create continentality index
base <- readOGR(paste0(shppath,"/TM_WORLD_BORDERS-0.3.shp"),
                "TM_WORLD_BORDERS-0.3")
base <- crop(base,c(-23,85,-60,38))
base <- gUnionCascaded(base)
base <- rasterize(base,raster(ext=extent(base),ncols=500,nrows=500))
base[is.na(base)]<-2
dist <- gridDistance(base,origin=2)
dist <- crop(dist,dem)
dist <- stretch(dist,0,100)
writeRaster(dist,"Continent.tif")


auxdat <- data.frame("Station"=shp$plot,"Biome"=extract(biomes,shp),
                     "Dem"=extract(dem,shp),
                     "Tmean"=extract(tmean,shp),
                     "Prec"=extract(prescum,shp),
                     "Continent"=extract(dist,shp),
                     "Biome_agg"=extract(biomes_agg,shp),
                     "Precseason"=extract(seasonality,shp))
shp <- shp[shp$plot%in%unique(dataset$Station),]
shp <- merge(shp,auxdat,by.x="plot",by.y="Station")
shp <- shp[shp$source=="SAWS",]

dataset <- dataset[unique(dataset$Station)%in%shp$plot,]
dataset <- merge(dataset,shp,by.x="Station",by.y="plot")
dataset$source <- as.character(dataset$source)
save(dataset,file=paste0(outpath,"/modeldata.RData"))
writeOGR(shp,paste0(shppath,"/selectedStations.shp"),
         "selectedStations",driver="ESRI Shapefile",
         overwrite=TRUE)

dist_res <- resample(dist,template)
biomes_res <- resample(biomes,template)
prescum_res <- resample(prescum,template)
tmean_res <- resample(tmean,template)
dem_res <- resample(dem,template)
seasonality <- resample(seasonality,template)
biomes_agg_res <- resample(biomes_agg,template)
predraster <- stack(dist_res,biomes_res,prescum_res,
                    tmean_res,dem_res,biomes_agg_res,seasonality)
names(predraster) <- c("Continentality","Biome","Prec",
                       "Tmean","Dem","Biome_agg","Precseason")
writeRaster(predraster,"predictors.tif",overwrite=TRUE)
