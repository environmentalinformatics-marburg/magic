
paths <-list.files("/media/hanna/data/Antarctica/ReModel2017/data/ClimateStations/raw/Univ_Wisconsin/Hourly_Data/2013/",
                   full.names = TRUE,pattern=".txt$")
alldat_Wisc <- data.frame()
for (i in 1:length(paths)){
  alldat_Wisc <- rbind(alldat_Wisc,TairFromUWISC(paths[i]))
}
###############################
paths <- list.files("/media/hanna/data/Antarctica/ReModel2017/data/ClimateStations/raw/USDA/",
                    pattern="13w.xlsx",full.names = TRUE,recursive = TRUE)
paths <- paths[grep("/Data/",paths)]
alldat_USDA <- data.frame()
for (i in 1:length(paths)){
  alldat_USDA <- rbind(alldat_USDA,TairFromUSDA(paths[i]))
}


paths <-list.files("/media/hanna/data/Antarctica/ReModel2017/data/ClimateStations/raw/LTER/",
                   full.names = TRUE,pattern="Tair.jsp$",recursive = TRUE)
alldat_LTER <- data.frame()
for (i in 1:length(paths)){
  alldat_LTER <- rbind(alldat_LTER,TairFromLTER(paths[i]))
}

paths <- list.files("/media/hanna/data/Antarctica/ReModel2017/data/ClimateStations/raw/italy/",
                    full.names = TRUE,recursive = TRUE, pattern=".txt$")
alldat_Italy <- data.frame()
for (i in 1:length(paths)){
  alldat_Italy <- rbind(alldat_Italy,TairFromItaly(paths[i]))
}
####
merged <- rbind(alldat_USDA,alldat_Wisc,alldat_LTER,alldat_Italy)
merged <- merged[merged$Year=="2013",]

stations <- data.frame("Name"=unique(merged$Name))
stations$Lat <- unlist(lapply(stations$Name,function(x){merged$Lat[merged$Name==x][1]}))
stations$Lon <- unlist(lapply(stations$Name,function(x){merged$Lon[merged$Name==x][1]}))

library(raster)
merged_sp <- SpatialPointsDataFrame(coords <- data.frame("x"=stations$Lon,
                                                         "y"=stations$Lat),
                                    data <- stations,
                                    proj4string = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
merged_sp <- spTransform(merged_sp,"+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs")

