library(raster)
library(Kendall)
library(RColorBrewer)

# Check your working directory
setwd("D:/modiscdata_mod/data_rst/cir_aeff/aeff_cir/aeff_cir_rc/aeff_mnth")

# setwd("/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau")
inputpath <- "D:/modiscdata_mod/data_rst/cir_aeff/aeff_cir/aeff_cir_rc/aeff_mnth"
ptrn <- "*aeff_mnth_mean*.tif"

# List folders in data directory
# tau.drs <- dir("data", full.names = T)
aeff_cir.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn), 
                      recursive = T)

# build and crop stack
cld.stck <- stack(aeff_cir.fls)
spplot(cld.stck)
cld.shp <- rasterToPolygons(cld.stck)
cld.stck.crp <- crop(cld.stck, extent(cld.shp))

# calculate Mann Kendall Trend for raster stack
fun <- function(x) {MannKendall(x)$tau}
MK_mnth_mean_tau <- calc(cld.stck, fun)

# plot Mk trend raster
RColorBrewer::display.brewer.all()
clrs <- colorRampPalette(brewer.pal(11, "Spectral"))

spplot(MK_mnth_mean_tau, main = "Terra: MK cloud effective radius (monthly mean), 2002 - 2013", col.regions = clrs)

# write raster file  
writeRaster(MK_mnth_mean_tau, filename = "MK_mnth_mean_aeff",
format = "GTiff", overwrite = TRUE) 

MK_mnth_mean_tau.fcl <- focal(MK_mnth_mean_tau, w = 3, fun = sd, 
                              filename = "MK_mnth_mean_aeff_fcl", 
                              format = "GTiff", overwrite = T)
clrs.fcl <- colorRampPalette(rev(brewer.pal(9, "Greys")))
spplot(MK_mnth_mean_tau.fcl, main = "Terra:", col.regions = clrs.fcl)



plot(MK_mnth_mean_tau, main = "Aqua: MK cloud effective radius (monthly mean), 2002 - 2013", col = 'blue')
cols <- rev(terrain.colors)
