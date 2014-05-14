runSwath2Grid <- function(mrtpath = "swath2grid", 
                          prmfn = "tmpMRTparams.prm", 
                          tifsdir = ".", 
                          modfn, 
                          geoloc_fn, 
                          ul_lon, ul_lat, lr_lon, lr_lat) {
  
  which_result = system(paste("which ", mrtpath, sep = ""), 
                        intern = TRUE)
  if (length(which_result) == 0) {
    return(paste("Error: mrtpath (", mrtpath, ") does not correspond to a file. Having swath2grid from MRTswatch is required for this function.", 
                 sep = ""))
  }
  
#   prmfn = write_MRTSwath_param_file(prmfn = prmfn, tifsdir = tifsdir, 
#                                     modfn = modfn, geoloc_fn = geoloc_fn, ul_lon = ul_lon, 
#                                     ul_lat = ul_lat, lr_lon = lr_lon, lr_lat = lr_lat)
  cmdstr = paste(mrtpath, " -pf=", prmfn, sep = "")
  system(cmdstr)
  
  return(cmdstr)
}
