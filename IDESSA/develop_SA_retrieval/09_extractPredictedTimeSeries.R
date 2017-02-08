###extract time series of predicted rainfall for a point or group of points
library(rgdal)
library(raster)

years <- 2010:2014

predpath <- "/media/memory01/data/IDESSA/Results/Predictions/agg/"
points <- "/media/memory01/data/IDESSA/auxiliarydata/ownStations.shp"
points <- readOGR(points,"ownStations")
points <- spTransform(points,"+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs")

results <- as.data.frame(matrix(nrow=length(points)))
for (i in 1:length(years)){
  predfiles <- list.files(paste0(predpath,years[i],"/agg_day/"),pattern="rainsum.tif$",
                                 full.names=TRUE)
    rst <- stack(predfiles)
    extr <- extract(rst,points,df=TRUE)
    results <- data.frame(results,extr)  
}
results <- results[,-c(1:2)]

dates <- sub("_rainsum","",names(results))
dates <- as.numeric(sub("X","",dates))



results <- t(results)
results <- data.frame(dates,results)
names(results) <- c("date",points$name)
row.names(results)<-1:nrow(results)


save(results,
     file="/media/memory01/data/IDESSA/Results/Predictions/timeSeriesStations/timeSeriesStatOwn.RData")
