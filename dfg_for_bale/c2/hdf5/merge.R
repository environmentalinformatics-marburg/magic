setwd("/media/fdetsch/XChange/MODIS_ARC/PROBA-V")

fls <- list.files(pattern = "NDVI.tif$")

lst <- lapply(fls, function(i) {
  rst <- raster(i)
  crop(rst, spy, snap = "out")
})

mrg <- do.call(raster::merge, lst)

