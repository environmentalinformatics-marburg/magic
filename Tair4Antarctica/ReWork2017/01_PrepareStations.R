rm(list=ls())
library(raster)
library(rgdal)

scriptpath <- "/home/hanna/Documents/Release/environmentalinformatics-marburg/magic/Tair4Antarctica/ReWork2017/"
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"

datapath <- paste0(mainpath,"/data/")
visualizationpath <- paste0(mainpath,"/visualizations/")
climatestationdat <- paste0(datapath,"/ClimateStations/raw/")
source(paste0(scriptpath,"/00_functions_StationImport.R"))

# load Uni Wisc. data
setwd(climatestationdat)
paths <-list.files("Univ_Wisconsin/Hourly_Data/",
                   full.names = TRUE,pattern=".txt$",recursive=TRUE)
paths <- paths[-grep("readme",paths)]
alldat_Wisc <- data.frame()
for (i in 1:length(paths)){
  alldat_Wisc <- rbind(alldat_Wisc,TairFromUWISC(paths[i]))
}
# load USDA data
paths <- list.files("USDA/",pattern=".xls",full.names = TRUE,
                    recursive = TRUE)
paths <- paths[-grep("graph_labels",paths)]
alldat_USDA <- data.frame()
for (i in 1:length(paths)){
  alldat_USDA <- rbind(alldat_USDA,TairFromUSDA(paths[i]))
}

# load LTER data
paths <-list.files("LTER/",
                   full.names = TRUE,pattern="Tair.jsp$",recursive = TRUE)
paths <- paths[-grep("readme",paths)]
alldat_LTER <- data.frame()
for (i in 1:length(paths)){
  alldat_LTER <- rbind(alldat_LTER,TairFromLTER(paths[i]))
}

# load Italy data
paths <- list.files("italy/",
                    full.names = TRUE,recursive = TRUE, pattern=".txt$")
alldat_Italy <- data.frame()
for (i in 1:length(paths)){
  alldat_Italy <- rbind(alldat_Italy,TairFromItaly(paths[i]))
}

#### Clean up data
merged <- rbind(alldat_USDA,alldat_Wisc,alldat_LTER,alldat_Italy)
merged <- merged[complete.cases(merged),]


#### Create shapefile
stations <- data.frame("Name"=unique(merged$Name))
stations$Lat <- unlist(lapply(stations$Name,function(x){merged$Lat[merged$Name==x][1]}))
stations$Lon <- unlist(lapply(stations$Name,function(x){merged$Lon[merged$Name==x][1]}))

merged_sp <- SpatialPointsDataFrame(coords <- data.frame("x"=stations$Lon,
                                                         "y"=stations$Lat),
                                    data <- stations,
                                    proj4string = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
merged_sp <- spTransform(merged_sp,"+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs")

LSTExt <- readOGR(paste0(datapath,"ShapeLayers/MSG_NotNA.shp"),"MSG_NotNA")
stations_select <- intersect(merged_sp,LSTExt)
merged <- merged[merged$Name%in%stations_select$Name,]


#for manual time series check:
pdf(paste0(visualizationpath,"timeseriescheck.pdf"))
for (i in 1: length(unique(merged$Name))){
  plot(merged$Date[merged$Name==unique(merged$Name)[i]],
       merged$Temperature[merged$Name==unique(merged$Name)[i]],
       pch=16,cex=0.4,xlab="Date",ylab="Temperature",
       main=unique(merged$Name)[i])
       #,xlim=c(0,365))
}
dev.off()

#manual check of the data
merged[merged$Name=="VictoriaValley"&merged$Temperature<(-39),"Temperature"] <- NA
merged <- merged[-which(merged$Name%in%c("DismalIsland","Mizuho","MountSiple"))]
stations_select <- stations_select[stations_select$Name%in%unique(merged$Name),]

save(merged,file=paste0(datapath,"/RData/stationdat2013.RData"))
writeOGR(stations_select, paste0(datapath,"ShapeLayers"), 
         "ClimateStations", driver="ESRI Shapefile",overwrite_layer = TRUE)