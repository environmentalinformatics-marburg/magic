kifiAbsChange <- function(fire.scenes, 
                          fire.ts.fls, 
                          timespan,
                          fire.rst,
                          ndvi.rst,
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
    
    # Fire cells in current scene
    fire.cells <- which(t(fire.mat[[i]]) > 0)
    
    # Loop through single fire cells of current scene
    tmp.out <- foreach(j = fire.cells, .combine = "rbind") %do% {

      # Extract NDVI cells within fire cell
      tmp <- fire.rst[[i]]
      tmp[][-j] <- NA
      tmp.shp <- rasterToPolygons(tmp)
      ndvi.cells <- cellsFromExtent(ndvi.rst[[300]], extent(tmp.shp))
      
      
      ## Identify last/next valid layer in case of missing NDVI
      
      # Before fire
      gap.before <- 0
      na_in_ndvi <- any(is.na(t(ndvi.mat[[i-1]])[ndvi.cells]))
      
      while (na_in_ndvi) {
        gap.before <- gap.before + 1
        
        na_in_ndvi <- any(is.na(t(ndvi.mat[[i-1-gap.before]])[ndvi.cells]))
      }
      
      # After fire
      gap.after <- 0
      na_in_ndvi <- any(is.na(t(ndvi.mat[[i+1]])[ndvi.cells]))
      
      while (na_in_ndvi) {
        gap.after <- gap.after + 1
        
        na_in_ndvi <- any(is.na(t(ndvi.mat[[i+1+gap.after]])[ndvi.cells]))
      }
      
      # Skip current iteration in case of fire distortion / missing fire data
      fire.before <- sapply(fire.mat[(i-gap.before-1):(i-1)], function(k) t(k)[j])
      fire.after <- sapply(fire.mat[(i+1):(i+gap.after+1)], function(k) t(k)[j])
      
      if (any(c(fire.before > 0, is.na(fire.before),
                fire.after > 0, is.na(fire.after)), na.rm = T)) return(NULL)
        
      
      # Merge valid fire/NDVI layers and extract corresponding dates
      tmp.fire <- fire.mat[c(i-1-gap.before, i+1+gap.after)]
      tmp.ndvi <- ndvi.mat[c(i-1-gap.before, i+1+gap.after)]
      
#       tmp.date <- fire.ts.fls[c(i-1-gap.before, i+1+gap.after), 1]
      tmp.date <- fire.ts.fls[i, 1]
      
      
      ## Deviation from mean before and after fire
      
      # Calculate mean and deviation from mean
      ndvi.val.before <- t(ndvi.mat[[i-1-gap.before]])[ndvi.cells]
      ndvi.val.after <- t(ndvi.mat[[i+1+gap.after]])[ndvi.cells]
      
      ndvi.mean <- mean(ndvi.val.before)
      
      ndvi.dev.pre <- ndvi.val.before - ndvi.mean
      ndvi.dev.post <- ndvi.val.after - ndvi.mean
      
      # Cell with maximum change in deviation from mean
      ndvi.dev.diff <- ndvi.dev.post - ndvi.dev.pre
      ndvi.cell <- ndvi.cells[which(ndvi.dev.diff == min(ndvi.dev.diff))]
      
      
      ## Output      
      
      # One identified NDVI cell
      if (length(ndvi.cell) == 1) {
        
        # Fire and NDVI value of current cell in given time span
        fire.vals <- sapply(tmp.fire, function(k) t(k)[j])
        fire.vals[(timespan+1):length(fire.vals)] <- 1
        
        ndvi.vals <- round(sapply(tmp.ndvi, function(k) t(k)[ndvi.cell]) / 10000, 
                           digits = 3)
        
        # Deviations from mean NDVI
        mean.dev <- round(c(ndvi.dev.pre[which(ndvi.cells == ndvi.cell)], 
                            ndvi.dev.post[which(ndvi.cells == ndvi.cell)]) / 10000, 
                          digits = 3)
        
        # Merge date, fire and NDVI information for current cell
        return(data.frame(date = tmp.date, 
#                           cell_fire = j, 
                          fire = fire.vals,  
#                           cell_ndvi = ndvi.cell, 
                          ndvi = ndvi.vals, 
                          mean_dev = mean.dev,
                          gap = c(gap.before, gap.after)))
      
      # More than one identified NDVI cells  
      } else {
        
        fire.vals <- sapply(tmp.fire, function(k) t(k)[j])
        fire.vals[(timespan+1):length(fire.vals)] <- 1
        
        ndvi.vals <- unlist(lapply(ndvi.cell, function(l) {
          round(sapply(tmp.ndvi, function(k) t(k)[l]) / 10000, digits = 3)
        }))
        
        # Deviations from mean NDVI
        mean.dev <- round(foreach(k = ndvi.cell, .combine = "c") %do% 
          c(ndvi.dev.pre[which(ndvi.cells == k)], 
                      ndvi.dev.post[which(ndvi.cells == k)]) / 10000, 3)
        
        # Repetition factor for date and fire data
        multiplier <- length(ndvi.cell)
        tmp.date.rep <- rep(tmp.date, multiplier)
        fire.vals.rep <- rep(fire.vals, multiplier)
        gap.rep <- rep(c(gap.before, gap.after), multiplier)
        
        # Merge date, fire and NDVI information for current cells
        return(data.frame(date = tmp.date.rep, 
#                           cell_fire = rep(j, length(tmp.date.rep)), 
                          fire = fire.vals.rep,  
#                           cell_ndvi = rep(ndvi.cell, each = length(tmp.date.rep) / length(ndvi.cell)), 
                          ndvi = ndvi.vals, 
                          mean_dev = mean.dev,
                          gap = gap.rep))
      }
    }
    
    return(tmp.out)
  }
  
  # Deregister parallel backend and return output
  stopCluster(cl)
  return(out)
}
  