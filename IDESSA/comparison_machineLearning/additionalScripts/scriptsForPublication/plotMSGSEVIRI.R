###plot an IR image of the example raster used in the publication 


setwd("/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/05/06/09")


usedPackages=c("caret","kernlab","ROCR","raster","latticeExtra","fields","reshape2",
               "grid","maps","mapdata","sp","rgdal","RColorBrewer","lattice","doParallel","hydroGOF","corrplot")

lapply(usedPackages, library, character.only=T)



rasterlist=stack("201005060950_mt09s_ca02p0001_m1hct_1000_rg01de_003000.rst",
                 "201005060950_mt09s_ca02p0002_m1hct_1000_rg01de_003000.rst",
                 "201005060950_mt09s_ca02p0003_m1hct_1000_rg01de_003000.rst",
                 "201005060950_mt09s_ct01dk004_m1hct_1000_rg01de_003000.rst")

rasterlist[rasterlist==-99]=NA

############################################################################

lm <- raster("/media/hanna/ubt_kdata_0005/pub_rapidminer/input//europe_landsea_mask.rst", 
             native = T, crs = "+proj=longlat +datum=WGS84")

ext <- extent(c(4, 17, 47.0, 54.45))
mm <- map('worldHires', plot = F, fill = T, col = "grey50")

lm <- crop(lm, ext)
lmplot <- spplot(lm, mm = mm, maxpixels = 400000, col.regions = "grey30",
                 colorkey = F, panel = function(..., mm) {
                   panel.levelplot(...)
                   panel.polygon(mm$x, mm$y, col = "grey50", border = "yellow", lwd = 0.1)
                 })
yat = seq(40, 70, 2.5)
ylabs = paste(yat, "°N", sep = "")
xat = seq(0, 100, 2.5)
xlabs = ifelse(xat < 0, paste(xat, "°W", sep = ""), 
               ifelse(xat > 0, paste(xat, "°E", sep = ""), 
                      paste(xat, "°", sep = "")))

############################################################################
RasterToPlot=rasterlist[[4]]

y=raster("/media/hanna/ubt_kdata_0005/pub_rapidminer/input/000000000000_00000_ml01danb1_na001_1000_rg01de_003000.rst", 
         native = T, crs = "+proj=longlat +datum=WGS84")
x=raster("/media/hanna/ubt_kdata_0005/pub_rapidminer/input/000000000000_00000_ml02danb1_na001_1000_rg01de_003000.rst",
         native = T, crs = "+proj=longlat +datum=WGS84")

#load rastervorlage von sagaraster
base=raster("/media/hanna/ubt_kdata_0005/pub_rapidminer/input/baseRaster_de.tiff")#load rastervorlage von sagaraster

RasterToPlot=resample(RasterToPlot, x)
tmpRasterToPlot=RasterToPlot
values(tmpRasterToPlot)[!is.na(values(RasterToPlot))]=1
xRaster=tmpRasterToPlot*x
yRaster=tmpRasterToPlot*y

plotraster=rasterize(cbind(values(xRaster),values(yRaster)),base,field=values(RasterToPlot))

###############################################################################

datp <- spplot(plotraster, mm= mm, maxpixels = 400000, colorkey = list(space = "top", width = 0.5,title="test"), main = " ",
                    col.regions =grey(25:max(values(plotraster),na.rm=T)/max(values(plotraster),na.rm=T)), 
                    #col.regions = colorRampPalette(c(brewer.pal(4,"Greys")[1],brewer.pal(4,"Blues")[2],brewer.pal(4,"Blues")[3],brewer.pal(4,"Blues")[4])),
                    at = seq(min(values(plotraster),na.rm=T), max(values(plotraster),na.rm=T), 1),
                    panel = function(...) {
                      panel.abline(h = yat, v = xat,
                                   col = "grey80", lwd = 0.8, lty = 3)
                      panel.levelplot(...)
                      panel.polygon(mm$x, mm$y, border = "black", lwd = 0.9)
                    }, scales = list(x = list(at = xat, labels = xlabs), 
                                     y = list(at = yat, labels = ylabs))
)

png("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/IR201005060950.png",res=300,width=10,height=8,units = "in")
datp
dev.off()
