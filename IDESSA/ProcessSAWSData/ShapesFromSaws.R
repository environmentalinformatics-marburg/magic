
#############################   Automatic Rainfall Stations (TXT)

setwd("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/")
outpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/2_ProcessSAWSData/Shapes/"
library(sp)
library (rgdal)
filenames=list.files(pattern=".ttx")


##make a shape Layer of just stations locations
for (i in 1:length(filenames)){
  #read ttx files
  data=read.table(filenames[i],sep="\t",header=T)
  #find unique stations by coordinates
  uniquecoord=unique(cbind(data$Longitude,data$Latitude))
  #Make point shape from unique stations
  spatialData=SpatialPointsDataFrame(uniquecoord,data=as.data.frame(unique(data$StasName)))
  proj4string(spatialData) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  names(spatialData)="Station"
  writeOGR(spatialData, outpath, as.character(filenames[i]), driver="ESRI Shapefile")
  print (i)
}
##make a shape layer of the whole data set
for (i in 1:length(filenames)){
  data=read.table(filenames[i],sep="\t",header=T)
  spatialData=SpatialPointsDataFrame(cbind(data$Longitude,data$Latitude),data)
  proj4string(spatialData) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  writeOGR(spatialData, outpath, paste("full_",as.character(filenames[i])), driver="ESRI Shapefile")
}
#############################   Automatic Climate Stations (TXT)

setwd("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/splittedTXT/FiveMin201-2014hanna/")
filenames=list.files()
data=read.table(filenames[1],sep="|",header=T,skip=2,na.strings = c( "------", "----------------","--------"))
data=data[,c(-1,-ncol(data))]
data=data[(rowSums(!is.na(data))!=0),]

title <- readLines(filenames[1], n=1)
title=substr(title,43,nchar(title))
data=data.frame(title,data)

####include lat long
