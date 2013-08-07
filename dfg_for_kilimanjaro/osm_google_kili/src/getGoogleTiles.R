getGoogleTiles <- function(tile.cntr,
                           location,
                           plot.res, 
                           path.out,
                           ...) {
  
  #########################################################################################
  # Parameters are as follows:
  #
  # tile.cntr (numeric list):     List containing numeric coordinates (lon, lat) relative 
  #                               to the location of the research plot under investigation.
  # location (data.frame): Data frame containing information about current plot.    
  # plot.res (numeric):           Desired resolution (size) of each tile.
  # path.out (character):         Character string specifying output folder.
  # ...:                          Further arguments to be passed on to gmap().
  #
  #########################################################################################
  
  # Required packages
  stopifnot(require(dismo))
  
  # Transform SpatialPointsDataFrame to data.frame (optional)
  if (class(location) != "data.frame")
    location <- data.frame(location)
  
  # Loop through single tile centers of current research plot
  dsm.rst.ls <- lapply(seq(tile.cntr), function(z) {

    # Set center of current tile
    tmp.coords.mrc <- location
    tmp.coords.mrc$Lon <- tmp.coords.mrc$Lon + tile.cntr[[z]][,1]
    tmp.coords.mrc$Lat <- tmp.coords.mrc$Lat + tile.cntr[[z]][,2]
    coordinates(tmp.coords.mrc) <- c("Lon", "Lat")
    projection(tmp.coords.mrc) <- CRS("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs")
    
    # Set extent of current tile
    tmp.coords.mrc$left <- coordinates(tmp.coords.mrc)[,1] - plot.res
    tmp.coords.mrc$top <- coordinates(tmp.coords.mrc)[,2] + plot.res
    tmp.coords.mrc$right <- coordinates(tmp.coords.mrc)[,1] + plot.res
    tmp.coords.mrc$bottom <- coordinates(tmp.coords.mrc)[,2] - plot.res
    
    # Boundary coordinates in Mercator and Longlat
    tmp.bndry.tl.mrc <- data.frame(tmp.coords.mrc)[,c("PlotID", "left", "top")]
    coordinates(tmp.bndry.tl.mrc) <- c("left", "top")
    proj4string(tmp.bndry.tl.mrc) <- proj4string(tmp.coords.mrc)
    
    tmp.bndry.br.mrc <- data.frame(tmp.coords.mrc)[,c("PlotID", "right", "bottom")]
    coordinates(tmp.bndry.br.mrc) <- c("right", "bottom")
    proj4string(tmp.bndry.br.mrc) <- proj4string(tmp.coords.mrc)
    
    tmp.bndry.tl <- spTransform(tmp.bndry.tl.mrc, CRS("+proj=longlat +datum=WGS84"))
    tmp.bndry.br <- spTransform(tmp.bndry.br.mrc, CRS("+proj=longlat +datum=WGS84"))
    
    tmp.bndry.xt <- extent(coordinates(tmp.bndry.tl)[,1], coordinates(tmp.bndry.br)[,1],
                           coordinates(tmp.bndry.br)[,2], coordinates(tmp.bndry.tl)[,2])
    
    # Download non-existent files only
    tmp.fls <- paste(path.out, "/kili_dsm_tile_", formatC(z, width = 3, format = "d", flag = "0"), ".tif", sep = "")
    if (!file.exists(tmp.fls)) {
      # Download Google Map of the given extent and save copy to HDD
      tmp.rst <- gmap(tmp.bndry.xt, ...)
      
      # Save Google Map as GeoTiff to HDD
      writeRaster(tmp.rst, filename = tmp.fls, format = "GTiff", overwrite = T)
      
      # Return DSM information
      return(data.frame(tile = formatC(z, width = 3, format = "d", flag = "0"), 
                        file = tmp.fls))
    }
  })
  
  # Return list of output rasters
  return(dsm.rst.ls)
}