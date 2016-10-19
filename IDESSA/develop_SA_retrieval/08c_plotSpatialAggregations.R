##PlotSpatialAggregations
rm(list=ls())
library(raster)
library(viridis)
library(rgdal)
mainpath <- "/media/memory01/data/IDESSA/"
#mainpath <- "/media/hanna/data/CopyFrom181/"
predictionpath_month <- paste0(mainpath,"Results/Predictions/agg_month/")
predictionpath_year <- paste0(mainpath,"Results/Predictions/agg_year/")
figurepath <- paste0(mainpath,"Results/Figures/")
auxdatpath <- paste0(mainpath,"auxiliarydata/")

base <- readOGR(paste0(auxdatpath,"TM_WORLD_BORDERS-0.3.shp"),
                "TM_WORLD_BORDERS-0.3")

################################################################################
#Rainy Days
################################################################################
yearly <- raster(paste0(predictionpath_year,"2013_rainydays.tif"))
yearly <- projectRaster(yearly, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
base <- crop(base,yearly)

monthly <- stack(list.files(predictionpath_month,pattern="rainydays.tif$",full.names = TRUE))
monthly <- projectRaster(monthly, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
names(monthly)<- month.abb[as.numeric(substr(names(monthly),6,7))]

yearly <- mask(yearly,base)
monthly <- mask(monthly,base)

png(paste0(figurepath,"rainydays_year.png"),
        width=14,height=11,units="cm",res = 600,type="cairo")
spplot(yearly,col.regions = rev(viridis(max(values(yearly),na.rm=TRUE))),scales=list(draw=TRUE),
       xlim=c(11.4,36.07),ylim=c(-35.4,-17.1),
       maxpixels=ncell(yearly),colorkey = list(at=seq(0,max(values(yearly),na.rm=TRUE))),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE))
dev.off()

png(paste0(figurepath,"rainydays_months.png"),
    width=15,height=15,units="cm",res = 600,type="cairo")
spplot(monthly,col.regions = rev(viridis(max(values(monthly),na.rm=TRUE))),
       scales=list(draw=FALSE,x=list(rot=90)),#x=list(rot=90)
       xlim=c(11.4,36.2),ylim=c(-35.4,-17),
       maxpixels=ncell(monthly)*0.6,colorkey = list(at=seq(0,max(values(monthly),na.rm=TRUE))),
       par.settings = list(strip.background=list(col="lightgrey")),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE))
dev.off()

################################################################################
#Precipitation sums
################################################################################
yearly <- raster(paste0(predictionpath_year,"2013_rainsum.tif"))
yearly <- projectRaster(yearly, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

monthly <- stack(list.files(predictionpath_month,pattern="rainsum.tif$",full.names = TRUE))
monthly <- projectRaster(monthly, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
names(monthly)<- month.abb[as.numeric(substr(names(monthly),6,7))]

yearly <- mask(yearly,base)
monthly <- mask(monthly,base)

png(paste0(figurepath,"rainsums_year.png"),
    width=14,height=11,units="cm",res = 600,type="cairo")
spplot(yearly,col.regions = rev(viridis(max(values(yearly),na.rm=TRUE))),scales=list(draw=TRUE),
       xlim=c(11.4,36.2),ylim=c(-35.4,-17),
       maxpixels=ncell(yearly),colorkey = list(at=seq(0,max(values(yearly),na.rm=TRUE))),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE))
dev.off()

png(paste0(figurepath,"rainsums_months.png"),
    width=15,height=15,units="cm",res = 600,type="cairo")
spplot(monthly,col.regions = rev(viridis(max(values(monthly),na.rm=TRUE))),
       scales=list(draw=FALSE,x=list(rot=90)),#x=list(rot=90)
       xlim=c(11.4,36.2),ylim=c(-35.4,-17),
       maxpixels=ncell(monthly)*0.6,colorkey = list(at=seq(0,max(values(monthly),na.rm=TRUE))),
       par.settings = list(strip.background=list(col="lightgrey")),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE))
dev.off()

