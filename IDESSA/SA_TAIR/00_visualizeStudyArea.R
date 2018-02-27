rm(list=ls())
#library(maps)
library(raster)
library(viridis)
library(latticeExtra)
library(rgdal)
mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/forPaper/"
vispath<- paste0(mainpath,"/visualizations")
load(paste0(mainpath,"/modeldat/modeldata.RData"))
load(paste0(mainpath,"/modeldat/traindata.RData"))
datsp <- readOGR(paste0(mainpath,"/shp/WeatherStations.shp"))
base <- readOGR("/home/hanna/Documents/Projects/IDESSA/GIS/TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp",
                "TM_WORLD_BORDERS-0.3")

dataset <- dataset[complete.cases(dataset[,3:17]),]
datsp_subs <- datsp[datsp$plot%in%unique(dataset$Station),]
#datsp_test <- datsp_subs[datsp_subs$plot%in%unique(testdat$Station),]
#datsp_train <- datsp_subs[!datsp_subs$plot%in%unique(testdat$Station),]

datsp_subs$usage <- "training"
datsp_subs$usage[!datsp_subs$plot%in%unique(traindat$Station)] <- "validation"
datsp_subs$usage <- factor(datsp_subs$usage)

wc <- getData('worldclim', var='tmean', res=5)
border <- getData('GADM', country='South Africa', level=0)
wc <- crop(wc,c(12,35,-35.6,-20))
wc_mean <- mean(wc)/10
wc_mean <- mask(wc_mean,base)

wc_mean[wc_mean<10] <- 10


png(paste0(vispath,"/map.png"), width=13,height=10,units="cm",res = 600,type="cairo")
spplot(wc_mean,col.regions = viridis(100),
       scales=list(draw=TRUE),
       xlim=c(12,35),ylim=c(-35.6,-20),
       maxpixels=ncell(wc_mean),
       colorkey = list(at=seq(min(values(wc_mean),na.rm=TRUE),
                              max(values(wc_mean),na.rm=TRUE),by=0.2)),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE),
       key=list(corner=c(1,0.02),cex=0.8,#space = 'bottom', 
                points = list(pch = 3, cex = 0.7, col = c("darkred","black")),
                text = list(c("training",
                              "validation"))))+
  as.layer(spplot(datsp_subs,zcol="usage",col.regions=c("darkred","black"),
                  pch=3,cex=0.7
  ))
trellis.focus("toplevel",highlight = FALSE)
panel.text(0.865, 0.5, "Average yearly air temperature (°C). Source: WorldClim", 
           cex = 0.6,srt=90)
dev.off()

