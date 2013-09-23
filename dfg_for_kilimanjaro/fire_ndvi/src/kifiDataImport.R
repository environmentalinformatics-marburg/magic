### Environmental stuff

# Workspace clearance
rm(list = ls(all = T))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/pa_NDown/ki_modis_ndvi/"}, 
       "Windows" = {path.wd <- "G:/ki_modis_ndvi"})
setwd(path.wd)

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal")
sapply(lib, function(...) require(..., character.only = T))

fun <- paste("src", c("kifiRemoveDuplicates.R", "kifiExtractDoy.R"), sep = "/")
sapply(fun, source)


### Data import

# Stack MODIS fire data
registerDoParallel(cl <- makeCluster(n.cores <- 4))
modis.fire.stacks <- foreach(i = c("MOD.*FireMask", "MYD.*FireMask")) %do% {
  tmp.fls <- list.files("data/MODIS_ARC/PROCESSED/md14_tmp/", 
                        pattern = i, recursive = T, full.names = T)

  tmp.stack <- foreach(j = tmp.fls, .packages= lib) %dopar%
    projectRaster(crop(stack(j), extent(37, 37.72, -3.4, -2.84)), 
                  crs = "+init=epsg:32737", method = "ngb", overwrite = T,
                  filename = paste("data/crop", basename(j), sep = "/"))
  return(tmp.stack)
}

# modis.fire.stacks <- foreach(i = c("MOD.*FireMask", "MYD.*FireMask")) %do% {
#   tmp.fls <- list.files("data/crop", pattern = i, recursive = T, full.names = T)
#   
#   tmp.stack <- foreach(j = tmp.fls, .packages= lib) %dopar% stack(j)
#   return(tmp.stack)
# }

# Unstack RasterStack objects 
modis.fire.rasters <- foreach(i = modis.fire.stacks) %do% {
  Reduce("append", foreach(j = i, .packages = lib) %dopar% {
    if (nlayers(j) == 1) return(j[[1]]) else return(unstack(j))
  })
}

# Remove duplicated RasterLayers
modis.fire.rasters <- kifiRemoveDuplicates(hdf.path = "data/MODIS_ARC", 
                                           hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
                                           data = modis.fire.rasters, 
                                           n.cores = 4)

# Import information about availability of MOD/MYD14A1
# kifiExtractDoy(hdf.path = "data/MODIS_ARC", 
#                hdf.doy.path = "data/md14_doy_availability.csv", 
#                hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
#                n.cores = 4)
modis.fire.avl <- read.csv("data/md14_doy_availability.csv")

# Change filepath of MODIS Terra and Aqua data (necessary when switching from Linux to Windows)
modis.fire.rasters <- foreach(i = modis.fire.rasters) %do% {
  foreach(j = seq(i)) %do% {
    tmp <- i[[j]]
    tmp@file@name <- gsub("/media/pa_NDown", "G:", tmp@file@name)
    return(tmp)
  }
}


### Merge MODIS Terra and Aqua

overlay.exe = T
overlay.write = T

if (overlay.exe) {
  modis.fire.overlay <- foreach(i = seq(nrow(modis.fire.avl)), .packages = lib) %dopar% {
    if (modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[1]][[modis.fire.avl[i, 3]]], modis.fire.rasters[[2]][[modis.fire.avl[i, 5]]], fun = function(x,y) {x*10+y}, 
              filename = if (overlay.write) paste0("data/overlay/md14a1/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j")) else "", 
              format = "GTiff", overwrite = T)
    } else if (modis.fire.avl[i, 2] & !modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[1]][[modis.fire.avl[i, 3]]], fun = function(x) {x*10}, 
              filename = if (overlay.write) paste0("data/overlay/md14a1/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j")) else "", 
              format = "GTiff", overwrite = T)
    } else if (!modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[2]][[modis.fire.avl[i, 5]]], fun = function(x) {x}, 
              filename = if (overlay.write) paste0("data/overlay/md14a1/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j")) else "", 
              format = "GTiff", overwrite = T)
    } else {
      NA
    }
  }
} else {
  tmp <- list.files("data/overlay/md14a1", full.names = T)
  modis.fire.overlay <- foreach(i = tmp, .packages = lib) %dopar% raster(i)
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

foreach(i = modis.fire.overlay, .packages = lib) %dopar% {
  reclassify(i, rcl.mat, right = NA, overwrite = T,
             filename = if (reclass.write) {
               tmp <- basename(substr(i@file@name, 1, nchar(i@file@name) - 4))
               paste0("data/reclass/md14a1/", tmp) } else "", 
             format = "GTiff")
}

# Deregister parallel backend
stopCluster(cl)
