library(raster)

# Check your working directory
setwd("D:/modiscdata_myd06/data_rst")

# setwd("/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau")
inputpath <- "D:/modiscdata_myd06/data_rst"
ptrn <- "*Cloud_Optical_Thickness.tif"

# List folders in data directory
cld.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn), 
                      recursive = F)

stck <- stack(cld.fls)
fun <- function(x){
  ifelse(x <= 0,0,x)
}
stck.cl <- calc(stck, fun)

writeRaster(stck.cl, paste("kifi", basename(cld.fls), sep = "/"), 
            format = "GTiff", bylayer = TRUE) 

