# OS detection
dsn <- switch(Sys.info()[["sysname"]], 
              "Linux" = "/media/permanent/",
              "Windows" = "E:/")

# Libraries
library(rgdal)
library(raster)

# Functions from 'magic'
for (i in c("getTileCenters.R", "getOsmTiles.R", "getGoogleTiles.R", 
            "osmRsmplMrg.R", "dsmRsmplMrg.R"))
  source(paste0(dsn, "repositories/magic/dfg_for_kilimanjaro/osm_google_kili/src/", i))

# Working directory
setwd(paste0(dsn, "kilimanjaro/plot_surroundings_ah"))

# # Create folder structure
# dir.create("src/")
# dir.create("data/tls/osm")
# dir.create("data/tls/dsm")

# Plot coordinates (file #1)
plt <- read.csv("data/station_master_utm.csv")
coordinates(plt) <- ~ Lon + Lat
projection(plt) <- CRS("+init=epsg:32737")

# Plot coordinates (file #2)
plt.db <- read.csv("data/Complete_Plots_midPoint_coordinates_update24032014.csv", 
                   nrows = 83)
plt.db$Lon <- as.numeric(gsub(",", ".", plt.db$Lon))
plt.db$Lat <- as.numeric(gsub(",", ".", plt.db$Lat))
coordinates(plt.db) <- ~ Lon + Lat
projection(plt.db) <- CRS("+init=epsg:4326")

# WGS84
plt.db.wgs84 <- spTransform(plt.db, CRS("+init=epsg:32737"))

diff.wgs84.x <- coordinates(plt.db.wgs84)[, 1] - plt.db$Easting
diff.wgs84.y <- coordinates(plt.db.wgs84)[, 2] - plt.db$Northing

# Clarke80
plt.db.clrk80 <- spTransform(plt.db, CRS("+init=epsg:21037"))

diff.clrk80.x <- coordinates(plt.db.clrk80)[, 1] - plt.db$Easting
diff.clrk80.y <- coordinates(plt.db.clrk80)[, 2] - plt.db$Northing

plt.db.clrk80$PlotID[abs(diff.clrk80.x) > 1]
plt.db.clrk80$PlotID[abs(diff.clrk80.y) > 1]

diff.clrk80.x[abs(diff.clrk80.x) > 1]
diff.clrk80.y[abs(diff.clrk80.y) > 1]

# tmp <- plt.db.wgs84[plt2$PlotID %in% c("sav0", "sav4", "sav5", "mai5"), ]
# tmp <- plt.db.wgs84[plt2$PlotID %in% c("kid1"), ]
# library(plotKML)
# plotKML(tmp)

for (i in 1:nrow(plt)) {
  # Current plot
  plot <- as.character(plt@data[i, "PlotID"])
  # Coordinates of current plot
  crds <- plt[i, ]
  # Relative tile coordinates
  cntr <- getTileCenters(plt.rds = 2000, plt.res = 500)
  
  # Download and merge OSM data
  osm <- getOsmTiles(tile.cntr = cntr, 
                     location = crds, 
                     plot.res = 500, 
                     plot.bff = 50,
                     tmp.folder = "C:/Users/fdetsch/AppData/Local/Temp/R_raster_tmp", 
                     path.out = "data/tls/osm", 
                     plot = plot,
                     type = "bing", mergeTiles = TRUE)
  
  osm.mrg <- osmRsmplMrg(path = paste0("data/tls/osm/", plot), 
                         pattern = "kili_tile_.*.tif$", 
                         rsmpl.exe = TRUE, 
                         path.rsmpl = paste0("data/tls/osm/", plot),
                         pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
                         n.cores = 4, 
                         file.rsmpl.mrg = paste0("data/tls/osm/", plot, ".tif"), 
                         overwrite = TRUE)
  
  #   # Download and merge Google data
  #   dsm <- getGoogleTiles(tile.cntr = cntr, 
  #                         location = crds, 
  #                         type = "satellite", rgb = TRUE,
  #                         plot.res = 500, 
  #                         plot.bff = 50, 
  #                         plot = plot,
  #                         path.out = "data/tls/dsm")
  #   
  #   dsm.mrg <- dsmRsmplMrg(path = paste0("data/tls/dsm/", plot), 
  #                          pattern = "kili_tile_.*.tif$", 
  #                          rsmpl.exe = TRUE, 
  #                          path.rsmpl = paste0("data/tls/dsm/", plot),
  #                          pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
  #                          n.cores = 4, 
  #                          file.rsmpl.mrg = paste0("data/tls/dsm/", plot, ".tif"), 
  #                          overwrite = TRUE, 
  #                          crop.google = TRUE, 
  #                          crop.radius = 150)
}


for (i in 1:nrow(plt.db.wgs84)) {
  # Current plot
  plot <- as.character(plt.db.wgs84@data[i, "PlotID"])
  
  if (file.exists(paste0("data/tls/osm/", plot, ".tif"))) {
    cat("File", paste0("data/tls/osm/", plot, ".tif"), "already exists!")
    next
  } else {
    # Coordinates of current plot
    crds <- plt.db.wgs84[i, ]
    # Relative tile coordinates
    cntr <- getTileCenters(plt.rds = 2000, plt.res = 500)
    
    # Download and merge OSM data
    osm <- getOsmTiles(tile.cntr = cntr, 
                       location = crds, 
                       plot.res = 500, 
                       plot.bff = 50,
                       tmp.folder = "C:/Users/fdetsch/AppData/Local/Temp/R_raster_tmp", 
                       path.out = "data/tls/osm", 
                       plot = plot,
                       type = "bing", mergeTiles = TRUE)
    
    osm.mrg <- osmRsmplMrg(path = paste0("data/tls/osm/", plot), 
                           pattern = "kili_tile_.*.tif$", 
                           rsmpl.exe = TRUE, 
                           path.rsmpl = paste0("data/tls/osm/", plot),
                           pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
                           n.cores = 4, 
                           file.rsmpl.mrg = paste0("data/tls/osm/", plot, ".tif"), 
                           overwrite = TRUE)
    
    #   # Download and merge Google data
    #   dsm <- getGoogleTiles(tile.cntr = cntr, 
    #                         location = crds, 
    #                         type = "satellite", rgb = TRUE,
    #                         plot.res = 500, 
    #                         plot.bff = 50, 
    #                         plot = plot,
    #                         path.out = "data/tls/dsm")
    #   
    #   dsm.mrg <- dsmRsmplMrg(path = paste0("data/tls/dsm/", plot), 
    #                          pattern = "kili_tile_.*.tif$", 
    #                          rsmpl.exe = TRUE, 
    #                          path.rsmpl = paste0("data/tls/dsm/", plot),
    #                          pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
    #                          n.cores = 4, 
    #                          file.rsmpl.mrg = paste0("data/tls/dsm/", plot, ".tif"), 
    #                          overwrite = TRUE, 
    #                          crop.google = TRUE, 
    #                          crop.radius = 150)
  }
}

# Plots with inconvenient Bing aerial quality -> Google Maps retrieval
cld <- c("sav5", "sav4", "sav3", "sav0", 
         "mai5", "mai4", "mai1", "mai0", 
         "hom5", 
         "hel5", "hel4", "hel3", "hel2", "hel1", 
         "gra5", 
         "fpd4", "fpd3", 
         "fer5", "fer4", "fer3", "fer2", "fer1", "fer0", 
         "fed5", "fed4", "fed3", "fed2", "fed1")
cld.ind <- sapply(cld, function(i) {
  grep(i, plt.db.wgs84$PlotID)
})

for (i in cld.ind) {
  # Current plot
  plot <- as.character(plt.db.wgs84@data[i, "PlotID"])
  
  if (file.exists(paste0("data/tls/dsm/", plot, ".tif"))) {
    cat("File", paste0("data/tls/dsm/", plot, ".tif"), "already exists!")
    next
  } else {
    # Coordinates of current plot
    crds <- plt.db.wgs84[i, ]
    # Relative tile coordinates
    cntr <- getTileCenters(plt.rds = 2000, plt.res = 500)
    
#     # Download and merge OSM data
#     osm <- getOsmTiles(tile.cntr = cntr, 
#                        location = crds, 
#                        plot.res = 500, 
#                        plot.bff = 50,
#                        tmp.folder = "C:/Users/fdetsch/AppData/Local/Temp/R_raster_tmp", 
#                        path.out = "data/tls/osm", 
#                        plot = plot,
#                        type = "bing", mergeTiles = TRUE)
#     
#     osm.mrg <- osmRsmplMrg(path = paste0("data/tls/osm/", plot), 
#                            pattern = "kili_tile_.*.tif$", 
#                            rsmpl.exe = TRUE, 
#                            path.rsmpl = paste0("data/tls/osm/", plot),
#                            pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
#                            n.cores = 4, 
#                            file.rsmpl.mrg = paste0("data/tls/osm/", plot, ".tif"), 
#                            overwrite = TRUE)
    
      # Download and merge Google data
      dsm <- getGoogleTiles(tile.cntr = cntr, 
                            location = crds, 
                            type = "satellite", rgb = TRUE,
                            plot.res = 500, 
                            plot.bff = 50, 
                            plot = plot,
                            path.out = "data/tls/dsm")
      
      dsm.mrg <- dsmRsmplMrg(path = paste0("data/tls/dsm/", plot), 
                             pattern = "kili_tile_.*.tif$", 
                             rsmpl.exe = TRUE, 
                             path.rsmpl = paste0("data/tls/dsm/", plot),
                             pattern.rsmpl = "kili_tile_.*rsmpl.tif$",
                             n.cores = 4, 
                             file.rsmpl.mrg = paste0("data/tls/dsm/", plot, ".tif"), 
                             overwrite = TRUE, 
                             crop.google = TRUE, 
                             crop.radius = 150)
  }
}
