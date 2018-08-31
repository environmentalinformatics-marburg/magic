rm(list=ls())
library(raster)
library(sf)

mainpath <- "/home/hanna/Documents/Projects/SpatialCV/MOF/"
datapath <- paste0(mainpath,"/data")
rasterpath <- paste0(datapath,"/raster")
vectorpath <- paste0(datapath,"/vector")

aerial <- stack(paste0(rasterpath,"/geonode_ortho_muf_1m.tif"))
names(aerial)<- c("blue","green","red")
distances <- stack(paste0(rasterpath,"/distances.grd"))
predictors <- stack(aerial,distances)
training_sf <- st_read(paste0(vectorpath,"/lcc_training_areas_20180126.shp"))
training_df <- extract(predictors,training_sf)
training_df <- merge(training_df,training_sf)
