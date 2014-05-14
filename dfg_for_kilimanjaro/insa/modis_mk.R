library(raster)
library(Kendall)
library(RColorBrewer)
library(latticeExtra)

# Check your working directory
setwd("E:/modiscdata_mod/data_rst/cld/mod06_agg")

inputpath <- "E:/modiscdata_mod/data_rst/cld/mod06_agg"
ptrn <- "mod06_agg*.tif"

# List folders in data directory
# tau.drs <- dir("data", full.names = T)
cld.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn), 
                      recursive = F)

cld.stck <- stack(cld.fls)

cld.shp <- rasterToPolygons(cld.stck)
cld.crp.stck <- crop(cld.stck, extent(cld.shp))

fun <- function(x) { 
  MannKendall(x)$tau 
}

fun.005 = function(x) {
  mk <- MannKendall(x)
  if (mk$sl >= .05) return(NA) else return(mk$tau)
}

cld.stck.mk <- calc(cld.crp.stck, fun.005)

RColorBrewer::display.brewer.all()
clrs.cld <- colorRampPalette(brewer.pal(11, "BrBG"))

dem <- raster("kili_dem_utm.tif")

png("mk_mod06_jan03_dec13.png", units = "mm", width = 300, 
    res = 300, pointsize = 20)

spplot(cld.stck.mk, scales = list(draw = TRUE), xlab = "x", ylab = "y", 
       col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
       sp.layout = list("sp.lines", rasterToContour(dem)), 
       par.settings = list(fontsize = list(text = 15)), 
       at = seq(-.1, .1, .01))

dev.off()



           
