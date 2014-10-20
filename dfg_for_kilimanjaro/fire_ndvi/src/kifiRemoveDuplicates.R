kifiRemoveDuplicates <- function(hdf.path, 
                                 hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
                                 data,
                                 ...) {
  
  # Packages
  lib <- c("raster")
  sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))
  
  # Retrieve DAYSOFYEAR for both TERRA (MOD) and AQUA (MYD)
  hdf.info <- lapply(hdf.pattern, function(i) {
    tmp.fls <- list.files(hdf.path, pattern = i, recursive = TRUE, 
                          full.names = TRUE)
    
    tmp.fls.doy <- sapply(tmp.fls, function(j) {
      tmp.info <- GDALinfo(j, returnScaleOffset = FALSE, silent = TRUE)
      tmp.doy <- attr(tmp.info, "mdata")[grep("DAYSOFYEAR", attr(tmp.info, "mdata"))]
      
      return(unlist(strsplit(substr(tmp.doy, 12, nchar(tmp.doy)), ", ")))
    })
    
    return(tmp.fls.doy)
  })
  
  # Remove duplicated RasterLayers from data
  hdf.doy.dupl <- lapply(c(1, 2), function(i) which(duplicated(as.Date(do.call("c", hdf.info[[i]])))))
  
  data <- lapply(seq(data), function(i) {
    data[[i]][[-hdf.doy.dupl[[i]]]]
  })
  
  # Return revised data
  return(data)
  
}
