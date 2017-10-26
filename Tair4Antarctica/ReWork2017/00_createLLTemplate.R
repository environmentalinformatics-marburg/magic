rm(list=ls())
template_raw <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Overall/dem_crop.tif")
projection(template_raw) <- "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

template_wc <- raster("/home/hanna/Downloads/wc2.0_10m_tmin/wc2.0_10m_tmin_07.tif")
#plot(template_wc)
e <- drawExtent()
template_wc <- crop(template_wc, c(-190,190,-95,-58))
writeRaster(template_wc,"/media/hanna/data/Antarctica/ReModel2017/data/raster/template_ll.tif" )
test <- projectRaster(template_wc,template_raw)
plot(test)
