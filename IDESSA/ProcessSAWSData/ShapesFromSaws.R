
#############################   Automatic Rainfall Stations (TXT)

setwd("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/")
outpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/2_ClimateStationsSAWS/Shapes/"
library(sp)
filenames=list.files(pattern=".ttx")

#sapply(filenames, function(x) writeSHP(x)) #lade alle packages 

 for (i in 1:length(filenames)){
  tmp=read.table(filenames[i],sep="\t",header=T)
#  tmp=SpatialPointsDataFrame(data.frame(tmp$Longitude,tmp$Latitude), tmp)
#  proj4string(tmp) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

#merge und as data frame?!
  uniquecoord=unique(cbind(tmp$Longitude,tmp$Latitude))
  tmp2=SpatialPointsDataFrame(uniquecoord,data=as.data.frame(unique(tmp$StasName)))
  proj4string(tmp2) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  names(tmp2)="Station"

  writeOGR(tmp2, outpath, as.character(filenames[i]), driver="ESRI Shapefile")
  print (i)
}

#############################   Automatic Climate Stations (TXT)

setwd("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/splittedTXT/FiveMin201-2014hanna/")
filenames=list.files()
tmp=read.table(filenames[1],sep="|",header=T,skip=2,na.strings = c( "------", "----------------","--------"))
tmp=tmp[,c(-1,-ncol(tmp))]
tmp=tmp[(rowSums(!is.na(tmp))!=0),]

title <- readLines(filenames[1], n=1)
title=substr(title,43,nchar(title))
tmp=data.frame(title,tmp)

####include lat long
