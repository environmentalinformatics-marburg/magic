rm(list=ls())
library(viridis)
library(raster)
library(latticeExtra)
library(gridExtra)
library(grid)
library(Rsenal)
setwd("/media/hanna/data/Antarctica/results/predictions/monthlyMeans/")

#mapviewPalette(100)

predictions <- list.files(,pattern=".tif$")
predictions <- predictions[substr(predictions,1,7)=="monthly"]
predictions_stack <- stack(predictions)
names(predictions_stack)<-month.abb[1:12]

png("/media/hanna/data/Antarctica/visualizations/spatialPred_yearlyAgg.png",
    width=17,height=22,units="cm",res = 600)
#pdf(paste0("/media/hanna/data/Antarctica/visualizations/spatialPred.png"))
  spplot(predictions_stack,maxpixels=50000,col.regions=mapviewPalette(500),cuts=80,
 #        colorkey = list(space = "top"),
         ylab.right=expression('T'['air']*'(°C)'),
 par.settings = list(layout.widths = list(axis.key.padding = 0,
                                          ylab.right = 2)))
 
dev.off()

################################################################################
#Plot spatial detail
################################################################################
cropext <- c(320000,510000,-1400000,-1200000)
predictions_stack<- crop(predictions_stack,cropext)


png("/media/hanna/data/Antarctica/visualizations/spatialPred_yearlyAgg_dv.png",
    width=17,height=22,units="cm",res = 600)
#pdf(paste0("/media/hanna/data/Antarctica/visualizations/spatialPred.png"))
spplot(predictions_stack,maxpixels=50000,col.regions=mapviewPalette(500),cuts=80,
       #        colorkey = list(space = "top"),
       ylab.right=expression('T'['air']*'(°C)'),
       par.settings = list(layout.widths = list(axis.key.padding = 0,
                                                ylab.right = 2)))

dev.off()


################################################################################
#Plot spatial detail yearly
################################################################################
lima <- stack("/media/hanna/data/Antarctica/data/Auxiliary/Quantarctica2/Basemap/Imagery/LIMA_Mosaic.tif")

predictions <- raster(list.files(,pattern="yearly"))

#SouthPoleExt <- crop(predictions,c(-500000,500000,-500000,500000))

DryValleyExt <- crop(predictions,extent(cropext))

lima <- crop(lima,extent(cropext))

t <- as(extent(cropext), "SpatialPolygons")





z_range1 <- seq(min(values(predictions),na.rm=T), max(values(predictions),na.rm=T) , 0.1)
p1 <- spplot(predictions,maxpixels=500000,col.regions=mapviewPalette(500),at=z_range1,scales=list(draw=TRUE),
             colorkey=FALSE)+
  as.layer(spplot(t,col="red",col.regions="transparent",lwd=2))+
  layer(panel.text(x=-3e+06,y=3e+06,labels="(a)"))

z_range2 <- seq(min(values(DryValleyExt),na.rm=T), max(values(DryValleyExt),na.rm=T) , 0.1)
p2<-spplot(DryValleyExt,maxpixels=500000,col.regions=mapviewPalette(500),at=z_range2,
           scales=list(draw=TRUE))+
  layer(panel.text(x=330000,y=-1210000,labels="(b)"))
#spplot(DryValleylima,maxpixels=500000,col.regions=mapviewPalette(500),cuts=80)


limalayout <- rgb2spLayout(lima, quantiles = c(0.02, 0.98), alpha = 1)
#plotRGB(lima)
p3 <- spplot(DryValleyExt,maxpixels=500000,col.regions="transparent",cuts=50,
             scales=list(draw=TRUE),colorkey=FALSE,sp.layout =limalayout)+
  layer(panel.text(x=330000,y=-1210000,labels="(c)"))



#pdf("/media/hanna/data/Antarctica/visualizations/spatialPred_yearlyAgg_detail.pdf",width=10,height=6)
png("/media/hanna/data/Antarctica/visualizations/spatialPred_yearlyAgg_detail.png",
    width=22,height=10,units="cm",res = 600)

grid.newpage()
latticeCombineGrid(list(p1,p2,p3),layout=c(3,1))
downViewport(trellis.vpname(name = "figure"))
#grid.rect()
#trellis.focus(name="panel",column = 1,row = 1,highlight = TRUE)
vp1 <- viewport(x = 0.05, y = 1.1, 
                height = 0.1, width = 0.27,
                just = c("left", "bottom"),
                name = "key1.vp")
pushViewport(vp1)
key1 <- draw.colorkey(key = list(col = mapviewPalette(500),
                                 at = z_range1,space="top",
                                 width=1), draw = TRUE)
upViewport(1)
vp2 <- viewport(x = 0.385, y = 1.1, 
                height = 0.1, width = 0.27,
                just = c("left", "bottom"),
                name = "key2.vp")
pushViewport(vp2)
key2 <- draw.colorkey(key = list(col = mapviewPalette(500),
                                 at = z_range2,space="top",
                                 width=1), draw = TRUE)



dev.off()

################################################################################
#GA
################################################################################
predictions <- raster(list.files(,pattern="yearly"))

statloc <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationsFinal.shp",
                   "StationsFinal")
statloc@data$Name <- gsub("([.])", "", statloc@data$Name)
statloc@data$Name <- gsub("([ ])", "", statloc@data$Name)

predictions <- crop(predictions,c(-2810142,2813933,-2348479,2290109))

png("/home/hanna/Documents/tmp/test.png",width = 545, height = 445, units = "px", pointsize = 12,
    type="cairo")

spplot(predictions,maxpixels=50000,col.regions=mapviewPalette(500),cuts=80,
       #        colorkey = list(space = "top"),
       ylab.right=expression('air temperature (°C)'),scales=list(draw=FALSE),
       par.settings = list(axis.line = list(col =  'transparent'),
       layout.widths = list(axis.key.padding = 0,
                                                ylab.right = 2)),
       sp.layout = list("sp.points", statloc, pch = 3, cex = 1.3, col = "black"))
dev.off()

