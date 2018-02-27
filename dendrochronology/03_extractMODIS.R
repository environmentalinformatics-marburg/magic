#02 extractMODIS
rm(list=ls())
library(raster)
mainpath <- "/mnt/sd19006/data/processing_data/modis_europe/"
datapath <- paste0(mainpath,"/MODIS/mcd11a1-europe/")
shppath <- paste0(mainpath,"/vector/")
outpath <- paste0(mainpath,"/MODIS_extracted/")
tmppath <- paste0(mainpath,"/tmp/")

rasterOptions(tmpdir = tmppath)

locations <- read.csv(paste0(shppath,"Koordinaten.csv"))
locations <- SpatialPointsDataFrame(locations[,c(3,2)],data=data.frame(locations$X),
                                    proj4string = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
locations <- spTransform(locations, 
                         CRS("+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs"))
files <- list.files(datapath,full.names = TRUE)
MOD <- files[grepl("MOD11",files)]
MYD <- files[grepl("MYD11",files)]

MODISdats <- list(MOD[grepl("LST_Day",MOD)],MOD[grepl("LST_Night",MOD)],
                  MYD[grepl("LST_Day",MYD)],MYD[grepl("LST_Night",MYD)])
names(MODISdats) <- c("MOD_DAY","MOD_NIGHT","MYD_DAY","MYD_NIGHT")

for (i in 1:length(MODISdats)){ #for Aqua/Terra and Day/Night
  dats <- MODISdats[[i]]
  results <- data.frame(matrix(ncol=length(locations)+1,nrow=length(dats)))
  for (k in 1:length(dats)){
    rst <- tryCatch(raster(dats[k]),error = function(e)e) #read the raster
    if (inherits(rst,"error")){next}
    if (grepl("DAY",names(MODISdats)[i])){
    doy <- substr(dats[k],nchar(dats)[k]-22,nchar(dats)[k]-16) #extract the date
    } else{
      doy <- substr(dats[k],nchar(dats)[k]-24,nchar(dats)[k]-18)
    }
    results[k,1] <- doy
    results[k,2:(length(locations)+1)] <- t(extract(rst,locations)) #extract LST for locations
  }
  names(results)[2:(length(locations)+1)] <- as.character(locations$locations.X)
  names(results)[1] <- "DOY"
  results$Sensor <- substr(names(MODISdats)[i],1,3)
  results$Daytime <- substr(names(MODISdats)[i],5,9)
  save(results,file=paste0(outpath,"LST_",names(MODISdats)[i],".RData"))
  print(i)
}

