# molopo 1km lcc, vegetation reclassification

library(raster)
library(rgdal)
library(sp)

# load all lcc and vvi data
lcc_fls <- list.files("I:/env_info/lcc_1km", full.names = TRUE, pattern = ".tif$")
vvi_fls <- list.files("I:/env_info/tiles_rgb_vvi", full.names = TRUE, pattern = ".tif$")
lcc <- sapply(lcc_fls, FUN = raster::raster)
vvi <- sapply(vvi_fls, FUN = function(i){raster::raster(i, band = 4)})
rm(lcc_fls, vvi_fls)


# for every lcc tile
lcc_veg_re <- lapply(seq(length(lcc)), function(l){
  # vvi mean value per class in the raster
  means <- lapply(seq(lcc[[l]]@data@max), function(m){
    return(mean(vvi[[l]][lcc[[l]]==m]))
  })
  # write the mean values in a vector
  means <- do.call(c, means)
  # find out at which position the maximum vvi value is
  # this is equal to the bush-class
  class_veg <- which(means == max(means))
  # write everything in a list for future analysis
  res <- list(mean_vvi = means, veg = class_veg)
  return(res)
})
saveRDS(lcc_veg_re, file = "F:/ludwig/RData/lcc_vegetation_classes.RDS")


lcc_veg_re <- readRDS("I:/env_info/RData/lcc_vegetation_classes.RDS")
# key for reclassification
veg <- lapply(seq(296), function(k){
  return(lcc_veg_re[[(k)]]$veg)
})
veg <- do.call(c, veg)

key <- data.frame(veg = veg, new = 50)

for(n in seq(296)){
  re <- reclassify(lcc[[n]], rcl = key[n,])
  writeRaster(re, filename = paste0("I:/env_info/output/lcc_reclass", n, ".tif"), overwrite = TRUE)
  print(n)
}

