library(raster)
library(Kendall)
library(RColorBrewer)
library(latticeExtra)
library(sp)

# Check your working directory
setwd("E:/out")

inputpath <- "E:/out"

RColorBrewer::display.brewer.all()

dem <- raster("kili_dem_utm.tif")
rst.mk.sg001 <- raster("mk_sg001_pos_myd06_jan03_dec13.tif")
rst.mk.sg005 <- raster("mk_sg005_pos_myd06_jan03_dec13.tif")


mk.sg001 <- spplot(rst.mk.sg001, scales = list(draw = TRUE), xlab = "x", ylab = "y", 
            col.regions = colorRampPalette(brewer.pal(9, "Blues")), 
            sp.layout = list("sp.lines", rasterToContour(dem)), 
            par.settings = list(fontsize = list(text = 15)), 
            at = seq(0, .21, .01))

mk.sg005 <- spplot(rst.mk.sg005, scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                   col.regions = colorRampPalette(brewer.pal(9, "YlGn")), 
                   par.settings = list(fontsize = list(text = 15)), 
                   at = seq(0, .21, .01))

png("mk_005_001_mod06_jan03_dec13.png", units = "mm", width = 300, 
    res = 300, pointsize = 20)

doubleYScale(mk.sg005, mk.sg001)
dev.off()
