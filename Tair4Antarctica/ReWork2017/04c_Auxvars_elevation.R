rm(list=ls())
library(rgdal)
library(raster)
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")

alt <- raster(paste0(rasterdata,"dem.tif"))

alt_recl <- alt
alt_recl[alt<=1000] <- 1
alt_recl[alt>1000&alt<=2000] <- 2
alt_recl[alt>2000&alt<=3000] <- 3
alt_recl[alt>3000] <- 4

writeRaster(alt_recl,paste0(rasterdata,"dem_recl.tif"))
