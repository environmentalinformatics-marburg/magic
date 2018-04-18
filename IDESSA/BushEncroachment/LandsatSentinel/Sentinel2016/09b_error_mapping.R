# error mapping
library(raster)
library(rgdal)
library(plyr)

# tile validation results
val <- list.files("D:/model_validation/", pattern = ".csv$", full.names = TRUE)
valid <- rbind(read.csv(val[1]), read.csv(val[2]), read.csv(val[3]), read.csv(val[4]), read.csv(val[5]))


# tile location
tiles <- list.files("D:/bush_classification/classifiedTiles/", full.names = TRUE, pattern = ".tif$")

locs <- lapply(seq(length(tiles)), function(i){
  t <- raster(tiles[i])
  x <- t@extent[1] + 500
  y <- t@extent[3] + 500
  tile <- t@data@names
  return(data.frame(tile = tile, x = x, y = y))
})
locs <- do.call(rbind, locs)

locs_valid <- plyr::join(locs, valid, by = "tile")
locs_valid[is.na(locs_valid)] <- 999

# split in train and test
locs_train <- locs_valid[locs_valid$RMSE == 999,]
locs_test <- locs_valid[locs_valid$RMSE < 999,]

coordinates(locs_train) <- ~ x + y
projection(locs_train) <- "+proj=tmerc +lat_0=0 +lon_0=23 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
writeOGR(locs_train, "D:/summary_results/locations_train.shp", driver = "ESRI Shapefile", layer = "valid")

coordinates(locs_test) <- ~ x + y
projection(locs_test) <- "+proj=tmerc +lat_0=0 +lon_0=23 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
writeOGR(locs_test, "D:/summary_results/locations_test.shp", driver = "ESRI Shapefile", layer = "valid")

