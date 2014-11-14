################################################################################
################################################################################
#                 Process Automatic Rainfall Stations (TTX)
################################################################################
################################################################################
setwd("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/")
outpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/2_ProcessSAWSData/Shapes/"
library(sp)
library (rgdal)
filenames=list.files(pattern=".ttx")


################################################################################
##write data per location
################################################################################  
uniquenames=c()
uniquecoord=data.frame()
for (i in 1:length(filenames)){
  #read ttx files
  data=read.table(filenames[i],sep="\t",header=T)
  #find unique stations by coordinates
  uniquenames=c(uniquenames,as.character(unique(data$StasName)))
  uniquecoord=rbind(uniquecoord,unique(cbind(data$Longitude,data$Latitude)))
################################################################################
##write data per location
################################################################################  
  for (k in 1:length(as.character(unique(data$StasName)))){
    tmp=data[data$StasName==as.character(unique(data$StasName))[k],]
    write.csv(data,paste0("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/perStation/ARS/",as.character(unique(data$StasName))[k],".csv"),row.names=F)
  }  
  print (i)
}
################################################################################
##make a shape Layer of just stations locations
################################################################################
spatialData=SpatialPointsDataFrame(uniquecoord,data=as.data.frame(uniquenames))
proj4string(spatialData) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
names(spatialData)="Station"
writeOGR(spatialData, outpath, "ARS", driver="ESRI Shapefile")

################################################################################
################################################################################
################################################################################
#                 Process Automatic Climate Stations (TXT)
################################################################################
################################################################################
####include lat long
stationcoordiantes=read.csv("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/stationList.csv")
setwd("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/splittedTXT/")
folders=list.files()
shapeTable=data.frame()
missing=c()
for (k in 1:length(folders)){
  setwd("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/splittedTXT/")
  setwd(folders[k])
  filenames=list.files()
  for (i in 1:length(filenames)){
    data=read.table(filenames[i],sep="|",header=T,skip=2,na.strings = c( "------", "----------------","--------"))
    data=data[,c(-1,-ncol(data))]
    data=data[(rowSums(!is.na(data))!=0),]
    title <- readLines(filenames[i], n=1)
    id=substr(title,30,nchar(title))
    title=substr(title,43,nchar(title))
    data=data.frame(title,data)
################################################################################
    #wenn koordinaten vorhanden, ergänze data file um diese
################################################################################
    if (any(as.character(stationcoordiantes$StasName)==as.character(data$title[1]))){
      data$lat=stationcoordiantes[as.character(stationcoordiantes$StasName)==as.character(data$title[1]),"Latitude"]
      data$lon=stationcoordiantes[as.character(stationcoordiantes$StasName)==as.character(data$title[1]),"Long"]
################################################################################
      ###write shape layer of locations
################################################################################
      tmpx=stationcoordiantes[as.character(stationcoordiantes$StasName)==as.character(data$title[1]),"Latitude"]
      tmpy=stationcoordiantes[as.character(stationcoordiantes$StasName)==as.character(data$title[1]),"Long"]
      tmpname=as.character(data$title[1])
      shapeTable=rbind(shapeTable,cbind(tmpx,tmpy,tmpname))
    }
    #wenn kein match mit koordinatenfile, schreib name der station auf "missing" liste
    if (!any(as.character(stationcoordiantes$StasName)==as.character(data$title[1]))){
      missing=c(missing,id)
    }
################################################################################
    #schreibe daten pro station
################################################################################
    write.csv(data,paste0("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/perStation/",as.character(data$title[1]),".csv"),row.names=F)
  
  }
}
################################################################################
#schreibe shapefile der locations
################################################################################
AWS=SpatialPointsDataFrame(data.frame(as.numeric(as.character(shapeTable$tmpx)),as.numeric(as.character(shapeTable$tmpy))),
                       data.frame(shapeTable$tmpname),
                       proj4string = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
)
writeOGR(AWS, outpath, "AWS", driver="ESRI Shapefile")
################################################################################
#dies&das
################################################################################
write.csv(missing,"/media/hanna/ubt_kdata_0005/ClimateDataSAWS/missing.txt",row.names=F)
