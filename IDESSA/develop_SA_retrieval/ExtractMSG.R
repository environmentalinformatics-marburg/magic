library(raster)
library(rgdal)
library(Rainfall)
year=2010
datapath <- "/media/memory01/data/data01/msg-out-hanna/"
cloudmaskpath <- "/media/memory01/data/data01/CM_SAF_CMa/"
stationpath <- "/media/memory01/data/IDESSA/"
outpath<-"/media/memory01/data/IDESSA/"

stations <- readOGR(paste0(stationpath,"allStations.shp"),"allStations")
stations <- spTransform(stations,
                        CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"))

#msg in unterordnern: zb: "MT9P201011292345_mt09s"
MSG_extract<-data.frame()
#for (year in c("2010","2011","2012")){
yearpath <-paste0(datapath,year,"/")
setwd(yearpath)
months <- list.dirs(recursive=FALSE,full.names = FALSE)
for (month in months){
  monthdir <- paste0(yearpath,"/",month,"/")
  setwd(monthdir)
  days <- list.dirs(,recursive=FALSE,full.names = FALSE)
  for (day in days){
    daydir <- paste0(yearpath,"/",month,"/",day,"/")
    setwd(daydir)
    scenes <- list.dirs(recursive=FALSE,full.names = FALSE)
    
    for (scene in scenes){
      scenedir <- paste0(yearpath,"/",month,"/",day,"/",scene,"/")
      setwd(scenedir)
      #########################################
      #Get MSG data
      ########################################
      MSG <- tryCatch(getChannels(paste0(scenedir,"/cal")),error = function(e)e)
      sunzen <- tryCatch(getSunzenith(paste0(scenedir,"/meta")),error = function(e)e)
      if(inherits(MSG, "error")||inherits(sunzen, "error")) {
        next
      }
      date <- getDate(paste0(scenedir,"/cal"))
      MSG <- stack(MSG,sunzen)
      extent(MSG)<-c(1408689.286,2908890.869, -3493969.487,-2293808.22)
      proj4string(MSG)<-CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs")
      ######
      #Process Cloud Mask
      #####
      cloudpath <- paste0(cloudmaskpath,"/",year,"/",month,"/",day,"/")
      setwd(cloudpath)
      Cloudmaskfile <- list.files(,pattern=date)
      if(length(Cloudmaskfile)==0){next}
      cloudmask <- raster(readGDAL(paste0('HDF5:\"',Cloudmaskfile,'\"://CMa')))
      cloudmask <- crop(cloudmask,c(2325, 2825, 3712-3020, 3712-2620))
      extent(cloudmask)<-c(1408689.286,2908890.869, -3493969.487,-2293808.22)
      proj4string(cloudmask)<-CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs")
      cloudmask[cloudmask==1]=NA
      cloudmask[cloudmask>1]=1
      #Extract data
      #####
      MSG <- tryCatch(mask(MSG,cloudmask),error = function(e)e)
      if(inherits(MSG, "error")){next}
      MSG_extract <- rbind(MSG_extract,data.frame(date,as.character(stations@data$Name),extract(MSG,stations)))
    }
  }
  print (paste0("year ", year, " month ",month, " in process..."))
}
#}

save(MSG_extract,file=paste0(outpath,"ExtractedData_",year,".RData"))





