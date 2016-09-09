##PlotSpatialAggregations
library(raster)
library(viridis)
library(rgdal)
setwd("/media/hanna/data/Rainfall4SA/Results/Predictions/agg_month/")

base <- readOGR("/home/hanna/Documents/Projects/IDESSA/GIS/TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp",
                "TM_WORLD_BORDERS-0.3")

################################################################################
#Rainy Days
################################################################################
yearly <- raster("../agg_year/2013_rainydays.tif")
base <- crop(base,projectRaster(yearly,
                                crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

base <- spTransform(base,projection(yearly))
monthly <- stack(list.files(,pattern="rainydays.tif$"))
names(monthly)<- month.abb[as.numeric(substr(names(monthly),6,7))]
#overall <- stack(monthly,yearly)
#names(overall)[13] <- "yearly" 

spplot(monthly,col.regions = rev(viridis(100)),
       sp.layout=list("sp.polygons", base, col = "green"))


################################################################################
#Precipitation sums
################################################################################
yearly <- raster("../agg_year/2013_rainsum.tif")
monthly <- stack(list.files(,pattern="rainsum.tif$"))
names(monthly)<- month.abb[as.numeric(substr(names(monthly),6,7))]
#overall <- stack(monthly,yearly)
#names(overall)[13] <- "yearly" 

spplot(monthly,col.regions = rev(viridis(100)))

library(maptools)
data(wrld_simpl)

