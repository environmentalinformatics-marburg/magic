# OS detection
dsn <- switch(Sys.info()[["sysname"]], 
              "Linux" = "/media/permanent/",
              "Windows" = "E:/")

# Libraries
library(rgdal)
library(raster)

# Working directory
setwd(paste0(dsn, "active/osm_google_imagery/"))

# Functions from 'magic'
for (i in c("getTileCenters.R", "getOsmTiles.R", "getGoogleTiles.R", 
            "osmRsmplMrg.R", "dsmRsmplMrg.R"))
  source(paste0(dsn, "active/osm_google_imagery/scripts/src/", i))

# Read plot information in WGS84, Lat/Lon
# Alternatively, one can read a csv file with PlotID, Lon, Lat
# plt <- read.table("filename.cvs", header = TRUE, sep = ",")
plt <- data.frame(PlotID = "Test",
                  Lon = 11.638706,
                  Lat = 48.102262)
coordinates(plt) <- ~ Lon + Lat
projection(plt) <- CRS("+init=epsg:4326")
plt.utm32n <- spTransform(plt, CRS("+init=epsg:32632")) 

i <- 1
for (i in 1:nrow(plt)) {
  # Current plot
  plot <- as.character(plt@data[i, "PlotID"])
  # Coordinates of current plot
  crds <- plt.utm32n[i, ]
  # Relative tile coordinates; rds = radius, res = extend of individual tiles
  # before merge (mrg); do not change if zoom = 19
  cntr <- getTileCenters(plt.rds = 200, plt.res = 50)
  
  # Download and merge OSM data
#   osm <- getOsmTiles(tile.cntr = cntr, 
#                      location = crds, 
#                      plot.res = 50, 
#                      plot.bff = 5,
#                      tmp.folder = temp/", 
#                      path.out = "data/", 
#                      plot = plot,
#                      type = "bing", 
#                      zoom = 19,
#                      mergeTiles = TRUE)
#   
#   osm.mrg <- osmRsmplMrg(path = paste0("data/", plot), 
#                          pattern = "kili_tile_.*.tif$", 
#                          rsmpl.exe = TRUE, 
#                          path.rsmpl = paste0("data/", plot),
#                          pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
#                          n.cores = 4, 
#                          file.rsmpl.mrg = paste0("data/", plot, ".tif"), 
#                          overwrite = TRUE)
  
  #   # Download and merge Google data
    dsm <- getGoogleTiles(tile.cntr = cntr, 
                          location = crds, 
                          type = "satellite", rgb = TRUE,
                          plot.res = 50, 
                          plot.bff = 10, 
                          plot = plot,
                          path.out = "data/",
                          zoom = 19)
    
    dsm.mrg <- dsmRsmplMrg(path = paste0("data/", plot), 
                           pattern = "kili_tile_.*.tif$", 
                           rsmpl.exe = TRUE, 
                           path.rsmpl = paste0("data/", plot),
                           pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
                           n.cores = 4, 
                           file.rsmpl.mrg = paste0("data/", plot, ".tif"), 
                           overwrite = TRUE, 
                           crop.google = TRUE, 
                           crop.radius = 10)
}