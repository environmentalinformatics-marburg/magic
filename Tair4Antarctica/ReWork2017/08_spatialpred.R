###08_prediction

#07 run ffs
rm(list=ls())
library(caret)
library(raster)
library(rgdal)
mainpath <- "/mnt/sd19007/users/hmeyer/Antarctica/ReModel2017/"
#mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")
modelpath <- paste0(datapath, "/modeldat/")
predpath <- paste0(datapath, "/predictions/")
MODISpath <- paste0(mainpath,"/MODISLST/")
MODISpath_VIS <- "/mnt/sd19006/data/users/fdetsch/R-Server/data/MODIS_ARC/PROCESSED/mod09ga-antarctica/"
tmppath <- paste0(mainpath,"/tmp/")
model <- get(load(paste0(modelpath,"model_final.RData")))

years <- 2003:2017

for (year in years){
  tmppath <- paste0(tmppath,"/",year)
  dir.create(tmppath)
  rasterOptions(tmpdir = tmppath)
  dir.create(paste0(predpath,"/",year))
  
  MODISdat_terra <- list.files(paste0(MODISpath,"/terra/",year,"/"),
                               recursive = TRUE,pattern=".tif",full.names = TRUE)
  MODISdat_aqua <- list.files(paste0(MODISpath,"/aqua/",year,"/"),
                              recursive = TRUE,pattern=".tif$",full.names = TRUE)
  
  aqua_day <- MODISdat_aqua[grep(pattern="LST_LST_Day",MODISdat_aqua)]
  aqua_night <- MODISdat_aqua[grep(pattern="LST_LST_Night",MODISdat_aqua)]
  terra_day <- MODISdat_terra[grep(pattern="LST_LST_Day",MODISdat_terra)]
  terra_night <- MODISdat_terra[grep(pattern="LST_LST_Night",MODISdat_terra)]
  
  MODIS_VIS <-   list.files(paste0(MODISpath_VIS,"/",year),full.names = TRUE,pattern=".tif$")
  MODIS_VIS <- MODIS_VIS[grepl("sur_refl",MODIS_VIS)]
  VIS_dates <- substr(MODIS_VIS,nchar(MODIS_VIS)-25,nchar(MODIS_VIS)-19)
  
  
  hillshades <- list.files(paste0(rasterdata,"/hillshade/"),pattern=".tif$",full.names = TRUE)
  solarprops <- list.files(paste0(rasterdata,"/solarinfo/"),pattern=".tif$",full.names = TRUE)
  
  for (i in 1:365){
    doy <- sprintf("%03d", i)
    
    
    LST_day <- tryCatch(
     mean(stack(aqua_day[substr(aqua_day,nchar(aqua_day)-6,nchar(aqua_day)-4)==doy],
                            terra_day[substr(terra_day,nchar(terra_day)-6,nchar(terra_day)-4)==doy]),
                      na.rm=T),
      error=function(e)e) 
   
      LST_night <-  tryCatch(mean(stack(aqua_night[substr(aqua_night,nchar(aqua_night)-6,nchar(aqua_night)-4)==doy],
                              terra_night[substr(terra_night,nchar(terra_night)-6,nchar(terra_night)-4)==doy]),
                        na.rm=T),
      error=function(e)e) 
      
      VISdats <- MODIS_VIS[substr(VIS_dates,5,7)==doy]
      VIS <- tryCatch(
        stack(VISdats),error=function(e)e)
    
    if(inherits(LST_night,"error")|inherits(LST_day,"error")|inherits(VIS,"error")){
      next
    }
      
    
    hillshade <- stack( hillshades[grep(pattern=paste0(doy,".tif$"),hillshades)])
    proj4string(hillshade) <- proj4string(LST_night)
    names(hillshade) <- c("min_hillsh","mean_hillsh","max_hillsh")
    solarprop <- stack(solarprops[grep(solarprops,pattern=paste0(doy,".tif$"))])
    proj4string(solarprop) <- proj4string(LST_night)
    names(solarprop) <- c("min_altitude","mean_altitude","max_altitude",
                          "min_azimuth","mean_azimuth","max_azimuth")

    VIS <- resample(VIS,LST_day)
    #LST_day <- crop(LST_day,VIS)
    #LST_night <- crop(LST_night,VIS)
    solarprop <- resample(solarprop,VIS)
    hillshade <- resample(hillshade,VIS)
    names(VIS) <- substr(names(VIS),nchar(names(VIS))-9,nchar(names(VIS))-2)
    preds <- stack(LST_day,LST_night,hillshade,solarprop,VIS)
    names(preds)[1:2] <- c("LST_day","LST_night")
    spatialpred <- predict(preds,model)
    writeRaster(spatialpred,paste0(predpath,"/",year,"/prediction_",year,"_",doy,".tif"),
                overwrite=TRUE)
    print(i)
    file.remove(list.files(tmppath,full.names = TRUE))
  }
}