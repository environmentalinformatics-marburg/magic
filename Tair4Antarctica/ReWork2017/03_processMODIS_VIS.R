#03_processMODIS_VIS

rm(list=ls())
library(rgdal)
library(raster)
library(plyr)
years <- c(2002:2017)

mainpath <- "/mnt/sd19007/users/hmeyer/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
Rdatapath <- paste0(datapath,"/RData/")
Shppath <- paste0(datapath,"/ShapeLayers/")
tmppath <- paste0(mainpath,"/tmp/")
rasterOptions(tmpdir = tmppath)

MODISpath <- "/mnt/sd19006/data/users/fdetsch/R-Server/data/MODIS_ARC/PROCESSED/mod09ga-antarctica/"
StationDat <- readOGR(paste0(Shppath,"ClimateStations.shp"))
for (year in years){
  MODISpath_year <- paste0(MODISpath,"/",year)
  filelist <- list.files(MODISpath_year,full.names = TRUE,pattern=".tif$")
  filelist <- filelist[grepl("sur_refl",filelist)]
  filelist_dates <- substr(filelist,nchar(filelist)-25,nchar(filelist)-19)
  dataTable <- list()
  for (i in 1:length(unique(filelist_dates))){
    dat <- stack(filelist[filelist_dates==unique(filelist_dates)[i]])
    names(dat) <- substr(names(dat),nchar(names(dat))-9,nchar(names(dat))-2)
    dataTable[[i]] <- data.frame("Date"=unique(filelist_dates)[i],
                                 extract(dat,StationDat),
                                 "Station"=StationDat$Name)
  }
  dataTable <- ldply(dataTable)
  save(dataTable,file=paste0(Rdatapath,"extractedData_VIS_",
                             year,".RData"))
}
