rm(list=ls())
library(raster)
library(rgdal)
library(Rsenal)


regcmpath ="/media/hanna/data/Antarctica/data/RegCM_2013/tiffs/"
outpath_A <- "/media/hanna/data/Antarctica/results/predictions/RegCMExtent/"
outpath_B <- "/media/hanna/data/Antarctica/results/predictions/RegCMRes/"
predpath <- "/media/hanna/data/Antarctica/results/predictions/"
setwd(predpath)
predictions <- list.files(,pattern=".tif$")
rasterOptions(tmpdir = "/media/hanna/data/Antarctica/rastertmp")

for (i in 1:length(predictions)){
  regCM <- raster(list.files(regcmpath,full.names = TRUE)[1])
  pred <- raster(predictions[i])
  proj4string(regCM)<-proj4string(pred)
  
  pred_regCMExt <- crop(pred,regCM)
  pred_regCMRes <- resample(pred_regCMExt,regCM)
  
  writeRaster(pred_regCMExt,paste0(outpath_A,"predictedTair_",
                                   substr(predictions[i],nchar(predictions[i])-10,nchar(predictions[i])-4),
                                   "_regCMExt.tif"),overwrite=TRUE)
  
  writeRaster(pred_regCMRes,paste0(outpath_B,"predictedTair_",
                                   substr(predictions[i],nchar(predictions[i])-10,nchar(predictions[i])-4),
                                   "_regCMRes.tif"),overwrite=TRUE)
  gc()
  file.remove(list.files("/media/hanna/data/Antarctica/rastertmp"))
}