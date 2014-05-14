library(raster)
library(Kendall)
library(RColorBrewer)

# Check your working directory
setwd("D:/modiscdata_mod/data_rst/cld/cld_mnth")

# setwd("/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau")
inputpath <- "D:/modiscdata_mod/data_rst/cld/cld_mnth"
ptrn <- "*cld_mnth_mean*.tif"

# List folders in data directory
# tau.drs <- dir("data", full.names = T)
cld.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn), 
                      recursive = T)

cld.stck <- stack(cld.fls)

cld.stck.mean <- calc(cld.stck, mean)

cld.stck.fcl <- focal(cld.stck.mean, w = 3, fun = sd, 
                      filename = "cld.stck.fcl", 
                      format = "GTiff", overwrite = T)

RColorBrewer::display.brewer.all()
clrs.fcl <- colorRampPalette(rev(brewer.pal(9, "Spectral")))
spplot(cld.stck.fcl, main = "Terra:", col.regions = clrs.fcl)
