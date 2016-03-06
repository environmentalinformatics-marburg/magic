###select stations for comparison study
rm(list=ls())
library(raster)
library(rgdal)
library(rgeos)

stations <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationData.shp","StationData")
#domain <- raster("/media/hanna/data/Antarctica/data/RegCM_2013/tiffs/RegCM_AirT_2013040101.tif")
LSTExt <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/MSG_NotNA.shp","MSG_NotNA")

#stations_select <- crop(stations, extent(domain))
#stations_select<-intersect(stations_select,LSTExt)
stations_select<-intersect(stations,LSTExt)
writeOGR(stations_select,"/media/hanna/data/Antarctica/data/ShapeLayers/StationDataAnt.shp",
         "StationDataRoss",driver="ESRI Shapefile")

#danach noch manuell pandasouth und evansknoll raus!