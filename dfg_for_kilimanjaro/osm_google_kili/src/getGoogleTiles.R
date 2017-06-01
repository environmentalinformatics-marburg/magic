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
#' @param mosaic \code{logical}, defaults to \code{FALSE}. If \code{TRUE}, 
#' downloaded tiles are merged into a single large image. Else if a 
#' \code{character} file name is specified, tiles are not only merged, but the 
#' resulting image is also written to disk incrementally, thus reducing the 
#' amount of memory required. 
#' 
#' @param ... Additional arguments passed to \code{\link{gmap}}.
#' 
#' @return 
#' If 'mosaic' is \code{TRUE} or represents a valid file path, a mosaicked 
#' \code{RasterBrick} object, else a \code{list} of downloaded tile names.
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
                           prefix = "kili_tile_",
                           mosaic = FALSE) {
  
  # Transform SpatialPointsDataFrame to data.frame (optional)
  prj <- proj4string(location)
  location <- data.frame(location)

  # Loop through single tile centers of current research plot
  dsm.rst.ls <- do.call("rbind", lapply(seq(tile.cntr), function(z) {
    
    # Current filename
    fl <- paste0(path.out, "/", prefix, 
                 formatC(z, width = 3, format = "d", flag = "0"), ".tif")

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
      
      # Download Google Map of the given extent and save copy to HDD
      tmp.rst <- try(dismo::gmap(tmp.bndry.xt, ...), silent = TRUE)
      
      if (inherits(tmp.rst, "try-error")) {
        tmp.rst = NULL
      } else {
        
        tmp.lst <- lapply(1:nlayers(tmp.rst), function(a) {
          val <- as.matrix(tmp.rst[[a]])
          val[(nrow(val)-42):nrow(val), ] <- NA
          setValues(tmp.rst[[a]], val)
        })
        
        tmp.rst <- trim(stack(tmp.lst), filename = fl)
      }
    }
    
    # Return DSM information
    data.frame(tile = formatC(z, width = 3, format = "d", flag = "0"), 
               file = ifelse(file.exists(fl), fl, NULL), stringsAsFactors = FALSE)
  }))
  
  # Return list of output rasters
  if (isTRUE(mosaic) | is.character(mosaic)) {
    tmp1 = ifelse(is.character(mosaic), paste0(dirname(mosaic), "/tmp.tif"), "")

    for (i in 2:nrow(dsm)) {
      if (i %% 10 == 0) 
        cat("File #", i, " is in, start processing...\n", sep = "")
      
      if (i == 2) {
        msc <- merge(brick(dsm$fls[i-1]), brick(dsm$fls[i]), tolerance = 100, 
                     filename = mosaic)
      } else {
        tmp2 <- merge(msc, brick(dsm$fls[i]), tolerance = 100, 
                      filename = tmp1, overwrite = TRUE)
        jnk <- file.copy(attr(tmp2@file, "name"), mosaic, overwrite = TRUE)
        msc <- brick(mosaic)
      }
    }
    
    return(msc)
    
  } else return(dsm.rst.ls)
}