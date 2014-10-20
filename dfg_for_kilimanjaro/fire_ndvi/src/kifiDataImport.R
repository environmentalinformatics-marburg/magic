### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {dsn <- "/media/fdetsch/XChange/kilimanjaro/ndvi/"}, 
       "Windows" = {dsn <- "D:/kilimanjaro/ndvi"})
setwd(dsn)

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal", "MODIS")
sapply(lib, function(...) require(..., character.only = TRUE))

fun <- paste("src", c("kifiRemoveDuplicates.R", "kifiExtractDoy.R"), sep = "/")
sapply(fun, source)

# Parallelization
registerDoParallel(cl <- makeCluster(3))


### Data import

# Update MODIS collection, 
# extract relevant SDS layers
# and reproject to EPSG:21037 (UTM-37S, CLRK80)
MODISoptions(localArcPath = paste0(dsn, "data/MODIS_ARC/"), 
             outDirPath = paste0(dsn, "data/MODIS_ARC/PROCESSED/"))

for (i in c("MOD14A1", "MYD14A1"))
  runGdal(i, 
          tileH = 21, tileV = 9, SDSstring = "1100", 
          outProj = "EPSG:21037", job = "fire_clrk")

# Kili extent
template.ext.ll <- extent(37, 37.72, -3.4, -2.84)
template.rst.ll <- raster(ext = template.ext.ll)
template.rst.utm <- projectExtent(template.rst.ll, crs = "+init=epsg:21037")

### Data import and cropping
modis.fire.stacks <- foreach(i = c("MOD.*FireMask", "MYD.*FireMask"), 
                             .packages = lib) %dopar% {
                            
  # Avl files                             
  tmp.fls <- list.files("data/MODIS_ARC/PROCESSED/fire_clrk", 
                        pattern = i, recursive = TRUE, full.names = TRUE)

  # Import and crop
  tmp.stack <- foreach(j = tmp.fls, .combine = "stack") %do% {
    rst <- stack(j)
    rst_crp <- crop(rst, template.rst.utm, format = "GTiff", bylayer = FALSE,
                    filename = paste0("data/md14a1/CRP_", basename(j)),  
                    overwrite = TRUE)
    return(rst_crp)
  }
  
  return(tmp.stack)
}

modis.fire.rasters <- foreach(i = c("MOD.*FireMask", "MYD.*FireMask"), 
                             .packages = lib) %dopar% {
  tmp.fls <- list.files("data/md14a1", pattern = paste("CRP", i, sep = ".*"), 
                        recursive = TRUE, full.names = TRUE)
  
  tmp_rst <- stack(tmp.fls)
  return(tmp_rst)
}

# Remove duplicated RasterLayers
modis.fire.rasters.rmdupl <- kifiRemoveDuplicates(hdf.path = "data/MODIS_ARC", 
                                           hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
                                           data = modis.fire.rasters)

# Import information about availability of MOD/MYD14A1
kifiExtractDoy(hdf.path = "data/MODIS_ARC", 
               hdf.doy.path = "data/md14a1/md14_doy_availability.csv", 
               hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
               n.cores = 3)
modis.fire.avl <- read.csv("data/md14a1/md14_doy_availability.csv")


### Merge MODIS Terra and Aqua

overlay.exe <- TRUE
overlay.write <- TRUE

if (overlay.exe) {
  modis.fire.overlay <- foreach(i = seq(nrow(modis.fire.avl)), .packages = lib) %dopar% {
    if (modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[1]][[modis.fire.avl[i, 3]]], modis.fire.rasters[[2]][[modis.fire.avl[i, 5]]], fun = function(x,y) {x*10+y}, 
              filename = if (overlay.write) paste0("data/md14a1/merge/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j")) else "", 
              format = "GTiff", overwrite = TRUE)
    } else if (modis.fire.avl[i, 2] & !modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[1]][[modis.fire.avl[i, 3]]], fun = function(x) {x*10}, 
              filename = if (overlay.write) paste0("data/md14a1/merge/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j")) else "", 
              format = "GTiff", overwrite = TRUE)
    } else if (!modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.rasters[[2]][[modis.fire.avl[i, 5]]], fun = function(x) {x}, 
              filename = if (overlay.write) paste0("data/md14a1/merge/md14a1_", strftime(modis.fire.avl[i, 1], format = "%Y%j")) else "", 
              format = "GTiff", overwrite = TRUE)
    } else {
      NA
    }
  }
} else {
  tmp <- list.files("data/md14a1/merge", pattern = "^md14a1", full.names = TRUE)
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
reclass.write <- TRUE

foreach(i = modis.fire.overlay, .packages = lib) %dopar% {
  reclassify(i, rcl.mat, right = NA, overwrite = TRUE,
             filename = if (reclass.write) {
               tmp <- basename(substr(i@file@name, 1, nchar(i@file@name) - 4))
               paste0("data/reclass/md14a1/", tmp) } else "", 
             format = "GTiff")
}

# Deregister parallel backend
stopCluster(cl)
