rm(list=ls())
library(raster)
library(rgdal)
load("/home/hanna/Documents/Projects/IDESSA/airT/forPaper/modeldat/modeldata.RData")
shp <- readOGR("/home/hanna/Documents/Projects/IDESSA/airT/forPaper/shp/WeatherStations.shp")

dataset <- dataset[complete.cases(dataset$ndvi),]

stationCor <- c()
for (i in 1:length(unique(dataset$Station))){
  subs <- dataset[dataset$Station==unique(dataset$Station)[i],]
  stationCor[i] <- cor(subs$ndvi,subs$Tair)
}
stationCor <- data.frame("Station"=unique(dataset$Station),"cor"=stationCor)

shp <- shp[shp$plot%in%stationCor$Station,]
shp$ndvicor <- merge(shp@data,stationCor,by.y="Station",by.x="plot")$cor

spplot(shp,"ndvicor")
