#06_Splitdata

rm(list=ls())
library(raster)
library(lubridate)
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")
modelpath <- paste0(datapath, "/modeldat/")


dat <- get(load(paste0(modelpath,"full_dataset.RData")))
set.seed(100)
trainingYears <- sample(2002:2016,7)
trainingDat <- dat[year(dat$Date)%in%trainingYears,]
testingDat <- dat[!year(dat$Date)%in%trainingYears,]

save(trainingDat,file=paste0(modelpath,"trainingDat.RData"))
save(testingDat,file=paste0(modelpath,"testingDat.RData"))