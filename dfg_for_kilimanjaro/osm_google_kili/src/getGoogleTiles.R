#' Download Google Maps Tiles
#' 
#' @description 
#' Built upon \code{\link{gmap}}, this function lets you download Google Maps 
#' imagery for a given geographic extent. In contrast to conventional 
#' approaches, however, smaller subsets are created from the initial boundaries 
#' which are processed iteratively, thus granting a higher level of spatial 
#' detail in the resulting image mosaic.
#' 
#' @param tile.cntr \code{list} with \code{numeric} coordinates relative to the 
#' centroid coordinate under investigation.
#' @param location \code{data.frame} containing information about current point 
#' of interest (POI).
#' @param plot.res Desired resolution (ie size) of each tile as \code{numeric}.
#' @param plot.bff \code{numeric} buffer to expand the pre-defined spatial 
#' frame around each tile centure. Measure against non-overlapping tiles.
#' @param path.out Output folder as \code{character}.
#' @param plot Optional name of the POI as \code{character}.
#' @param ... Additional arguments passed to \code{\link{gmap}}.
#' 
#' @return 
#' A \code{list}.
#' 
#' @author Florian Detsch
#' 
#' @seealso \code{\link{gmap}}.
#' 
#' @export getGoogleTiles
#' @name getGoogleTiles
getGoogleTiles <- function(tile.cntr,
                           location,
                           plot.res,
                           plot.bff = 0,
                           path.out = ".",
                           plot = NULL,
                           prefix = "kili_tile_",
                           ...) {
  
  # Transform SpatialPointsDataFrame to data.frame (optional)
  prj <- proj4string(location)
  location <- data.frame(location)

  # Loop through single tile centers of current research plot
  dsm.rst.ls <- lapply(seq(tile.cntr), function(z) {
    
    # Current filename
    fl <- if (is.null(plot)) {
      paste0(path.out, "/", prefix, 
             formatC(z, width = 3, format = "d", flag = "0"), ".tif")
    } else {
      paste0(path.out, "/", plot, "/", prefix, 
             formatC(z, width = 3, format = "d", flag = "0"), ".tif")
    }    
    
    if (file.exists(fl)) {
      print(paste("File", fl, "already exists! Proceeding to the next tile ..."))
    } else {
      print(paste("Processing file ", fl, "..."))
      
      # Set center of current tile
      tmp.coords.mrc <- location
      tmp.coords.mrc$x <- tmp.coords.mrc$x + tile.cntr[[z]][, 1]
      tmp.coords.mrc$y <- tmp.coords.mrc$y + tile.cntr[[z]][, 2]
      coordinates(tmp.coords.mrc) <- c("x", "y")
      projection(tmp.coords.mrc) <- CRS(prj)
      
      # Set extent of current tile
      tmp.coords.mrc$left <- coordinates(tmp.coords.mrc)[,1] - plot.res - plot.bff
      tmp.coords.mrc$top <- coordinates(tmp.coords.mrc)[,2] + plot.res + plot.bff
      tmp.coords.mrc$right <- coordinates(tmp.coords.mrc)[,1] + plot.res + plot.bff
      tmp.coords.mrc$bottom <- coordinates(tmp.coords.mrc)[,2] - plot.res - plot.bff
      
      # Boundary coordinates in Mercator and Longlat
      tmp.bndry.tl.mrc <- data.frame(tmp.coords.mrc)[,c("Location", "left", "top")]
      coordinates(tmp.bndry.tl.mrc) <- c("left", "top")
      proj4string(tmp.bndry.tl.mrc) <- proj4string(tmp.coords.mrc)
      
      tmp.bndry.br.mrc <- data.frame(tmp.coords.mrc)[,c("Location", "right", "bottom")]
      coordinates(tmp.bndry.br.mrc) <- c("right", "bottom")
      proj4string(tmp.bndry.br.mrc) <- proj4string(tmp.coords.mrc)
      
      tmp.bndry.tl <- spTransform(tmp.bndry.tl.mrc, CRS("+init=epsg:4326"))
      tmp.bndry.br <- spTransform(tmp.bndry.br.mrc, CRS("+init=epsg:4326"))
      
      tmp.bndry.xt <- extent(coordinates(tmp.bndry.tl)[,1], coordinates(tmp.bndry.br)[,1],
                             coordinates(tmp.bndry.br)[,2], coordinates(tmp.bndry.tl)[,2])
      
      # Download non-existent files only
      if (is.null(plot)) {
        tmp.fls <- paste0(path.out, "/", prefix,
                          formatC(z, width = 3, format = "d", flag = "0"), ".tif")
      } else {
        tmp.fls <- paste0(path.out, "/", plot, "/", prefix,
                          formatC(z, width = 3, format = "d", flag = "0"), ".tif")
      }
      
      if (!file.exists(tmp.fls)) {
        # Download Google Map of the given extent and save copy to HDD
        tmp.rst <- dismo::gmap(tmp.bndry.xt, ...)
        
        tmp.lst <- lapply(1:nlayers(tmp.rst), function(a) {
          val <- as.matrix(tmp.rst[[a]])
          val[(nrow(val)-42):nrow(val), ] <- NA
          setValues(tmp.rst[[a]], val)
        })
        
        tmp.rst <- trim(stack(tmp.lst))
        
        # Save Google Map as GeoTiff to HDD
        if (is.null(plot)) {
          writeRaster(tmp.rst, filename = tmp.fls, format = "GTiff", 
                      overwrite = TRUE)
        } else {
          suppressWarnings(dir.create(paste(path.out, plot, sep = "/")))
          writeRaster(tmp.rst, tmp.fls)
        }
        
        # Return DSM information
        return(data.frame(tile = formatC(z, width = 3, format = "d", flag = "0"), 
                          file = tmp.fls, stringsAsFactors = FALSE))
      }
    }
  })
  
  # Return list of output rasters
  return(dsm.rst.ls)
}