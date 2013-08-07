getOsmTiles <- function(tile.cntr, 
                        location,
                        plot.res,
                        tmp.folder = NULL,
                        path.out = ".", 
                        ...) {
  
  #########################################################################################
  # Parameters are as follows:
  #
  # tile.cntr (numeric list):     Output list from function getTileCenters().  
  #                               Contains numeric coordinates (lon, lat) relative 
  #                               to the location of the current research plot.
  # location (data.frame): Data frame containing information about current plot. 
  # plot.res (numeric):           Tile size.
  # tmp.folder (character):       Folder containing temporary raster files.
  # path.out (character):         Output folder. 
  # ...:                          Further arguments passed on to openmap().
  #
  #########################################################################################
  
  # Check if folder containing temporary files is specified
  if (is.null(tmp.folder))
    stop("Folder containing temporary raster files is not specified!
        (e.g. ~/AppData/Local/Temp/R_raster_tmp)")
  
  # Required packages
  lib <- c("raster", "OpenStreetMap")
  sapply(lib, function(...) stopifnot(require(..., character.only = T)))
  
  # Transform SpatialPointsDataFrame to data.frame (optional)
  if (class(location) != "data.frame")
    location <- data.frame(location)
  
  # Loop through single tile centers of current research plot
  osm.rst.ls <- lapply(seq(tile.cntr), function(z) {
    
    # Set center of current tile
    tmp.coords.mrc <- location
    tmp.coords.mrc$Lon <- tmp.coords.mrc$Lon + tile.cntr[[z]][, 1]
    tmp.coords.mrc$Lat <- tmp.coords.mrc$Lat + tile.cntr[[z]][, 2]
    coordinates(tmp.coords.mrc) <- c("Lon", "Lat")
    projection(tmp.coords.mrc) <- CRS("+init=epsg:32737")
    
    # Set extent of current tile
    tmp.coords.mrc$left <- coordinates(tmp.coords.mrc)[, 1] - plot.res
    tmp.coords.mrc$top <- coordinates(tmp.coords.mrc)[, 2] + plot.res
    tmp.coords.mrc$right <- coordinates(tmp.coords.mrc)[, 1] + plot.res
    tmp.coords.mrc$bottom <- coordinates(tmp.coords.mrc)[, 2] - plot.res
    
    # Boundary coordinates in Mercator
    tmp.bndry.tl.mrc <- data.frame(tmp.coords.mrc)[, c("PlotID", "left", "top")]
    coordinates(tmp.bndry.tl.mrc) <- c("left", "top")
    proj4string(tmp.bndry.tl.mrc) <- proj4string(tmp.coords.mrc)
    
    tmp.bndry.br.mrc <- data.frame(tmp.coords.mrc)[, c("PlotID", "right", "bottom")]
    coordinates(tmp.bndry.br.mrc) <- c("right", "bottom")
    proj4string(tmp.bndry.br.mrc) <- proj4string(tmp.coords.mrc)
    
    # Reproject boundrary coordinates to LatLon
    tmp.bndry.tl <- spTransform(tmp.bndry.tl.mrc, CRS("+init=epsg:4326"))
    tmp.bndry.br <- spTransform(tmp.bndry.br.mrc, CRS("+init=epsg:4326"))
    
    # Get BING image of the given extent
    tmp.osm <- openmap(upperLeft = c(as.numeric(coordinates(tmp.bndry.tl)[, 2]), as.numeric(coordinates(tmp.bndry.tl)[, 1])), 
                       lowerRight = c(as.numeric(coordinates(tmp.bndry.br)[, 2]), as.numeric(coordinates(tmp.bndry.br)[, 1])), 
                       ...)
    
    # Rasterize BING image
    tmp.osm.rst <- raster(tmp.osm)
    writeRaster(tmp.osm.rst, paste(path.out, "/kili_tile_", formatC(z, width = 3, format = "d", flag = "0"), sep = ""), 
                format = "GTiff", overwrite = T)
    
    # Remove temporary files from local drive
    tmp.fls <- list.files(tmp.folder, full.names = T, recursive = T)
    file.remove(tmp.fls)
    
    # Return OSM information
    return(data.frame(tile = formatC(z, width = 3, format = "d", flag = "0"), 
                      file = paste(path.out, "/kili_tile_", formatC(z, width = 3, format = "d", flag = "0"), ".tif", sep = "")))
  })
  
  # Return output
  return(osm.rst.ls)
}