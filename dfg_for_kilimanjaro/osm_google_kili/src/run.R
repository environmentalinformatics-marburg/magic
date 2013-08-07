### Environmental settings

# Clear workspace
rm(list = ls(all = TRUE))

# Working directory
path.wd <- "G:/ki_osm"
setwd(path.wd)

# Required packages and functions
lib <- c("raster", "rgdal", "parallel")
sapply(lib, function(...) require(..., character.only = T))

source("src/getTileCenters.R")
source("src/getOsmTiles.R")
source("src/getGoogleTiles.R")


# ### Geographic extent
#
# ## KiLi Plot coordinates (used in 1st landuse classification)
# 
# # Import data and select complete cases only
# data.coords <- read.csv(file.coords, header = TRUE, stringsAsFactors = FALSE)[,c("PlotID", "Lon", "Lat")]
# data.coords <- data.coords[complete.cases(data.coords),]
# 
# # Set coordinates and coordinate reference system (CRS) of SpatialPointsDataFrame
# coordinates(data.coords) <- c("Lon", "Lat")
# projection(data.coords) <- CRS("+proj=longlat +datum=WGS84")
# 
# # Mercator plot coordinates
# data.coords.mrc <- spTransform(data.coords, 
#                                CRS("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs"))
# 
# # Distance between plot and final image boundary
# plt.rds <- 2000
# # Extent of single OSM tiles
# plt.res <- 250
# 
# # Generate list containing relative coordinates of single tile centers
# tile.cntr <- getTileCenters(plt.rds = plt.rds, 
#                             plt.res = plt.res)

## Kibo summit

# Reprojection of Lonlat coordinates
kibo.summit <- data.frame(Lon = 37.353333, Lat = -3.075833, PlotID = "Kibo")
coordinates(kibo.summit) <- c("Lon", "Lat")
projection(kibo.summit) <- CRS("+init=epsg:4326")
kibo.summit.utm <- spTransform(kibo.summit, CRS("+init=epsg:32737"))

# Generate list containing relative coordinates of single tile centers
tile.cntr <- getTileCenters(plt.rds = 80000, # 80 km radius around Kibo summit
                            plt.res = 10000) # 10 km distance between each grid point


### OSM 

## Download, rasterize and merge single OSM tiles per research plot

# Get OSM tiles
osm <- getOsmTiles(tile.cntr = tile.cntr, 
                   location = kibo.summit.utm, 
                   plot.res = 5000, 
                   tmp.folder = "C:/Users/fdetsch/AppData/Local/Temp/R_raster_tmp", 
                   path.out = "out", 
                   type = "bing", zoom = 16, mergeTiles = F)

osm <- Reduce(rbind, osm)
          
# Merge single OSM tiles to complete raster
cl <- makeCluster(4)
osm.rst <- parLapply(cl, osm$file, stack)
osm.mrg <- do.call(function(...) {merge(..., tolerance = 1, overlap = F, 
                                        filename = "out/kili_all", format = "GTiff", overwrite = T)
}, osm.rst)


### Google Maps

# Download from Google Maps server
dsm <- getGoogleTiles(tile.cntr = tile.cntr, 
                 location = kibo.summit.utm, 
                 plot.res = 5000, 
                 path.out = "out", 
                 type = "satellite", scale = 2, rgb = T)

# Merge single dsm tiles to complete raster
dsm.rst <- parLapply(cl, dsm$file, stack)
dsm.mrg <- do.call(function(...) {merge(..., tolerance = 1, overlap = F, 
                                        filename = "out/kili_dsm_all", format = "GTiff", overwrite = T)
}, dsm)
stopCluster(cl)
