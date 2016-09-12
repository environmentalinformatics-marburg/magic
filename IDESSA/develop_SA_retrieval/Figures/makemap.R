
library(raster)
library(mapview)
library(rgdal)
library(latticeExtra)
library(maps)
library(maptools)
library(rgeos)
setwd("/home/hanna/Documents/Presentations/Paper/Meyer2016_SARetrieval/figureDrafts/")
stations <- readOGR("stations_intersect.shp","stations_intersect")
domain <- readOGR("modelDomain_wgs.shp","modelDomain_wgs")
gadm <- readOGR("/home/hanna/Documents/Projects/IDESSA/GIS/gadm/gadm_SouthernAfrica.shp",
                "gadm_SouthernAfrica")

#wc <- getData('worldclim', var='prec', res=2.5)
wc <- stack (paste0("/home/hanna/Documents/Projects/IDESSA/Precipitation/worldclim/",
                    paste0("wc",1:12,".tif")))
wc <- crop(wc,extent(domain)+4)
wc2<-sum(wc)

map.colors = colorRampPalette(c("#FC8D59", "#FEE08B","#99D594", "#3288BD"))

map <-   spplot(wc2,col.regions =map.colors(1000),colorkey=list(space="right"),cuts=c(300),
         at = seq(8, 1700, by = 10),scales = list(draw = TRUE),
         key=list(corner=c(0,0.02),cex=0.9,#space = 'bottom', 
                  points = list(pch = 1, cex = 1, col = c("blue","darkblue","red","darkgreen")),
                  text = list(c("Automatic Rainfall Stations (SAWS)",
                                                  "Automatic Weather Stations (SAWS)",
                                                  "Own Climate Stations",
                                                  "SASSCAL Stations"))))+
  as.layer(spplot(gadm,col.regions="transparent",colorkey=FALSE,lwd=2,col="grey40"))+
  as.layer(spplot(domain,zcol="DN",col.regions="transparent",col="red",lwd=2,colorkey=FALSE))+
  as.layer(spplot(stations,zcol="type",col.regions=c("blue","darkblue","red","darkgreen"),
                  pch=1,cex=0.7
                  ))

pdf("map.pdf",width=8,height=6)
print(map)
trellis.focus("toplevel",highlight = FALSE)
panel.text(0.889, 0.5, "Average Yearly Precipitation (mm). Source: WorldClim", 
           cex = 0.8,srt=90)
panel.text(0.50, 0.14, "____",col="red")
panel.text(0.60, 0.13, "Model Domain",cex=0.9)
trellis.unfocus()
dev.off()

################################################################################
#V2
################################################################################
library(raster)
library(viridis)
library(rgdal)

setwd("/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/")
#figurepath <- "/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/"

base <- readOGR("/home/hanna/Documents/Projects/IDESSA/GIS/TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp",
                "TM_WORLD_BORDERS-0.3")
template <- raster("/media/hanna/data/Rainfall4SA/Results/Predictions/agg_year/2013_rainydays.tif")
wc <- stack (paste0("/home/hanna/Documents/Projects/IDESSA/Precipitation/worldclim/",
                    paste0("wc",1:12,".tif")))

stations <- readOGR("allStations.shp",
                    "allStations")

template <- projectRaster(template, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
base <- crop(base,template)
wc <- crop(wc,template)
wcsum <- calc(wc,sum)


pdf("map.pdf",width=9.5,height=7.5)
spplot(wcsum,col.regions = rev(viridis(max(values(wcsum),na.rm=TRUE))),scales=list(draw=TRUE),
       xlim=c(11.4,36.3),ylim=c(-35.4,-17.1),
       maxpixels=ncell(wcsum)*0.02,colorkey = list(at=seq(0,max(values(wcsum),na.rm=TRUE))),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE),
  key=list(corner=c(1,0.02),cex=0.8,#space = 'bottom', 
           points = list(pch = 3, cex = 0.7, col = c("blue","darkblue","red","darkred")),
           text = list(c("Automatic Rainfall Stations (SAWS)",
                         "Automatic Weather Stations (SAWS)",
                         "IDESSA Stations",
                         "SASSCAL Stations"))))+
  as.layer(spplot(stations,zcol="type",col.regions=c("blue","darkblue","red","darkred"),
                  pch=3,cex=0.7
  ))
trellis.focus("toplevel",highlight = FALSE)
panel.text(0.91, 0.5, "Average yearly precipitation (mm). Source: WorldClim", 
           cex = 0.8,srt=90)
dev.off()