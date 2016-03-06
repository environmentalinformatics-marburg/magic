##
rm(list=ls())
library(raster)
library(rgdal)
library(Rsenal)
library(caret)

sampsize <- 0.25
#load("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/dataset.RData")


ComparisonTable_Aqua <- get(load("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/ComparisonTable_Aqua.RData"))
ComparisonTable_Terra <- get(load("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/ComparisonTable_Terra.RData"))

#ComparisonTable_Aqua <- ComparisonTable_Aqua [which(
#  !names(ComparisonTable_Aqua)%in%(c("Byrd","Brianna","Henry","Baldrick",
#                                     "canada_met","Theresa",
#                                     "Ago-4","Elizabeth","Nico","Tom")))]

#ComparisonTable_Terra <- ComparisonTable_Terra [which(
#  !names(ComparisonTable_Terra)%in%(c("Byrd","Brianna","Henry","Baldrick",
#                                      "canada_met","Theresa",
#                                      "Ago-4","Elizabeth","Nico","Tom")))]

statdat <- c()
LST <- c()
station <- c()
doy<-c()
time<-c()
for (i in 1:length(ComparisonTable_Aqua)){
  statdat <- c(statdat,ComparisonTable_Aqua[[i]]$statdat)
  LST <- c(LST,ComparisonTable_Aqua[[i]]$LST)
  doy <- c(doy,ComparisonTable_Aqua[[i]]$doy)
  time <- c(time,ComparisonTable_Aqua[[i]]$time)
  station <- c(station,rep(names(ComparisonTable_Aqua)[i],
                           length(ComparisonTable_Aqua[[i]]$LST)))
}
for (i in 1:length(ComparisonTable_Terra)){
  statdat <- c(statdat,ComparisonTable_Terra[[i]]$statdat)
  LST <- c(LST,ComparisonTable_Terra[[i]]$LST)
  doy <- c(doy,ComparisonTable_Terra[[i]]$doy)
  time <- c(time,ComparisonTable_Terra[[i]]$time)
  station <- c(station,rep(names(ComparisonTable_Terra)[i],
                           length(ComparisonTable_Terra[[i]]$LST)))
}


dataset <- data.frame("statdat"=statdat,"LST"=LST,"station"=station,
                            "doy"=doy,"time"=time,
                            "month"=months(as.POSIXct(paste0("2013",doy),
                                                      format="%Y%j",tz="UTC"),abbreviate=T),
                            
                            "sensor"=c(rep("Aqua",length(unlist(ComparisonTable_Aqua))),
                                       rep("Terra",length(unlist(ComparisonTable_Terra)))))

dataset$month <- factor(dataset$month, levels = c("Jan","Feb","Mar",
                                                            "Apr","May","Jun",
                                                            "Jul","Aug","Sep",
                                                            "Oct","Nov","Dec"))


StationMeta <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationDataAnt.shp",
                       "StationDataAnt")
StationMeta@data$Name <- gsub("([.])", "",StationMeta@data$Name)
StationMeta@data$Name <- gsub("([ ])", "", StationMeta@data$Name)


dem <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Overall/dem_crop.tif")
slope <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Overall/slope.tif")
aspect <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Overall/aspect.tif")
skyview <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Overall/SVF.sdat")
#insolation <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Overall/insolation.sdat")
ice <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Quantarctica2/Basemap/Terrain/BEDMAP2/bedmap2_thickness.tif")
MSGext <- raster("/media/hanna/data/Antarctica/data/Auxiliary/MSGExtent.tif")
proj4string(skyview)<-proj4string(dem)


reclt <- c(0,45,1,315,360,1,45,135,2, 135,225,3,225,315,4)
aspect <- reclassify(aspect,reclt)
  


ice[ice>0]=1
ice[ice<0]=0
auxiliary <- list(dem,slope,aspect,skyview,ice)
auxiliary <- lapply(auxiliary,function(x){proj4string(x)=proj4string(StationMeta)
return(x)})


auxiliary <- lapply(auxiliary,extract,StationMeta)

stationprop<-data.frame(StationMeta$Name,matrix(unlist(auxiliary), nrow=length(StationMeta), byrow=F))
names(stationprop)[2:ncol(stationprop)]<- c("dem","slope","aspect","skyview",
                                            "ice")

property <- data.frame(matrix(ncol=ncol(stationprop)-1,nrow=nrow(dataset)))
for (k in 1:(ncol(stationprop)-1)){
  for (i in 1:length(stationprop$StationMeta.Name)){
    property[which(as.character(dataset$station)==
                     as.character(stationprop$StationMeta.Name)[i]),k]=
      stationprop[i,k+1]
  }
}
names(property) <- c("dem","slope","aspect","skyview",
                     "ice")
dataset <- data.frame(dataset,property)
dataset$type<-"NA"
for (i in 1:nrow(dataset)){
  dataset$type[i] <-as.character(StationMeta@data$Type[
    StationMeta@data$Name==dataset$station[i]])
}
############ define data types

dataset$aspect <- as.factor(dataset$aspect)
levels(dataset$aspect)<-c("North","East","South","West")
dataset$time <- as.factor(dataset$time)
dataset$ice <- as.factor(dataset$ice)
levels(dataset$ice)<-c("NoIce","Ice")
dataset$type <- as.factor(dataset$type)
save(dataset,file="/media/hanna/data/Antarctica/results/ExactTimeEvaluation/dataset.RData")


################################################################################
#Prepare and Split data
################################################################################

dataset<-dataset[complete.cases(dataset),]
set.seed(100)
trainIndex <- createDataPartition(dataset$station, 
                                  p = sampsize,
                                  list = FALSE,
                                  times = 1)
trainData <- dataset[trainIndex,]
testData <- dataset[-trainIndex,]

save(trainData,file="/media/hanna/data/Antarctica/results/ML/trainData.RData")
save(testData,file="/media/hanna/data/Antarctica/results/ML/testData.RData")
