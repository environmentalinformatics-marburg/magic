kifiExtractDoy <- function(hdf.path, 
                           hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"),
                           hdf.doy.write = T, 
                           hdf.doy.path = ".", 
                           n.cores = 1L, 
                           ...) {

  #########################################################################################
  # Parameters are as follows:
  #
  # hdf.path (character):     Folder containing HDF files. 
  # hdf.pattern (character):  Pattern specifying which files in hdf.path should
  #                           be considered (see ?list.files).
  # hdf.doy.write (logical):  Should extracted days of year (DOY) be stored on 
  #                           the local system?
  # hdf.doy.path (character): Name of the output file. Defaults to current WD if
  #                           not supplied and hdf.doy.write = T.
  # n.cores (integer):        Number of cores to use for parallelization.
  # ...:                      Additional arguments.
  #
  #########################################################################################
  
  # Required packages
  stopifnot(require(doParallel))
  
  # Parallelisation
  registerDoParallel(clstr <- makeCluster(n.cores))
  
  # Retrieve DAYSOFYEAR for both TERRA (MOD) and AQUA (MYD)
  hdf.info <- foreach(i = hdf.pattern, .packages = "rgdal") %dopar% {
    tmp.fls <- list.files(hdf.path, pattern = i, recursive = TRUE, full.names = TRUE)
    
    tmp.fls.doy <- sapply(tmp.fls, function(j) {
      tmp.info <- GDALinfo(j, returnScaleOffset = FALSE, silent = TRUE)
      tmp.doy <- attr(tmp.info, "mdata")[grep("DAYSOFYEAR", attr(tmp.info, "mdata"))]
      
      return(unlist(strsplit(substr(tmp.doy, 12, nchar(tmp.doy)), ", ")))
    })
    
    return(tmp.fls.doy)
  }
  
  # Available MODIS Terra and Aqua dates
  hdf.doy.terra <- as.Date(do.call("c", hdf.info[[1]]))
  hdf.doy.aqua <- as.Date(do.call("c", hdf.info[[2]]))
  
  # Dates for full time span
  hdf.ts <- seq(from = min(as.Date(do.call("c", hdf.info[[1]]))), to = max(as.Date(do.call("c", hdf.info[[1]]))), by = 1)
  
  # Daily availability of MODIS Terra and Aqua for each time step
  hdf.doy <- data.frame(date = hdf.ts, 
                        terra = hdf.ts %in% hdf.doy.terra, 
                        aqua = hdf.ts %in% hdf.doy.aqua)
  
  # Sum up available daily data of MODIS Terra and Aqua for each time step
  hdf.doy$terra.sum <- sapply(seq(hdf.doy$terra), function(i) {
    sum(hdf.doy$terra[1:i])
  })
  hdf.doy$aqua.sum <- sapply(seq(hdf.doy$aqua), function(i) {
    sum(hdf.doy$aqua[1:i])
  })
  hdf.doy <- hdf.doy[, c(1,2,4,3,5)]
  
  # Optional output storage
  if (hdf.doy.write)
    write.csv(hdf.doy, hdf.doy.path, row.names = FALSE, ...)
  
  # Deregister parallel backend
  stopCluster(clstr)
  
  # Return output data frame
  return(hdf.doy)
  
}

# ### Call
# 
# kifiExtractDoy(hdf.path = "/media/pa_NDown/ki_modis_ndvi/data/MODIS_ARC", 
#                hdf.doy.path = "/media/pa_NDown/ki_modis_ndvi/data/m.d14_doy_availability.csv", 
#                hdf.pattern = c("MOD14A1.*.hdf$", "MYD14A1.*.hdf$"), 
#                n.cores = 4)