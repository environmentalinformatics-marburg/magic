kifiProbMat <- function(fire.scenes, 
                        fire.ts.fls, 
                        timespan, 
                        fire.rst, 
                        ndvi.rst, 
                        model, 
                        n.cores = 2, 
                        ...) {
  
  # Required packages
  lib <- c("raster", "rgdal", "foreach")
  sapply(lib, function(x) stopifnot(require(x, character.only = T)))
  
  # Parallelization
  registerDoParallel(cl <- makeCluster(n.cores))
  
  # Loop through fire scenes
  out <- foreach(i = which(fire.scenes), .packages = lib) %dopar% {
                                
    # Date, fire and NDVI rasters for the given time span around current scene
    tmp.date <- fire.ts.fls[c(((i-timespan-timespan):(i-1)), ((i+1):(i+timespan))), 1]
    
    tmp.fire <- lapply(list((i-timespan-timespan):(i-timespan-1), 
                            (i-timespan):(i-1), (i+1):(i+timespan)), function(j) {
                              fire.rst[j]
                            })
    
    tmp.ndvi <- lapply(list((i-timespan-timespan):(i-timespan-1), 
                            (i-timespan):(i-1), (i+1):(i+timespan)), function(j) {
                              ndvi.rst[j]
                            })
    
    # Skip current loop if NDVI is completely missing for at least one of the 
    # three defined time steps
    if(any(sapply(tmp.ndvi, function(j) all(is.na(j))))) return(NULL)
    
    # Fire cells in current scene
    tmp.fire.cells <- which(fire.rst[[i]][] > 0)
    
    # Loop through single fire cells of current scene
    fire.ndvi.pre.post <- lapply(tmp.fire.cells, function(j) {
      
      # Extract NDVI cells within fire cell
      tmp <- fire.rst[[i]]
      tmp[][-j] <- NA
      tmp.shp <- rasterToPolygons(tmp)
      ndvi.cells <- cellsFromExtent(ndvi.rst[[300]], extent(tmp.shp))
      
      # Identify NDVI cell with highest decrease (or lowest increase)
      if (timespan == 1) {
        
        tmp.ndvi <- unlist(tmp.ndvi)
        
        # Change from penultimate to ultimate NDVI
        ndvi.diff1 <- (tmp.ndvi[[2]] - tmp.ndvi[[1]])[ndvi.cells]
        # Change from ultimate to subsequent NDVI
        ndvi.diff2 <- (tmp.ndvi[[3]] - tmp.ndvi[[2]])[ndvi.cells]
        
        if (any(is.na(ndvi.diff1)) | any(is.na(ndvi.diff2))) return(NA)
      }
      
      x.new <- ndvi.diff2
      y.new <- predict(model, data.frame(independ = x.new), type = "response")
      
      tmp <- ndvi.rst[[i]]
      tmp[][-ndvi.cells] <- 0
      tmp[ndvi.cells] <- y.new
      
      return(tmp)
    })
    
    # Reject NAs
    invalid.layers <- sapply(fire.ndvi.pre.post, is.logical)
    if (all(invalid.layers)) {
      return(NULL)
    } else {
      
      # Stack, overlay and return nonNA layers
      fire.ndvi.pre.post <- stack(fire.ndvi.pre.post[which(!invalid.layers)])
      return(overlay(fire.ndvi.pre.post, fun = max))
    }
  }
  
  # Stop cluster and return output
  stopCluster(cl)
  return(out)
}