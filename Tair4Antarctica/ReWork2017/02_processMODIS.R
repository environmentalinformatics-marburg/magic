### create two table with extracted Data and the corresponding overflight times
rm(list=ls())
library(rgdal)
library(raster)
library(plyr)
#origin_of_file <- c(-3282496.232239199, 3333134.0276302756)
years <- c(2002:2017)

mainpath <- "/media/memory01/data/users/hmeyer/Antarctica_data/"
datapath <- paste0(mainpath,"/data/")
Rdatapath <- paste0(datapath,"/RData/")
Shppath <- paste0(datapath,"/ShapeLayers/")
MODISpath <- "/media/memory01/data/users/hmeyer/Antarctica_data/MODISLST/"
StationDat <- readOGR(paste0(Shppath,"ClimateStations.shp"))
for (year in years){
  aquapath <- paste0(MODISpath,"/aqua/",year)
  terrapath <- paste0(MODISpath,"/terra/",year)
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
    filelist <- list.files(path,full.names = TRUE,pattern=".tif$")
    filelist_time <- filelist[grep("view_time",filelist)]
    filelist_data <- filelist[-grep("view_time",filelist)]
    
    ###check übereinstimmung
    if (any(substr(filelist_data,nchar(filelist_data)-10,nchar(filelist_data))!=
            substr(filelist_time,nchar(filelist_time)-10,nchar(filelist_time)))){
      # stop("filelist data does not match filelist time")
      filelist_data_night <- filelist_data[lapply(strsplit(filelist_data,"_"),function(x){x[[9]]})=="Night"]
      filelist_data_day <- filelist_data[lapply(strsplit(filelist_data,"_"),function(x){x[[9]]})=="Day"]
      filelist_time_night <- filelist_time[lapply(strsplit(filelist_time,"_"),function(x){x[[8]]})=="Night"]
      filelist_time_day <- filelist_time[lapply(strsplit(filelist_time,"_"),function(x){x[[8]]})=="Day"]
      
      filelist_data_night <- filelist_data_night[lapply(strsplit(filelist_data_night,"_"),function(x){x[[11]]})%in%
                                                   lapply(strsplit(filelist_time_night,"_"),function(x){x[[11]]})]
      filelist_time_night <- filelist_time_night[lapply(strsplit(filelist_time_night,"_"),function(x){x[[11]]})%in%
                                                   lapply(strsplit(filelist_data_night,"_"),function(x){x[[11]]})]
      filelist_data_day <- filelist_data_day[lapply(strsplit(filelist_data_day,"_"),function(x){x[[11]]})%in%
                                               lapply(strsplit(filelist_time_day,"_"),function(x){x[[11]]})]
      filelist_time_day <- filelist_time_day[lapply(strsplit(filelist_time_day,"_"),function(x){x[[11]]})%in%
                                               lapply(strsplit(filelist_data_day,"_"),function(x){x[[11]]})]
      
      filelist_time<-c(filelist_time_day,filelist_time_night)
      filelist_data<-c(filelist_data_day,filelist_data_night)
      if (any(substr(filelist_data,nchar(filelist_data)-10,nchar(filelist_data))!=
              substr(filelist_time,nchar(filelist_time)-10,nchar(filelist_time)))){
        stop("filelist data does not match filelist time")
      }}
    
    
    for (i in 1:length(filelist_time)){
      dat <- stack(filelist_data[i],filelist_time[i])
      names(dat) <- c("LST","Time")
      #     proj4string(dat)<-CRS("+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs") 
      #      extent(dat)<-c(origin_of_file[1],origin_of_file[1]+dim(dat)[2]*1000,
      #                     origin_of_file[2]-dim(dat)[1]*1000,origin_of_file[2])
      daynight <- "Day"
      if("Night"%in%strsplit(filelist_data[i],"_")[[1]]){daynight="Night"}
      dataTable[[sensor]][[i]] <- data.frame("Date"=substr(filelist_time[i],nchar(filelist_time[i])-10,nchar(filelist_time[i])-4),
                                             extract(dat,StationDat),
                                             "Station"=StationDat$Name,
                                             "Sensor"= sensorName,
                                             "daynight"=daynight)
    }
    
    dataTable[[sensor]] <- ldply(dataTable[[sensor]])
  }
  dataTable <- ldply(dataTable)
  save(dataTable,file=paste0(Rdatapath,"extractedData",
                             year,".RData"))
}
