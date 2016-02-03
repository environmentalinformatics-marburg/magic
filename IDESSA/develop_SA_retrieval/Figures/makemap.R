library(raster)
library(mapview)
library(rgdal)
library(latticeExtra)
setwd("/home/hanna/Documents/Presentations/Paper/Meyer2016_SARetrieval/figureDrafts/")
stations <- readOGR("stations_intersect.shp","stations_intersect")
domain <- readOGR("modelDomain_wgs.shp","modelDomain_wgs")

tmp=as(extent(domain)+3, 'SpatialPolygons')
proj4string(tmp)<-proj4string(domain)
tmp<-SpatialPolygonsDataFrame(tmp,data=data.frame(1))

#mapviewGetOption("basemaps")

map=spplot(mapview(tmp),#map.type=c("osm"),
           col.regions="transparent",colorkey=FALSE,zoom=7)+
  as.layer(spplot(domain,zcol="DN",col.regions="transparent",col="red",lwd=2,colorkey=FALSE)) +
  as.layer(spplot(stations,zcol="type",col.regions=c("blue","darkgreen","red","orange"),pch=16))


map <- update(map,
              par.settings=list(superpose.symbol=list(pch=16,col=c("blue","darkgreen","red","orange"))),
              auto.key = list(text=c("Automatic Rainfall Stations (SAWS)","Automatic Weather Stations (SAWS)",
                                     "Own Climate Stations","SASSCAL Stations"), 
                              points=TRUE,space="bottom",columns=1))

pdf("map.pdf",width=10,height=7)
print(map)
dev.off()

#?openmap ->Namen
################################################################################
################################################################################

library(raster)
library(mapview)
library(rgdal)
library(latticeExtra)
library(maps)
library(maptools)
library(rgeos)
library(devtools)
install_github("environmentalinformatics-marburg/magicVis")

setwd("/home/hanna/Documents/Presentations/Paper/Meyer2016_SARetrieval/figureDrafts/")
stations <- readOGR("stations_intersect.shp","stations_intersect")
domain <- readOGR("modelDomain_wgs.shp","modelDomain_wgs")


gadm <- readOGR("/home/hanna/Documents/Projects/IDESSA/GIS/gadm/gadm_SouthernAfrica.shp","gadm_SouthernAfrica")

#wc <- getData('worldclim', var='prec', res=2.5)
wc <- stack (list.files("wc2-5",pattern=".bil$",full.names = TRUE))
wc <- crop(wc,extent(domain)+4)
wc2<-sum(wc)


mk.colors = colorRampPalette(c("#FC8D59", "#FEE08B","#99D594", "#3288BD"))



map <-   spplot(wc2,col.regions =mk.colors(1000),colorkey=list(space="right"),cuts=c(300),
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
trellis.focus("toplevel")
panel.text(0.88, 0.5, "Average yearly precipitation (mm). Source: WorldClim", 
           cex = 0.8,srt=90)
dev.off()



