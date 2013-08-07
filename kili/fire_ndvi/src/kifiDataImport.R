# Required packages and functions
lib <- c("doParallel", "raster", "rgdal")
sapply(lib, function(...) require(..., character.only = T))

source("D:/ki_modis_ndvi/src/kifiRemoveDuplicates.R")


### Data import

# Stack MODIS fire data
registerDoParallel(clstr <- makeCluster(n.cores <- 4))
modis.fire.stacks <- lapply(c("MOD.*FireMask", "MYD.*FireMask"), function(i) {
  tmp.fls <- list.files("D:/ki_modis_ndvi/data/MODIS_ARC/", pattern = i, recursive = TRUE, full.names = TRUE)
  tmp.stack <- foreach(i = tmp.fls, .packages= "raster") %dopar%
    stack(i)
  return(tmp.stack)
})
stopCluster(clstr)

# Decompose RasterStack objects to single layers
clstr <- makePSOCKcluster(n.cores)
clusterEvalQ(clstr, c(library(raster), library(rgdal)))
modis.fire.rasters <- parLapply(clstr, modis.fire.stacks, function(i) {
  Reduce("append", lapply(i, unstack))
})

# Remove duplicated RasterLayers
modis.fire.rasters <- kifiRemoveDuplicates(hdf.path = "D:/ki_modis_ndvi/data/MODIS_ARC", 
                                           hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
                                           data = modis.fire.rasters, 
                                           n.cores = 4)

# Import information about MODIS Terra and Aqua availability of fire product M.D14A1
modis.fire.avl <- read.csv("D:/ki_modis_ndvi/data/m.d14_doy_availability.csv", header = TRUE)

# Change filepath of MODIS Terra and Aqua data (necessary when switching from Linux to Windows)
modis.fire.rasters <- lapply(modis.fire.rasters, function(i) {
  lapply(seq(i), function(j) {
    tmp <- i[[j]]
    tmp@file@name <- gsub("/media/pa_NDown", "D:", tmp@file@name)
    return(tmp)
  })
})


### Merge MODIS Terra and Aqua

overlay.exe = TRUE
overlay.write = TRUE
clusterExport(clstr, c("modis.fire.avl", "modis.fire.rasters", "overlay.exe", "overlay.write"))

if (overlay.exe) {
  modis.fire.overlay <- lapply(seq(nrow(modis.fire.avl)), function(i) {
    if (modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[1]][[modis.fire.avl[i, 3]]], modis.fire.rasters[[2]][[modis.fire.avl[i, 5]]], fun = function(x,y) {x*10+y}, 
              filename = if (overlay.write) paste("D:/ki_modis_ndvi/data/overlay/md14a1/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j"), sep = "") else "", 
              format = "GTiff", overwrite = TRUE)
    } else if (modis.fire.avl[i, 2] & !modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[1]][[modis.fire.avl[i, 3]]], fun = function(x) {x*10}, 
              filename = if (overlay.write) paste("D:/ki_modis_ndvi/data/overlay/md14a1/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j"), sep = "") else "", 
              format = "GTiff", overwrite = TRUE)
    } else if (!modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[2]][[modis.fire.avl[i, 5]]], fun = function(x) {x}, 
              filename = if (overlay.write) paste("D:/ki_modis_ndvi/data/overlay/md14a1/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j"), sep = "") else "", 
              format = "GTiff", overwrite = TRUE)
    } else {
      NA
    }
  })
} else {
  tmp <- list.files("D:/ki_modis_ndvi/data/overlay/md14a1", full.names = TRUE)
  clusterExport(clstr, "tmp")
  modis.fire.overlay <- parLapply(clstr, tmp, raster)
}


### Reclassification

# Reclassification matrix
rcl.mat <- matrix(c(0, 7, 0,   # --> 0
                    10, 17, 0, 
                    20, 27, 0, 
                    30, 37, 0,
                    40, 47, 0, 
                    50, 57, 0, 
                    60, 67, 0, 
                    70, 77, 0, 
                    8, 9, 1,   # --> 1
                    18, 19, 1, 
                    28, 29, 1, 
                    38, 39, 1,
                    48, 49, 1, 
                    58, 59, 1, 
                    68, 69, 1, 
                    78, 99, 1), ncol = 3, byrow = TRUE)

# Reclassify
reclass.write = TRUE
clusterExport(clstr, c("modis.fire.overlay", "rcl.mat", "reclass.write"))

parLapply(clstr, modis.fire.overlay, function(i) {
  reclassify(i, rcl.mat, right=NA, overwrite=TRUE,
             filename = if (reclass.write) {
               tmp <- basename(substr(i@file@name, 1, nchar(i@file@name) - 4))
               paste("D:/ki_modis_ndvi/data/reclass/md14a1/", tmp, sep = "") } else "", 
             format = "GTiff")
})
