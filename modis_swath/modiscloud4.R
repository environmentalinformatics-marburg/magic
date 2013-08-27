library(modiscloud)
library(devtools)
library(rstudio)
library(doParallel)

source("writeMRTSwathParamFile.R")
source("runSwath2Grid.R")


# Check your working directory
# setwd("E:/modiscdata/mod/2002_raw")
setwd("/media/IOtte/modiscdata_myd06/data/2012")

#list.files(pattern = "MOD")
list.files(pattern = "MYD")

#######################################################
# Run MRTSwath tool "swath2grid"
#######################################################
check_for_matching_geolocation_files(moddir = getwd(),
                                     modtxt = "MYD06_L2", geoloctxt = "MYD03",
                                     return_geoloc = FALSE, return_product = FALSE)
# Get the matching data/geolocation file pairs
fns_df = check_for_matching_geolocation_files(modtxt = "MYD06_L2",geoloctxt = "MYD03", 
                                              return_geoloc = FALSE, return_product = TRUE)
fns_df

#check_for_matching_geolocation_files(modtxt = "MYD35_L2",geoloctxt = "MYD03", 
#                                     return_geoloc = FALSE, return_product = FALSE)

# Resulting TIF files go in this directory
tifsdir = paste(getwd(), "tifs", sep = "/")
#swath2grid <- get_path()
#mrtpath = ("C:/MRTSwath_Win/bin")
mrtpath = ("/home/ottei/MRTSwath_download_Linux64/bin/swath2grid")

# Box to subset
ul_lat = -2.84
ul_lon = 37
lr_lat = -3.4
lr_lon = 37.7

# Parallelization
registerDoParallel(cl <- makeCluster(4))

for (i in 1:nrow(fns_df)) {
  
  foreach(sds = c("Cloud_Effective_Radius", "Cloud_Optical_Thickness", 
                  "Cloud_Water_Path", 
                  "Cirrus_Reflectance", "Cirrus_Reflectance_Flag"), 
          .packages = "modiscloud") %do% {
            
            prmfn = writeMRTSwathParamFile(prmfn = "tmpMRTparams.prm", 
                                           tifsdir = tifsdir, 
                                           modfn = fns_df$mod35_L2_fns[i], 
                                           geoloc_fn = fns_df$mod03_fns[i], 
                                           sds = sds, 
                                           ul_lon = ul_lon, ul_lat = ul_lat, 
                                           lr_lon = lr_lon, lr_lat = lr_lat)
            
            runSwath2Grid(mrtpath = mrtpath, 
                          prmfn = "tmpMRTparams.prm", 
                          tifsdir = tifsdir, 
                          modfn = fns_df$mod35_L2_fns[i], 
                          geoloc_fn = fns_df$mod03_fns[i], 
                          ul_lon = ul_lon, ul_lat = ul_lat, lr_lon = lr_lon, lr_lat = lr_lat)
          }
}

tiffns = list.files(tifsdir, pattern = ".tif", full.names = TRUE)
tiffns

clusterEvalQ(cl, library(raster))
clusterExport(cl, "tiffns")

tiffrst <- parLapply(cl, tiffns, function(x) { 
  rst <- raster(x)
  
  rst.prj <- projectRaster(rst, crs = "+proj=utm +zone=37 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
  
  if (ifelse(length(grep("Cloud_Effective_Radius", x) == 1) > 0, T, F) |
      ifelse(length(grep("Cloud_Optical_Thickness", x) == 1) > 0, T, F)) {
    scale.factor <- 0.009999999776482582
  } else if (ifelse(length(grep("Cirrus_Reflectance", x) == 1) > 0, T, F)) {
    scale.factor <- 1.9999999494757503e-4
  } else {
    scale.factor <- 1
  }
  
  rst.prj.scl <- rst.prj * scale.factor
  
  writeRaster(rst.prj.scl, paste("tifs/prj_scl", basename(x), sep = "/"), 
              format = "GTiff", overwrite = T)
  
#   rst.prj.scl.fcl <- focal(rst.prj.scl, w = 5, fun = sd, 
#                            filename = paste("tifs/prj_scl_fcl", basename(x), sep = "/"), 
#                            format = "GTiff", overwrite = T)
})

stopCluster(cl)


