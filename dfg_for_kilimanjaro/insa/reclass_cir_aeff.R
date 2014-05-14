library(raster)
library(Kendall)

# Check your working directory
setwd("D:/modiscdata_mod/data_rst/cir_tau/tau_cir")

# setwd("/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau")
inputpath <- "D:/modiscdata_mod/data_rst/cir_tau/tau_cir"
ptrn <- "*Cloud_Optical_Thickness.tif"

# List folders in data directory
tau.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn), 
                      recursive = T)

tau.stck <- stack(tau.fls)

# reclassify cir_aeff_product
fun <- function(x){
  ifelse(x == 0, NA, ifelse(x == -99.99, 0, ifelse(x < 1, 0, x)))
}

tau.stck <- calc(tau.stck, fun)

# spplot(aeff.stck[[2]])

writeRaster(tau.stck, paste("tau_cir_rc", basename(tau.fls), sep = "/"), 
            format = "GTiff", bylayer = TRUE, overwrite = TRUE) 
