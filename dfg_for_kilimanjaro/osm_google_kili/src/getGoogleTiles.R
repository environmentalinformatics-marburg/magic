getGoogleTiles <- function(tile.cntr,
                           location,
                           plot.res,
                           plot.bff,
                           path.out = ".",
                           plot = NULL,
                           ...) {
  
  #########################################################################################
  # Parameters are as follows:
  #
  # tile.cntr (numeric list):     List containing numeric coordinates (lon, lat) relative 
  #                               to the location of the research plot under investigation.
  # location (data.frame): Data frame containing information about current plot.    
  # plot.res (numeric):           Desired resolution (size) of each tile.
  # plot.bff (numeric):           Buffer to expand extent around tile centers, 
  #                               measure against non-overlapping tiles.
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
    
    # Current filename
    if (is.null(plot)) {
      fl <- paste0(path.out, "/kili_tile_", 
                   formatC(z, width = 3, format = "d", flag = "0"), ".tif")
    } else {
      fl <- paste0(path.out, "/", plot, "/kili_tile_", 
                   formatC(z, width = 3, format = "d", flag = "0"), ".tif")
    }    
    
    if (file.exists(fl)) {
      print(paste("File", fl, "already exists! Proceeding to the next tile ..."))
    } else {
      print(paste("Processing file ", fl, "..."))
      
      # Set center of current tile
      tmp.coords.mrc <- location
      tmp.coords.mrc$Lon <- tmp.coords.mrc$Lon + tile.cntr[[z]][, 1]
      tmp.coords.mrc$Lat <- tmp.coords.mrc$Lat + tile.cntr[[z]][, 2]
      coordinates(tmp.coords.mrc) <- c("Lon", "Lat")
      projection(tmp.coords.mrc) <- CRS("+init=epsg:32737")
      
      # Set extent of current tile
      tmp.coords.mrc$left <- coordinates(tmp.coords.mrc)[,1] - plot.res - plot.bff
      tmp.coords.mrc$top <- coordinates(tmp.coords.mrc)[,2] + plot.res + plot.bff
      tmp.coords.mrc$right <- coordinates(tmp.coords.mrc)[,1] + plot.res + plot.bff
      tmp.coords.mrc$bottom <- coordinates(tmp.coords.mrc)[,2] - plot.res - plot.bff
      
      # Boundary coordinates in Mercator and Longlat
      tmp.bndry.tl.mrc <- data.frame(tmp.coords.mrc)[,c("PlotID", "left", "top")]
      coordinates(tmp.bndry.tl.mrc) <- c("left", "top")
      proj4string(tmp.bndry.tl.mrc) <- proj4string(tmp.coords.mrc)
      
      tmp.bndry.br.mrc <- data.frame(tmp.coords.mrc)[,c("PlotID", "right", "bottom")]
      coordinates(tmp.bndry.br.mrc) <- c("right", "bottom")
      proj4string(tmp.bndry.br.mrc) <- proj4string(tmp.coords.mrc)
      
      tmp.bndry.tl <- spTransform(tmp.bndry.tl.mrc, CRS("+init=epsg:4326"))
      tmp.bndry.br <- spTransform(tmp.bndry.br.mrc, CRS("+init=epsg:4326"))
      
      tmp.bndry.xt <- extent(coordinates(tmp.bndry.tl)[,1], coordinates(tmp.bndry.br)[,1],
                             coordinates(tmp.bndry.br)[,2], coordinates(tmp.bndry.tl)[,2])
      
      # Download non-existent files only
      if (is.null(plot)) {
        tmp.fls <- paste0(path.out, "/kili_dsm_tile_", 
                          formatC(z, width = 3, format = "d", flag = "0"), ".tif")
      } else {
        tmp.fls <- paste0(path.out, "/", plot, "/kili_dsm_tile_", 
                          formatC(z, width = 3, format = "d", flag = "0"), ".tif")
      }
      
      if (!file.exists(tmp.fls)) {
        # Download Google Map of the given extent and save copy to HDD
        tmp.rst <- gmap(tmp.bndry.xt, ...)
        
        # Save Google Map as GeoTiff to HDD
        if (is.null(plot)) {
          writeRaster(tmp.rst, filename = tmp.fls, format = "GTiff", 
                      overwrite = TRUE)
        } else {
          dir.create(paste(path.out, plot, sep = "/"))
          writeRaster(tmp.rst, paste0(path.out, "/", plot, "/kili_tile_", 
                                      formatC(z, width = 3, format = "d", flag = "0")), 
                      format = "GTiff", overwrite = TRUE)
        }
        
        # Return DSM information
        return(data.frame(tile = formatC(z, width = 3, format = "d", flag = "0"), 
                          file = tmp.fls))
      }
    }
  })
  
  # Return list of output rasters
  return(dsm.rst.ls)
}