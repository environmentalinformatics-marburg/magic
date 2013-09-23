kifiModisDownload <- function(modis.products, 
                              modis.download.only = T,
                              modis.outproj = "asIn",
                              ...) {

  #########################################################################################
  # Parameters are as follows:
  #
  # modis.products (character):     Names of the desired MODIS products. See
  #                                 ?getProduct for detailed information.
  # modis.download.only (logical):  Download only (default) or download and
  #                                 reproject the specified products.
  # modis.outproj (character):      Desired output CRS. Default is "asIn"
  #                                 (i.e. MODIS Sinusoidal).
  # ...:                            Further arguments passed on to getHdf and, 
  #                                 runGdal, respectively.
  #
  #########################################################################################
  
  # Required libraries
  stopifnot(require(MODIS))
  
  # Download MODIS data with given extent
  if (modis.download.only) {
    lapply(modis.products, function(i) {
      getHdf(i, ...)
    })
    
  # Download and extract MODIS data with given extent
  } else {
    # Extract specified SDS from .hdf files
    lapply(modis.products, function(i) {
      runGdal(i, outProj = modis.outproj, ...)
    })
  }
  
  # Return message when download is finished
  return("Processing MODIS data finished!")
}

# ### Call
# 
# MODISoptions(localArcPath = "G:/ki_modis_ndvi/data/MODIS_ARC", 
#              outDirPath = "G:/ki_modis_ndvi/data/MODIS_ARC/PROCESSED")
# kifiModisDownload(modis.products = c("MOD13Q1", "MYD13Q1"), 
#                   modis.download.only = F, 
#                   begin = "2013-06-03",
#                   extent = extent(37, 37.72, -3.4, -2.84),
#                   SDSstring = "100000000001",
#                   modis.outproj = "4326", 
#                   job = "md13_tmp"
#                   )
