### create two table with extracted Data and the corresponding overflight times

library(rgdal)
library(raster)
origin_of_file <- c(-3282496.232239199, 3333134.0276302756)
year <-2013



aquapath <- paste0("/media/hanna/data/Antarctica/data/MODIS_LST/aqua/",
  year,"/mosaics/")
terrapath <-paste0("/media/hanna/data/Antarctica/data/MODIS_LST/terra/",
  year,"/mosaics/")


#StationDat <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationDataRoss.shp",
#                      "StationDataRoss")
StationDat <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationDataAnt.shp",
                      "StationDataAnt")



dataTable <- list()
timeTable <- list()
for (path in c(aquapath,terrapath)){
  if(path==aquapath){sensor=1}
  if(path==terrapath){sensor=2}
  dataTable[[sensor]]<-data.frame(matrix(ncol=nrow(StationDat@data)+1))
  timeTable[[sensor]]<-data.frame(matrix(ncol=nrow(StationDat@data)+1))
  filelist <- list.files(path,full.names = TRUE,pattern=".kea$")
  filelist_time <- filelist[grep("view_time",filelist)]
  filelist_data <- filelist[-grep("view_time",filelist)]
  
  if(any(substr(filelist_time,nchar(filelist_time)-10,nchar(filelist_time)-4)!=
         substr(filelist_data,nchar(filelist_data)-10,nchar(filelist_data)-4))) {
    next
  }
  for (i in 1:length(filelist_time)){
    DataLayer <- raster(readGDAL(paste0("HDF5:",filelist_data[i],"://BAND1/DATA")))
    TimeLayer <- raster(readGDAL(paste0("HDF5:",filelist_time[i],"://BAND1/DATA")))
    
    proj4string(DataLayer)<-CRS("+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs") 
    extent(DataLayer)<-c(origin_of_file[1],origin_of_file[1]+dim(DataLayer)[2]*1000,
                         origin_of_file[2]-dim(DataLayer)[1]*1000,origin_of_file[2])
    proj4string(TimeLayer)<-CRS("+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs") 
    extent(TimeLayer)<-c(origin_of_file[1],origin_of_file[1]+dim(TimeLayer)[2]*1000,
                         origin_of_file[2]-dim(TimeLayer)[1]*1000,origin_of_file[2])
    
    dataTable[[sensor]][i,] <- as.numeric(c(substr(filelist_time[i],nchar(filelist_time[i])-10,nchar(filelist_time[i])-4),
                                            extract(DataLayer,StationDat)))
    timeTable[[sensor]][i,] <- as.numeric(c(substr(filelist_time[i],nchar(filelist_time[i])-10,nchar(filelist_time[i])-4),
                                            extract(TimeLayer,StationDat)))
  }
  
  names(timeTable[[sensor]])<-c("date",as.character(StationDat@data$Name))
  names(dataTable[[sensor]])<-c("date",as.character(StationDat@data$Name))
}
names(timeTable)<-c("Aqua","Terra")
names(dataTable)<-c("Aqua","Terra")


save(dataTable,file=paste0("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/data_extracted_",
year,".RData"))
save(timeTable,file=paste0("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/time_extracted_",
year,".RData"))
