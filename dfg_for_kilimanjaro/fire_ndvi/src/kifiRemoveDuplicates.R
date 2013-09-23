kifiRemoveDuplicates <- function(hdf.path, 
                                 hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
                                 data,
                                 n.cores = 1,
                                 ...) {
  
  # Packages
  lib <- c("doParallel", "raster")
  sapply(lib, function(x) stopifnot(require(x, character.only = T)))
  
  # Parallelisation
  registerDoParallel(clstr <- makeCluster(n.cores))
  
  # Retrieve DAYSOFYEAR for both TERRA (MOD) and AQUA (MYD)
  hdf.info <- foreach(i = hdf.pattern, .packages = "rgdal") %dopar% {
    tmp.fls <- list.files(hdf.path, pattern = i, recursive = T, full.names = T)
    
    tmp.fls.doy <- sapply(tmp.fls, function(j) {
      tmp.info <- GDALinfo(j, returnScaleOffset = F, silent = T)
      tmp.doy <- attr(tmp.info, "mdata")[grep("DAYSOFYEAR", attr(tmp.info, "mdata"))]
      
      return(unlist(strsplit(substr(tmp.doy, 12, nchar(tmp.doy)), ", ")))
    })
    
    return(tmp.fls.doy)
  }
  
  # Deregister parallel backend
  stopCluster(clstr)
  
  # Remove duplicated RasterLayers from data
  hdf.doy.dupl <- lapply(c(1, 2), function(i) which(duplicated(as.Date(do.call("c", hdf.info[[i]])))))
  
  data <- lapply(seq(data), function(i) {
    data[[i]][-hdf.doy.dupl[[i]]]
  })
  
  # Return revised data
  return(data)
  
}

# ### Call
# 
# tmp <- kifiRemoveDuplicates(hdf.path = "/media/pa_NDown/ki_modis_ndvi/data/MODIS_ARC", 
#                             hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
#                             data = modis.fire.rasters, 
#                             n.cores = 4)