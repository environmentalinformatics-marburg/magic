rm(list=ls())
library(rgdal)
library(raster)
library(rgeos)
mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/forPaper/"
ndvipath <- paste0(mainpath,"/ndvi")
auxpath <- paste0(mainpath,"/auxiliary")
shppath <- paste0(mainpath,"/shp")
outpath <- paste0(mainpath,"/modeldat")
setwd(auxpath)


load(paste0(ndvipath,"/dataset_withNDVI.RData"))
dataset <- dataset[complete.cases(dataset$ndvi),]
shp <- readOGR(paste0(shppath,"/WeatherStations.shp"),"WeatherStations")
dem <- getData("alt",country="ZAF",mask=FALSE)[[1]]
tmean <- getData('worldclim', var='tmean', res=2.5)
tmean <- mean(crop(tmean,dem))/10
prescum <- getData('worldclim', var='prec', res=2.5)
prescum <- sum(crop(prescum,dem))
biomes <- raster("biome.tif")

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




auxdat <- data.frame("Station"=shp$plot,"Biome"=extract(biomes,shp),
                     "Dem"=extract(dem,shp),
                     "Tmean"=extract(tmean,shp),
                     "Prec"=extract(prescum,shp),
                     "Continent"=extract(dist,shp))
shp <- shp[shp$plot%in%unique(dataset$Station),]
shp <- merge(shp,auxdat,by.x="plot",by.y="Station")
shp <- shp[shp$source=="SAWS",]

dataset <- dataset[unique(dataset$Station)%in%shp$plot,]
dataset <- merge(dataset,shp,by.x="Station",by.y="plot")
save(dataset,file=paste0(outpath,"/modeldata.RData"))
writeOGR(shp,paste0(shppath,"/selectedStations.shp"),
         "selectedStations",driver="ESRI Shapefile",
         overwrite=TRUE)

