rm(list=ls())
library(raster)
setwd("/media/hanna/data/Antarctica/results/predictions/")
outpath <- "/media/hanna/data/Antarctica/results/predictions/monthlyMeans/"
predictions <- list.files(,pattern=".tif$")
dates <- substr(predictions,nchar(predictions)-10,nchar(predictions)-4)
dates <- as.Date(dates, "%Y%j")
months <- format(dates,"%m")

for (i in 12:12){
  #month <- month.abb[i]
  month <- sprintf("%02d", i)
  predictions_subs <- predictions[months==month]
  predictions_stack <- stack(predictions_subs)
  av <- calc(predictions_stack,mean,na.rm=TRUE)
  writeRaster(av,paste0(outpath,"monthlyMean_",month,"_",month.abb[i],".tif"),overwrite=TRUE)
  print(i)
}
      
setwd("/media/hanna/data/Antarctica/results/predictions/monthlyMeans/")
predictions <- list.files(,pattern=".tif$")
predictions <- predictions[substr(predictions,1,7)=="monthly"]
predictions_stack <- stack(predictions)
av <- calc(predictions_stack,mean,na.rm=TRUE)
writeRaster(av,paste0(outpath,"yearlyMean.tif"),overwrite=TRUE)



