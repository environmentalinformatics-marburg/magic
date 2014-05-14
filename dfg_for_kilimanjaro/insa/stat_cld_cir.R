library(raster)

# Check your working directory
setwd("D:/modiscdata_mod/data_rst/cir_aeff")

# setwd("/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau")
inputpath <- "D:/modiscdata_mod/data_rst/cir_aeff"
ptrn_cir <- "*Cirrus_Reflectance_Flag.tif"
ptrn_tau <- "*Cloud_Effective_Radius.tif"

# List folders in data directory
cir.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn_cir), 
                      recursive = T)

stck_cir <- stack(cir.fls)


tau.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn_tau), 
                      recursive = T)

stck_tau <- stack(tau.fls)

fun.1 = function(x, y) {
  (x*y)}

stck.bth <- overlay(stck_cir, stck_tau, fun = fun.1, unstack = TRUE)
#stck.bth.stck <- stack(stck.bth)

writeRaster(stck.bth, paste("aeff_cir", basename(tau.fls), sep = "/"), 
            format = "GTiff", bylayer = TRUE, overwrite = TRUE) 

# reclassify cir_aeff_product
fun.2 <- function(x){
  ifelse(x == 0, NA, ifelse(x == -99.99, 0, ifelse(x < 1, 0, x)))
}

tau.stck <- calc(stck.bth, fun.2)

# spplot(aeff.stck[[2]])

writeRaster(tau.stck, paste("aeff_cir/aeff_cir_rc", basename(tau.fls), sep = "/"), 
            format = "GTiff", bylayer = TRUE, overwrite = TRUE) 
