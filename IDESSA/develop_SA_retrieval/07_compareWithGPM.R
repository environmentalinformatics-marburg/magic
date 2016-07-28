## Script adds IMERG estimations to an evaluation table that includes observed
# and predicted rainfall for South Africa weather stations
rm(list=ls())
library(Rsenal)
library(caret)
library(Rainfall)
### Set data paths #############################################################
setwd("/media/memory01/data/IDESSA/Results/Evaluation/")
stationpath <- "/media/memory01/data/IDESSA/statdat/"
### Load data ##################################################################
template <- raster("/media/memory01/data/IDESSA/Results/Predictions/Rate/201301010015.tif")
evaldat <- get(load("evaluationData_all.RData"))
evaldat <- evaldat[as.numeric(as.character(evaldat$Date))>201403120000,]
stations <- readOGR(paste0(stationpath,"allStations.shp"),"allStations")
IMERGfiles <- list.files("/media/memory01/data/data01/RainfallProducts/IMERG_GPM_2014/",
                         recursive=1,pattern=".HDF5$",full.names = TRUE)
IMERGfileNames <- list.files("/media/memory01/data/data01/RainfallProducts/IMERG_GPM_2014/",
                             recursive=1,pattern=".HDF5$",full.names = FALSE)

results <- data.frame()

for (date in unique(substr(evaldat$Date,1,10))){
  ### Prepare data matching ######################################################
  subs <- evaldat[substr(evaldat$Date,1,10)==date,]
  yearmonthday <- substr(date,1,8)
  hour <- substr(date,9,10)
  ### Load matching imerg data ###################################################
  gpms <- IMERGfiles[substr(IMERGfileNames,26,33)==yearmonthday&
                       substr(IMERGfileNames,36,37)==hour]
  gpmStack<-tryCatch(stack(rasterizeIMERG(gpms[1]),
                           rasterizeIMERG(gpms[2])),
                     error = function(e)e)
  if(inherits(gpmStack, "error")){
    next
  }
  ### Calculate mm/h #############################################################
  gpmStack <- calc(gpmStack,mean)
  gpmExtr <- data.frame("Date"=date,"Station"=as.character(stations@data$Name),
                        "IMERG"=extract(gpmStack,stations))
  ### Merge with evaluation table ################################################
  results <- rbind(results,merge(subs, gpmExtr, by.x = "Station",
                                 "Station"))
}
save(results,file="IMERGComparison.RData")