## Script adds IMERG estimations to an evaluation table that includes observed
# and predicted rainfall for South Africa weather stations
rm(list=ls())
library(Rsenal)
library(caret)
library(Rainfall)
processRaster <- FALSE # FALSE if only statistics are to be calculated
#and raster already exist
### Set data paths #############################################################
pathorig <- getwd()
setwd("/media/memory01/data/IDESSA/Results/Evaluation/")
stationpath <- "/media/memory01/data/IDESSA/statdat/"
gpmout <- "/media/memory01/data/IDESSA/Results/IMERG/"
IMERGpath <- gpmout
### Load data ##################################################################
template <- raster("/media/memory01/data/IDESSA/Results/Predictions/template.tif")
#template <- projectRaster(template,crs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0")
evaldat <- get(load("evaluationData_all.RData"))
evaldat <- evaldat[as.numeric(as.character(evaldat$Date))>201403120000,]
evaldat <- evaldat[as.numeric(as.character(evaldat$Date))<201409312400,]
stations <- readOGR(paste0(stationpath,"allStations.shp"),"allStations")
stations <- spTransform(stations,
                        CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"))
IMERGfiles <- list.files("/media/memory01/data/data01/RainfallProducts/IMERG_GPM_2014/",
                         recursive=1,pattern=".HDF5$",full.names = TRUE)
IMERGfileNames <- list.files("/media/memory01/data/data01/RainfallProducts/IMERG_GPM_2014/",
                             recursive=1,pattern=".HDF5$",full.names = FALSE)
results <- data.frame()

for (date in unique(substr(evaldat$Date,1,10))){
  ### Prepare data matching ####################################################
  subs <- evaldat[substr(evaldat$Date,1,10)==date,]
  if (processRaster){
    yearmonthday <- substr(date,1,8)
    hour <- substr(date,9,10)
    
    ### Load, reproject and aggregate matching imerg data ########################
    gpms <- IMERGfiles[substr(IMERGfileNames,26,33)==yearmonthday&
                         substr(IMERGfileNames,36,37)==hour]
    gpmStack <- tryCatch(stack(rasterizeIMERG(gpms[1]),
                               rasterizeIMERG(gpms[2])),
                         error = function(e)e)
    if(inherits(gpmStack, "error")){
      next
    }
    gpmStack <- projectRaster(gpmStack,template)
    gpmStack <- crop(gpmStack,template)
    gpmStack <- calc(gpmStack,mean)
    if (!processRaster){
      writeRaster(gpmStack,paste0(gpmout,"IMERG_",date,".tif"),overwrite=TRUE)
    }
  }
  if(!processRaster){
    gpmStack <- raster(paste0(gpmout,"IMERG_",date,".tif"))
  }
  gpmExtr <- data.frame("Date"=date,"Station"=as.character(stations@data$Name),
                        "IMERG"=extract(gpmStack,stations))
  ### Merge with evaluation table ################################################
  results <- rbind(results,merge(subs, gpmExtr, by.x = "Station",
                                 "Station"))
}
results$RA_IMERG <- "NoRain"
results$RA_IMERG[results$IMERG>0] <- "Rain"
results$RA_IMERG <- factor(results$RA_IMERG,levels=c("Rain","NoRain"))
save(results,file="IMERGComparison.RData")
setwd(pathorig)