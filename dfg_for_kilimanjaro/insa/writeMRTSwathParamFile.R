writeMRTSwathParamFile <- function(prmfn = "tmpMRTparams.prm", 
                                   tifsdir, 
                                   modfn, geoloc_fn, 
                                   sds, 
                                   ul_lon, ul_lat, lr_lon, lr_lat) {
  
  # Initialize the list of lines in the parameter file
  prmfile = NULL
  pnum = 0
  prmfile[[(pnum=pnum+1)]] =   " "
  
  # Input files
  prmfile[[(pnum=pnum+1)]] =   paste("INPUT_FILENAME = ", modfn, sep="")
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] = 	paste("GEOLOCATION_FILENAME = ", geoloc_fn, sep="")
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] =   paste("INPUT_SDS_NAME = ", sds, ", 1", sep = "")  
  
  # Subset parameters
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] = 	paste("OUTPUT_SPATIAL_SUBSET_TYPE = LAT_LONG", sep="")
  prmfile[[(pnum=pnum+1)]] = 	paste("OUTPUT_SPACE_UPPER_LEFT_CORNER (LONG LAT) =", ul_lon, ul_lat, sep=" ")
  prmfile[[(pnum=pnum+1)]] = 	paste("OUTPUT_SPACE_LOWER_RIGHT_CORNER (LONG LAT) = ", lr_lon, lr_lat, sep=" ")
  
  # Output filename
  prmfile[[(pnum=pnum+1)]] = 	" "
  
  outfn = gsub(pattern=".hdf", replacement=".tif", modfn)
  outfn = extract_fn_from_path(fn_with_path=outfn)
  outfn = slashslash(paste(tifsdir, outfn, sep="/"))
  
  prmfile[[(pnum=pnum+1)]] = 	paste("OUTPUT_FILENAME = ", outfn, sep="")
  prmfile[[(pnum=pnum+1)]] = 	paste("OUTPUT_FILE_FORMAT = GEOTIFF_FMT", sep="")
  
  # Reprojection information (for Geographic Projection, with nearest-neighbor resampling)
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] = 	"KERNEL_TYPE (CC/BI/NN) = NN"
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] = 	"OUTPUT_PROJECTION_NUMBER = UTM"
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] = 	"OUTPUT_PROJECTION_PARAMETER = 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0"
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] = 	"OUTPUT_PROJECTION_SPHERE = 8"
  prmfile[[(pnum=pnum+1)]] = 	" "
  prmfile[[(pnum=pnum+1)]] =  "OUTPUT_PROJECTION_ZONE = 37"
  prmfile[[(pnum=pnum+1)]] =  " "
  prmfile[[(pnum=pnum+1)]] =  "OUTPUT_PIXEL_SIZE = 1000"
  prmfile[[(pnum=pnum+1)]] = 	" "
  
  # Write the MRTSwath tool parameter file
  write.table(x=prmfile, file=prmfn, append=FALSE, quote=FALSE, sep="\n", row.names=FALSE, col.names=FALSE)
  #moref(prmfn)
  
  return(prmfn)
}
