###match station data with MODIS LST at exact overflight time
rm(list=ls())
library(rgdal)
#StationMeta <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationData.shp","StationData")
StationMeta <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationDataAnt.shp","StationDataAnt")
#

##################### USDA #####################################################
datapath <- c("/media/hanna/data/Antarctica/data/Station/Station_Data_prepared/USDA",
              "/media/hanna/data/Antarctica/data/Station/Station_Data_prepared/LTER",
              "/media/hanna/data/Antarctica/data/Station/Station_Data_prepared/Uni_Wisc/2013")
types<-c("USDA","LTER","UNIWISC")

namestmp<-c()
acc1 <- 0
acc2 <- 0
finaldat <- list()
for (type in types){
  acc1=acc1+1
  setwd(datapath[acc1])
  if(type=="USDA"){
    files<-list.files(,pattern="csv$")
  }
  if (type=="LTER"){
    files<-list.files(,"Tair.jsp")
  }
  if (type=="UNIWISC"){
    files<-list.files(,pattern="txt$")
    header<- c("Year","Julian day","Month","Day","One hour observation time",
               "Temperature (C)","Pressure (hPa)","Wind Speed (m/s)","Wind Direction",
               "Relative Humidity (%)","Delta-T (C)")
  }
  
  
  if (type=="USDA"){
    namestmp <- c(namestmp,substr(files,1,nchar(files)-8))
    for (i in 1:length(files)){
      acc2 <- acc2 + 1
      stationdat=read.csv(files[i],header=F)
      header<-c()
      for (k in 1:ncol(stationdat)){
        header[k] <- paste(stationdat[1,k],stationdat[2,k],stationdat[3,k])
      }
      stationdat=read.csv(files[i],skip=3,header=F)
      names(stationdat)<-header
      doy <- stationdat$'DAY OF YEAR'
      hour <- stationdat$'HOUR'/100
      if (any(names(stationdat)=='Air Temp deg C')){
        airT<-stationdat$'Air Temp deg C'} else{
          airT<-stationdat$'Air Temp, 1 deg C'}
      finaldat[[acc2]] <- data.frame("doy"=as.numeric(doy),
                                     "time"=hour,
                                     "airT"=airT)
    }}

  if (type=="LTER"){
    
    namematches=unlist(lapply(substr(files,1,nchar(files)-9),function(x){
      which(StationMeta@data$LTERIdn==x)}))

    namestmp <- c(namestmp,as.character(StationMeta@data$Name[namematches]))

    for (i in 1:length(files)){
      acc2 <- acc2 + 1
      stationdat<-read.table(files[i],skip=26,header=T,sep=",")
      stationdat <- stationdat[substr(stationdat$DATE_TIME,7,10)=="2013",]
      if(nrow(stationdat)<2){next}
      stationdat <- stationdat[,-which(names(stationdat)=="AIRT_COMMENTS")]
      airT<-c()
      if (any(names(stationdat)=='AIRT2M')){
        airT<-stationdat$'AIRT2M'} else{
          if(any(names(stationdat)=="AIRT3M")){
            airT<-stationdat$'AIRT3M'}else{
              airT<-stationdat$'AIRT1M'
            }}
      time_tmp <-  substr(stationdat$DATE_TIME,11,16)
      doy <- as.POSIXlt(substr(stationdat$DATE_TIME,1,10), format = "%m/%d/%Y")$yday+1
      airT<-aggregate(airT, by=list(as.numeric(paste0(doy,substr(time_tmp,2,3)))),
                               FUN=mean, na.rm=TRUE)$x
     
      time <- substr(unique(paste0(doy,"_",substr(time_tmp,1,3))),nchar(unique(
        paste0(doy,"_",substr(time_tmp,1,3))))-1,nchar(unique(paste0(doy,"_",substr(time_tmp,1,3)))))
      
      doy <-  substr(unique(paste0(doy,"_",substr(time_tmp,1,3))),nchar(unique(
        paste0(doy,"_",substr(time_tmp,1,3))))-6,nchar(unique(paste0(doy,"_",substr(time_tmp,1,3))))-4)
   
      finaldat[[acc2]] <- data.frame("doy"=as.numeric(doy),
                                     "time"=as.numeric(time),
                                     "airT"=airT)
      
    }}
  
  
  if(type=="UNIWISC"){
    stid<-unique(substr(files,1,3))
    
 #   namematches=unlist(lapply(stid,function(x){
#      which(as.character(StationMeta@data$HeadrID)==x)}))
    namematches <- which(StationMeta@data$HeadrID%in%stid==TRUE)
    
    
    namestmp <- c(namestmp,as.character(StationMeta@data$Name[namematches]))

    for (i in 1:length(stid)){
      acc2 <- acc2 + 1
      file_st<-files[substr(files,1,3)==stid[i]]
 #     if (length(file_st)!=12){next}
      stationdat<-data.frame()
      for (k in 1:length(file_st)){
        tmp=read.table(file_st[k],header=F,skip=2)
        names(tmp)<-header
        stationdat<-rbind(stationdat,tmp)
      }
      doy <- stationdat$'Julian day'
      hour <- stationdat$'One hour observation time'/100
      stationdat$'Temperature (C)'[stationdat$'Temperature (C)'==444]=NA # remove NA values
      airT <-stationdat$'Temperature (C)'
      finaldat[[acc2]] <- data.frame("doy"=as.numeric(doy),
                                     "time"=as.numeric(hour),
                                     "airT"=airT)
      }
  }
}
names(finaldat)<- namestmp
names(finaldat) <- gsub("([ ])", "", names(finaldat))

StationMeta@data$Name <- gsub("([.])", "",StationMeta@data$Name)
StationMeta@data$Name <- gsub("([ ])", "", StationMeta@data$Name)
finaldat <- finaldat[which(names(finaldat)%in%StationMeta@data$Name==TRUE)]

#subset ross sea
#StationMetaRoss <- readOGR("/media/hanna/data/Antarctica/data/StationDataRoss.shp","StationDataRoss")
#StationMetaRoss@data$Name <- gsub("([.])", "",StationMetaRoss@data$Name)
#StationMetaRoss@data$Name <- gsub("([ ])", "", StationMetaRoss@data$Name)

#finaldat <- finaldat[names(finaldat)%in%StationMetaRoss@data$Name]

save(finaldat,file="/media/hanna/data/Antarctica/results/ExactTimeEvaluation/Stationdat.RData")
