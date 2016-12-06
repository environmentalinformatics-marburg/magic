library(rgdal)
library(raster)
library(viridis) #nicht daily sondern stündlich!!
MSGpredpath <- paste0("/media/memory01/data/IDESSA/Results/Predictions/")

outpath <- "/media/memory01/data/IDESSA/Results/Figures/timeseries/"
dir.create(outpath)

saturationpoint <- 10
base <- readOGR("/media/memory01/data/IDESSA/auxiliarydata/TM_WORLD_BORDERS-0.3.shp",
                "TM_WORLD_BORDERS-0.3")
filelist_rate <- list.files(paste0(MSGpredpath,"Rate/"), pattern=".tif$",full.names = TRUE)


for (i in 1:length(filelist_rate)){
date <- substr(filelist_rate[i],nchar(filelist_rate[i])-13,nchar(filelist_rate[i])-4)
ri <- raster(filelist_rate[i])
#ra <- raster(list.files(paste0(MSGpredpath,"Area/"), pattern=paste0(date,".tif$"),full.names = TRUE))
ri <- projectRaster(ri, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
ri <- mask(ri,base)
ri <- crop(ri, c(11.4,36.2,-35.4,-17))

ri[ri>saturationpoint] <- saturationpoint

spp <- spplot(ri,col.regions = rev(viridis(100)),
              at=seq(0.0,saturationpoint,by=0.2),
              scales=list(draw=TRUE),
              xlim=c(11.4,36.07),ylim=c(-35.4,-17.1),
              maxpixels=ncell(ri),colorkey = TRUE,
              main=paste0(substr(date,1,4),"-",substr(date,5,6),"-",
                          substr(date,7,8)," ",substr(date,9,10),":00"),
              sp.layout=list("sp.polygons", base, col = "black", first = FALSE))

png(paste0(outpath,"rainsum_",date,".png"),
    width=15,height=15,units="cm",res = 600,type="cairo")
print(spp)
dev.off()
}

#rename files then
#avconv -framerate 3 -i %02d.png video.webm

