kifiModisDownload <- function(modis.products, 
                              modis.download.only = T,
                              modis.extent, 
                              modis.begin = NULL, 
                              modis.end = NULL, 
                              modis.outproj = "4326") {

  #########################################################################################
  # Parameters are as follows:
  #
  # modis.products (character):       Names of the desired MODIS products. See
  #                                   ?getProduct for detailed information.
  # modis.download.only (logical):    Perform download only (default, see ?getHdf) or download
  #                                   and reproject the specified products (see ?runGdal).
  # modis.extent (extent | numeric):  Desired geographic extent of the product.
  # modis.begin (character):          Begin date of MODIS time series.
  # modis.end (character):            End date of MODIS time series.
  # modis.outproj (character):        Desired CRS of the projected MODIS data. Default is
  #                                   EPSG 4326. Defauts to NULL if modis.download.only = T.
  # ...:                              Further arguments passed on to getHdf and runGdal, 
  #                                   respectively.
  #
  #########################################################################################
  
  # Required libraries
  stopifnot(require(MODIS))
  
  # Set output CRS (if required)
  if (modis.download.only) {
    modis.outproj <- NULL
  } else {
    MODISoptions(outProj = modis.outproj)
  }
  
  # Required extent
  if (is.numeric(modis.extent)) {
    modis.extent <- extent(modis.extent)
  } else if (!is.numeric(modis.extent) & class(modis.extent) != "extent") {
    stop("Argument 'modis.extent' must be either of class 'extent' or 'numeric'")
  }
  
  # Download MODIS data with given extent
  if (modis.download.only) {
    lapply(modis.products, function(i) {
      getHdf(i, extent = modis.extent, 
             begin = modis.begin, end = modis.end)
    })
    # Download and extract MODIS data with given extent
  } else {
    # Extract specified SDS from .hdf files
    lapply(modis.products, function(i) {
      runGdal(i, extent = modis.extent, SDSstring = "1100", 
              begin = modis.begin, end = modis.end, outproj = modis.outproj)
    })
  }
  
  # Return message when download is finished
  return("MODIS data download finished!")
  
}

# ### Call
# 
# kifiModisDownload(modis.products = c("MOD13Q1", "MYD13Q1"), 
#                   modis.download.only = F, 
#                   modis.extent = c(37, 37.72, -3.4, -2.84),
#                   modis.begin = "2013152", 
#                   modis.outproj = "+proj=utm +zone=37 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs")