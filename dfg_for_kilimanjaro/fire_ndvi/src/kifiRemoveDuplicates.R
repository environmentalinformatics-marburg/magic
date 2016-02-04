kifiRemoveDuplicates <- function(hdf.path, 
                                 hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
                                 data,
                                 ...) {
  
  # Packages
  stopifnot(require(raster))
  
  # Retrieve DAYSOFYEAR for both TERRA (MOD) and AQUA (MYD)
  hdf.info <- lapply(hdf.pattern, function(i) {
    tmp.fls <- list.files(hdf.path, pattern = i, recursive = TRUE, 
                          full.names = TRUE)
    
    tmp.fls.doy <- sapply(tmp.fls, function(j) {
      tmp.info <- GDALinfo(j, returnScaleOffset = FALSE, silent = TRUE)
      mdata <- attr(tmp.info, "mdata")
      tmp.doy <- mdata[grep("DAYSOFYEAR", mdata)]
      
      return(unlist(strsplit(substr(tmp.doy, 12, nchar(tmp.doy)), ", ")))
    })
    
    return(tmp.fls.doy)
  })
  
  # Remove duplicated RasterLayers from data
  hdf.doy.dupl <- lapply(seq(hdf.info), function(i) which(duplicated(as.Date(do.call("c", hdf.info[[i]])))))
  
  data <- lapply(seq(data), function(i) {
    data[[i]][[-hdf.doy.dupl[[i]]]]
  })
  
  # Return revised data
  return(data)
  
}
