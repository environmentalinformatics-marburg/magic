library(raster)

# Check your working directory
setwd("D:/modiscdata_mod/data_rst")

# setwd("/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau")
inputpath <- "D:/modiscdata_mod/data_rst"
ptrn <- "*Cirrus_Reflectance_Flag.tif"

# List folders in data directory
cir.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn), 
                      recursive = F)

stck <- stack(cir.fls)
# rst.tmp <- stck[[2]]
# rst.tmp@data@values
# unique(values(rst.tmp))
# tst<- c(4e-04, 4e-04, 4e-04, 4e-04, 4e-04, 4e-04, 4e-04, NA, 2e-04)
# ifelse(tst == 0.0004, 0, 1)

# ifelse(values(rst.tmp) >= 0.00039 &
#         values(rst.tmp) <= 0.0004, 0, 1)

# options(digits = 10)

fun <- function(x){
  ifelse(x >= 0.00039 &
           x <= 0.0004, 1, 0)
}

stck.cir <- calc(stck, fun)
cir.shp <- rasterToPolygons(stck.cir)
cir.stck <- crop(stck.cir, extent(cir.shp))

spplot(stck.cir[[2]])

writeRaster(stck.cir, paste("cir_stat", basename(cir.fls), sep = "/"), 
            format = "GTiff", bylayer = TRUE, overwrite = TRUE) 
