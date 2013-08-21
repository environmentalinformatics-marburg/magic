kifiAbsChange <- function(fire.scenes, 
                          fire.ts.fls, 
                          timespan,
                          fire.rst,
                          fire.mat, 
                          ndvi.mat, 
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
    tmp.date <- fire.ts.fls[c(((i-timespan):(i-1)), ((i+1):(i+timespan))), 1]
    
    tmp.fire <- sapply(list((i-timespan):(i-1), (i+1):(i+timespan)), function(j) {
      fire.mat[j]
    })
    
    tmp.ndvi <- sapply(list((i-timespan):(i-1), (i+1):(i+timespan)), function(j) {
      ndvi.mat[j]
    })
    
    # Skip current loop if NDVI is completely missing for at least one of the 
    # three defined time steps
    if(any(sapply(tmp.ndvi, function(j) all(is.logical(j))))) return(NULL)
    
    # Fire cells in current scene
    tmp.fire.cells <- which(t(fire.mat[[i]])[] > 0)
    
    # Loop through single fire cells of current scene
    tmp.out <- foreach(j = tmp.fire.cells, .combine = "rbind") %do% {
          
      # Extract NDVI cells within fire cell
      tmp <- fire.rst[[i]]
      tmp[][-j] <- NA
      tmp.shp <- rasterToPolygons(tmp)
      ndvi.cells <- cellsFromExtent(ndvi.rst[[300]], extent(tmp.shp))
      
      
      ## Deviation from mean before and after fire
      
      # Return NULL in case of any missing values
      if (any(is.na(t(tmp.ndvi[[length(tmp.ndvi) - timespan]])[ndvi.cells]) |
                is.na(t(tmp.ndvi[[length(tmp.ndvi) - timespan + 1]])[ndvi.cells])))
        return(NULL)
      
      # Calculate mean and deviation from mean
      ndvi.mean <- mean(t(tmp.ndvi[[length(tmp.ndvi) - timespan]])[ndvi.cells], 
                        na.rm = T)
      
      ndvi.dev.pre <- t(tmp.ndvi[[length(tmp.ndvi) - timespan]])[ndvi.cells] - ndvi.mean
      ndvi.dev.post <- t(tmp.ndvi[[length(tmp.ndvi) - timespan + 1]])[ndvi.cells] - ndvi.mean
      
      # Cell with maximum change in deviation from mean
      ndvi.dev.diff <- ndvi.dev.post - ndvi.dev.pre
      ndvi.cell <- ndvi.cells[which(ndvi.dev.diff == min(ndvi.dev.diff))]
      
      # Output      
      if (length(ndvi.cell) == 1) {
        
        # Fire and NDVI value of current cell in given time span
        fire.vals <- sapply(tmp.fire, function(k) t(k)[j])
        fire.vals[(timespan+1):length(fire.vals)] <- 1
        
        ndvi.vals <- round(sapply(tmp.ndvi, function(k) t(k)[ndvi.cell]) / 10000, 
                           digits = 3)
        
        # Merge date, fire and NDVI information for current cell
        return(data.frame(date = tmp.date, 
                          cell_fire = rep(j, length(tmp.date)), 
                          fire = fire.vals,  
                          cell_ndvi = rep(ndvi.cell, length(tmp.date)), 
                          ndvi = ndvi.vals))
        
      } else {
        
        fire.vals <- sapply(tmp.fire, function(k) t(k)[j])
        fire.vals[(timespan+1):length(fire.vals)] <- 1
        
        ndvi.vals <- unlist(lapply(ndvi.cell, function(l) {
          round(sapply(tmp.ndvi, function(k) t(k)[l]) / 10000, digits = 3)
        }))
        
        # Repetition factor for date and fire data
        multiplier <- length(ndvi.vals) / length(tmp.date)
        tmp.date.rep <- rep(tmp.date, multiplier)
        fire.vals.rep <- rep(fire.vals, multiplier)
        
        # Merge date, fire and NDVI information for current cells
        return(data.frame(date = tmp.date.rep, 
                          cell_fire = rep(j, length(tmp.date.rep)), 
                          fire = fire.vals.rep,  
                          cell_ndvi = rep(ndvi.cell, each = length(tmp.date.rep) / length(ndvi.cell)), 
                          ndvi = ndvi.vals))
      }
    }
    
    return(tmp.out)
  }
  
  # Deregister parallel backend and return output
  stopCluster(cl)
  return(out)
}
  