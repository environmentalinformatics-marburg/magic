### create two table with extracted Data and the corresponding overflight times
rm(list=ls())
library(rgdal)
library(raster)
library(plyr)
origin_of_file <- c(-3282496.232239199, 3333134.0276302756)
years <- c(2013)

mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
Rdatapath <- paste0(datapath,"/RData/")
Shppath <- paste0(datapath,"/ShapeLayers/")
MODISpath <- "/media/hanna/Seagate_0002/Work/LandCare_MB_RSR_terrestrial_data_analysis/RemoteSensing_Analysis/Data/MODIS_LST/"
StationDat <- readOGR(paste0(Shppath,"ClimateStations.shp"),
                      "ClimateStations")
for (year in years){
  aquapath <- paste0(MODISpath,"/aqua/",year,"/mosaics/")
  terrapath <- paste0(MODISpath,"/terra/",year,"/mosaics/")
  dataTable <- list()
  timeTable <- list()
  for (path in c(aquapath,terrapath)){
    if(path==aquapath){
      sensor <- 1
      sensorName <- "Aqua"}
    if(path==terrapath){
      sensor <- 2
      sensorName <- "Terra"
    }
    dataTable[[sensor]] <- list()
    filelist <- list.files(path,full.names = TRUE,pattern=".kea$")
    filelist_time <- filelist[grep("view_time",filelist)]
    filelist_data <- filelist[-grep("view_time",filelist)]
    
    ###check übereinstimmung
    if (any(substr(filelist_data,nchar(filelist_data)-10,nchar(filelist_data))!=
        substr(filelist_time,nchar(filelist_time)-10,nchar(filelist_time)))){
          stop("filelist data does not match filelist time")
        }
    for (i in 1:length(filelist_time)){
      #tryCatch(
        DataLayer <- raster(readGDAL(paste0("HDF5:",filelist_data[i],"://BAND1/DATA")))
      #,error=function(e)e)
     # if(inherits(DataLayer,"error")){next}
      TimeLayer <- raster(readGDAL(paste0("HDF5:",filelist_time[i],"://BAND1/DATA")))
      dat <- stack(DataLayer,TimeLayer)
      names(dat) <- c("LST","Time")
      proj4string(dat)<-CRS("+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs") 
      extent(dat)<-c(origin_of_file[1],origin_of_file[1]+dim(dat)[2]*1000,
                     origin_of_file[2]-dim(dat)[1]*1000,origin_of_file[2])
      
      dataTable[[sensor]][[i]] <- data.frame("Date"=substr(filelist_time[i],nchar(filelist_time[i])-10,nchar(filelist_time[i])-4),
                                             extract(dat,StationDat),
                                             "Station"=StationDat$Name,
                                             "Sensor"= sensorName)
    }
    
    dataTable[[sensor]] <- ldply(dataTable[[sensor]])
  }
  dataTable <- ldply(dataTable)
  save(dataTable,file=paste0(Rdatapath,"extractedData",
                             year,".RData"))
}

####ADD NIGHT/DAY INFO