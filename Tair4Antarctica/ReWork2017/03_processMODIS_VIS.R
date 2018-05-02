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
tmppath <- paste0(mainpath,"/tmp2/")

MODISpath <- "/mnt/sd19006/data/users/fdetsch/R-Server/data/MODIS_ARC/PROCESSED/mod09ga-antarctica/"
StationDat <- readOGR(paste0(Shppath,"ClimateStations.shp"))
for (year in years){
  tmp2 <- paste0(tmppath,"/",year,"/")
  dir.create(tmp2)
  MODISpath_year <- paste0(MODISpath,"/",year)
  filelist <- list.files(MODISpath_year,full.names = TRUE,pattern=".tif$")
  filelist <- filelist[grepl("sur_refl",filelist)]
  filelist_dates <- substr(filelist,nchar(filelist)-25,nchar(filelist)-19)
  dataTable <- list()
  for (i in 1:length(unique(filelist_dates))){
    tmp3 <- paste0(tmp2,"/",i,"/")
    rasterOptions(tmpdir = tmp3)
    dat <- tryCatch(stack(filelist[filelist_dates==unique(filelist_dates)[i]]), error = function(e)e)
    #dat[is.na(dat)]<- 0
    #dat[dat<0] <- 0

    if(inherits(dat, "error")){next}
    names(dat) <- substr(names(dat),nchar(names(dat))-9,nchar(names(dat))-2)
    extr <- tryCatch(extract(dat,StationDat), error = function(e)e)
    if(inherits(extr, "error")){next}
    extr[is.na(extr)] <- 0
    extr[extr<0] <- 0
    dataTable[[i]] <- data.frame("Date"=unique(filelist_dates)[i],
                                extr,
                                 "Station"=StationDat$Name)
    print(i)
    file.remove(list.files(tmp3,full.names = TRUE))
  }
  file.remove(list.files(tmp2,full.names = TRUE))
  dataTable <- ldply(dataTable)
  save(dataTable,file=paste0(Rdatapath,"extracted_VIS/extractedData_VIS_",
                             year,".RData"))
}
