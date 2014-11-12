###Spatial Aggregation (5 pixel zusammenfassen)
library(raster)

datapath="/media/hanna/ubt_kdata_0005/pub_rapidminer/spatialAggregation/rain/rain_predicted/3h/"
setwd(datapath)
resultpath="spatialAggregation"

dir.create(resultpath)

files=list.files(pattern=".rst$")
for (i in 1:length(files)){
  r=raster(files[i])
  r=aggregate(r,5)
  writeRaster(r,paste0(resultpath,"/agg_",files[i],".tif"),overwrite=TRUE)
  
}

