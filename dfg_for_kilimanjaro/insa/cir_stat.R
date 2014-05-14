library(raster)
library(rgdal)
library(RColorBrewer)
library(gridExtra)

# Check your working directory
setwd("D:/modiscdata_mod/data_rst/cir")

### Input preparation 
inputpath <- "D:/modiscdata_mod/data_rst/cir"
ptrn <- "*Cirrus_Reflectance_Flag.tif"

### list files in direcotry 
fnames.cir <- list.files(inputpath, 
                         pattern = glob2rx(ptrn), 
                         recursive = F)

### Build raster stack and crop add NAs
cir.stck <- stack(fnames.cir)
cir.shp <- rasterToPolygons(cir.stck)
cir.stck.nw <- crop(cir.stck, extent(cir.shp))

### getValues of raster stack to calc row/col sums
cir.vl <- values(cir.stck.nw)

cir.cs <- colSums(cir.vl, na.rm = TRUE)
cir.cs.rs <- sum(cir.cs)
pxl.all <- 6336*3377
pc <- cir.cs.rs/pxl.all
# Aqua 31% aller Pixel mit Cirren bedeckt


### plot overlay of all raster, cirrus per pixel in %
ol <- overlay(cir.stck.nw, fun = sum)
ol.diff <- ol/nlayers(cir.stck.nw)
ol.rev <- 1 - ol.diff

RColorBrewer::display.brewer.all()
clrs <- colorRampPalette(brewer.pal(11, "BrBG"))

spplot(ol.rev, scales = list(x = list (draw = T), y = list (draw = T)), 
       col.regions = clrs) #, aspect = mapasp(ol.rev, xlim, ylim))

dem <- raster("kili_dem_utm.tif")

png("C:/Users/iotte/Desktop/poster_graph/tr_cir_cov_percentage_02_12.png",
    units = "mm", width = 300, res = 300, pointsize = 20)
spplot(ol.rev, scales = list(draw = T),  
       col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
       sp.layout = list("sp.lines", rasterToContour(dem)), 
       par.settings = list(fontsize = list(text = 15)))
dev.off()



