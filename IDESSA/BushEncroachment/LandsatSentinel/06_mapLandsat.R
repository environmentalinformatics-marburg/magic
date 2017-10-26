
library(raster)
library(mapview)
library(rgdal)
library(latticeExtra)
library(maps)
library(maptools)
library(rgeos)
library(viridis)
setwd("/home/hanna/Documents/Projects/IDESSA/LandsatTimeSeries/")
gadm <- getData("GADM",country="ZAF",level=2)
pred <- raster("l8pred.tif")
gadm <- spTransform(gadm,crs(pred))
pred <- pred*100
#pred [pred>0.9] <- 0.9

cols <- colorRampPalette(brewer.pal(5,"YlGn"))(500)

png("map.png", width=14,height=10,units="cm",res = 600,type="cairo")
spplot(pred,col.regions=cols,
       colorkey = list(at=seq(0,max(values(pred),na.rm=TRUE),1)),
       maxpixels=500000,scales=list(draw=TRUE),
       sp.layout=list("sp.lines", gadm, col = "black",
                      first=FALSE))
trellis.focus("toplevel",highlight = FALSE)
panel.text(0.823, 0.5, "Woody vegetation in %", 
           cex = 0.8,srt=90)
dev.off()

png("map_de.png", width=14,height=10,units="cm",res = 600,type="cairo")
spplot(pred,col.regions=cols,
       colorkey = list(at=seq(0,max(values(pred),na.rm=TRUE),1)),
       maxpixels=500000,scales=list(draw=TRUE),
       sp.layout=list("sp.lines", gadm, col = "black",
                      first=FALSE))
trellis.focus("toplevel",highlight = FALSE)
panel.text(0.823, 0.5, "holzige Vegetation in %", 
           cex = 0.8,srt=90)
dev.off()
