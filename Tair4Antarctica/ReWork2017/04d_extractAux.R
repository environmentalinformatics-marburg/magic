#04d_extractAux
rm(list=ls())
library(rgdal)
library(raster)
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")

StationDat <- readOGR(paste0(Shppath,"ClimateStations.shp"))



hillshades <- list.files(paste0(rasterdata,"hillshade"),full.names = TRUE)
solarinfos <- list.files(paste0(rasterdata,"solarinfo"),full.names = TRUE)

aux_extr <- list()
for (i in 1:365){
  hillsh <- stack(hillshades[as.numeric(substr(hillshades,nchar(hillshades)-6,
                                               nchar(hillshades)-4))==i])
  solarinf <- stack(solarinfos[as.numeric(substr(solarinfos,nchar(solarinfos)-6,
                                                 nchar(solarinfos)-4))==i])
  projection(hillsh) <- projection(StationDat)
  projection(solarinf) <- projection(StationDat)
  aux_extr[[i]] <- data.frame("doy"=i,StationDat$Name,extract(hillsh,StationDat),
                              extract(solarinf,StationDat))
  names(aux_extr[[i]]) <- c("Doy","Station","min_hillsh","mean_hillsh","max_hillsh",
                            "min_altitude","mean_altitude","max_altitude",
                            "min_azimuth","mean_azimuth","max_azimuth")
  print(i)
}
aux_extr<- do.call("rbind",aux_extr)

alt <-raster(paste0(rasterdata,"dem_recl.tif"))
projection(alt)<-projection(StationDat)
alt_extr <- data.frame("Name"=StationDat$Name, "DEM"=extract(alt,StationDat))
aux_extr <- merge(aux_extr,alt_extr,by.x="Station",by.y="Name")

save(aux_extr,file=paste0(rdatapath,"aux_extr.RData"))
