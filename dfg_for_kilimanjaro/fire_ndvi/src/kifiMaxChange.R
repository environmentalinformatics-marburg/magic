kifiMaxChange <- function(fire.scenes, 
                          fire.ts.fls, 
                          timespan, 
                          fire.rst, 
                          ndvi.rst, 
                          n.cores = 2, 
                          ...) {
  
  # Required packages
  lib <- c("raster", "rgdal", "foreach")
  sapply(lib, function(x) stopifnot(require(x, character.only = T)))
  
  # Parallelization
  registerDoParallel(cl <- makeCluster(n.cores))

  # Loop through scenes with at least one fire pixel
  out <- foreach(i = which(fire.scenes), .combine = "rbind", 
                 .packages = lib) %dopar% {

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
#     if(any(sapply(tmp.ndvi, function(j) all(is.na(j))))) return(NULL)
    if(any(sapply(tmp.ndvi, function(j) all(is.na(j))))) NULL
    
    # Fire cells in current scene
    tmp.fire.cells <- which(fire.rst[[i]][] > 0)
    
    # Loop through single fire cells of current scene
    tmp.out <- foreach(j = tmp.fire.cells, .combine = "rbind") %do% {
          
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
        
        if (any(is.na(ndvi.diff1)) | any(is.na(ndvi.diff2))) return(NULL)
      }
      
      # Maximum difference between ultimate and subsequent NDVI -> fire cell
      ndvi.cell <- ndvi.cells[which(ndvi.diff2 == min(ndvi.diff2, na.rm = T))]
      
      if (length(ndvi.cell) == 1) {
        
        # Extract fire and NDVI of the current cell for the given time span
        fire.vals <- sapply(unlist(tmp.fire), function(k) k[j])
        fire.vals[(timespan+timespan+1):length(fire.vals)] <- 1
        ndvi.vals <- round(sapply(tmp.ndvi, function(k) k[ndvi.cell]) / 10000, 
                           digits = 3)
        
        # Merge date, fire and NDVI information for the current fire cell
        return(data.frame(date = tmp.date, 
                          cell_fire = rep(j, length(tmp.date)), 
                          fire = fire.vals,  
                          cell_ndvi = rep(ndvi.cell, length(tmp.date)), 
                          ndvi = ndvi.vals, 
                          ndvi_diff = c(0, ndvi.diff1[which(ndvi.diff2 == min(ndvi.diff2))], 
                                        ndvi.diff2[which(ndvi.diff2 == min(ndvi.diff2))])))
        
      } else {
        
        fire.vals <- sapply(unlist(tmp.fire), function(k) k[j])
        fire.vals[(timespan+timespan+1):length(fire.vals)] <- 1
        ndvi.vals <- unlist(lapply(ndvi.cell, function(l) {
          round(sapply(tmp.ndvi, function(k) k[l]) / 10000, digits = 3)
        }))
        
        ndvi.diff <- foreach(k = seq(ndvi.cell), .combine = "c") %do% {
          c(0, ndvi.diff1[which(ndvi.diff2 == min(ndvi.diff2))][k], 
            ndvi.diff2[which(ndvi.diff2 == min(ndvi.diff2))][k])
        }
        
        multiplier <- length(ndvi.vals) / length(tmp.date)
        tmp.date.rep <- rep(tmp.date, multiplier)
        fire.vals.rep <- rep(fire.vals, multiplier)
        return(data.frame(date = tmp.date.rep, 
                          cell_fire = rep(j, length(tmp.date)), 
                          fire = fire.vals,  
                          cell_ndvi = rep(ndvi.cell, each = length(tmp.date) / length(ndvi.cell)), 
                          ndvi = ndvi.vals, 
                          ndvi_diff = ndvi.diff))
      }
    }
    
    return(tmp.out)
  }
  
  # Deregister parallel backend and return output
  stopCluster(cl)
  return(out)
}
  