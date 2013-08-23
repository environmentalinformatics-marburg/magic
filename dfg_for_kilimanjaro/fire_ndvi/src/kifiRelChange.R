kifiRelChange <- function(fire.scenes, 
                          fire.ts.fls, 
                          timespan, 
                          fire.rst,
                          ndvi.rst,
                          fire.mat, 
                          ndvi.mat, 
                          n.cores = 2, 
                          ...) {
  
  # Required packages
  lib <- c("raster", "rgdal", "doParallel")
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
      
      # Two time steps before fire
      gap.2_before <- 0
      na_in_ndvi <- any(is.na(t(ndvi.mat[[i-(gap.before+1)-1]])[ndvi.cells]))
      
      while (na_in_ndvi) {
        gap.2_before <- gap.2_before + 1
        
        na_in_ndvi <- any(is.na(t(ndvi.mat[[i-(gap.before+1)-1-gap.2_before]])[ndvi.cells]))
      }
      
      # After fire
      gap.after <- 0
      na_in_ndvi <- any(is.na(t(ndvi.mat[[i+1]])[ndvi.cells]))
      
      while (na_in_ndvi) {
        gap.after <- gap.after + 1
        
        na_in_ndvi <- any(is.na(t(ndvi.mat[[i+1+gap.after]])[ndvi.cells]))
      }
      
      # Skip current iteration in case of fire distortion / missing fire data
      fire.before <- sapply(fire.mat[(i-(gap.before+1)-1-gap.2_before):(i-1)], function(k) t(k)[j])
      fire.after <- sapply(fire.mat[(i+1):(i+gap.after+1)], function(k) t(k)[j])
      
      if (any(c(fire.before > 0, is.na(fire.before),
                fire.after > 0, is.na(fire.after)), na.rm = T)) return(NULL)
      
      # Merge valid fire/NDVI layers and extract corresponding dates
      tmp.fire <- fire.mat[c(i-(gap.before+1)-1-gap.2_before, i-1-gap.before, i+1+gap.after)]
      tmp.ndvi <- ndvi.mat[c(i-(gap.before+1)-1-gap.2_before, i-1-gap.before, i+1+gap.after)]
      
      tmp.date <- fire.ts.fls[i, 1]
      
      
      ## Relation between change difference from NDVI before to after the fire
      
      # Change from penultimate to ultimate NDVI
      ndvi.diff1 <- t(tmp.ndvi[[2]] - tmp.ndvi[[1]])[ndvi.cells]
      # Change from ultimate to subsequent NDVI
      ndvi.diff2 <- t(tmp.ndvi[[3]] - tmp.ndvi[[2]])[ndvi.cells]
            
      # Relative maximum difference between ultimate and subsequent NDVI
      ndvi.rel_diff <- ndvi.diff2 - ndvi.diff1
      ndvi.cell <- ndvi.cells[which(ndvi.rel_diff == min(ndvi.rel_diff))]
      
      
      ## Output
      
      # One identified NDVI cell
      if (length(ndvi.cell) == 1) {
        
        # Fire and NDVI value of current cell in given time span
        fire.vals <- sapply(tmp.fire, function(k) t(k)[j])
        fire.vals[3] <- 1
        
        ndvi.vals <- round(sapply(tmp.ndvi, function(k) t(k)[ndvi.cell]) / 10000, 
                           digits = 3)
        
        # Absolute NDVI change difference
        abs_diff <- round(c(ndvi.diff1[which(ndvi.cells == ndvi.cell)], 
                      ndvi.diff2[which(ndvi.cells == ndvi.cell)]) / 10000, 3)
#         # Relative NDVI change difference
#         rel_diff <- round(c(0, 0, ndvi.rel_diff[which(ndvi.cells == ndvi.cell)]) / 10000, 3)
        
        # Merge date, fire and NDVI information for the current fire cell
        return(data.frame(date = tmp.date, 
#                           cell_fire = rep(j, length(tmp.date)), 
                          fire = fire.vals[2:3],  
#                           cell_ndvi = rep(ndvi.cell, length(tmp.date)), 
                          ndvi = ndvi.vals[2:3], 
                          abs_diff = abs_diff, 
#                           rel_diff = rel_diff, 
#                           gap = c(gap.2_before, gap.before, gap.after)))
                          gap = c(gap.before, gap.after)))
        
      # More than one identified NDVI cells  
      } else {
        
        # Fire and NDVI value of current cell in given time span
        fire.vals <- sapply(tmp.fire, function(k) t(k)[j])
        fire.vals[3] <- 1
        
        ndvi.vals <- round(foreach(k = ndvi.cell, .combine = "c") %do% { 
                             tmp <- sapply(tmp.ndvi, function(l) t(l)[k])
                             return(tmp[2:3])} / 10000, 
                           digits = 3)
        
        # Absolute NDVI change difference
        abs.diff <- round(foreach(k = ndvi.cell, .combine = "c") %do% 
          c(ndvi.diff1[which(ndvi.cells == k)], 
            ndvi.diff2[which(ndvi.cells == k)]) / 10000, 3)
#         # Relative NDVI change difference
#         rel.diff <- round(foreach(k = ndvi.cell, .combine = "c") %do%
#           c(0, 0, ndvi.rel_diff[which(ndvi.cells == k)]) / 10000, 3)
        
        multiplier <- length(ndvi.cell)
        tmp.date.rep <- rep(tmp.date, multiplier)
        fire.vals.rep <- rep(fire.vals[2:3], multiplier)
        
        return(data.frame(date = tmp.date.rep, 
#                           cell_fire = rep(j, length(tmp.date.rep)), 
                          fire = fire.vals.rep,  
#                           cell_ndvi = rep(ndvi.cell, each = length(tmp.date.rep) / length(ndvi.cell)), 
                          ndvi = ndvi.vals, 
                          abs_diff = abs.diff, 
#                           rel_diff = rel.diff, 
#                           gap = rep(c(gap.2_before, gap.before, gap.after), multiplier)))
                          gap = rep(c(gap.before, gap.after), multiplier)))
      }
    }
    
    return(tmp.out)
  }
  
  # Deregister parallel backend and return output
  stopCluster(cl)
  return(out)
}
  