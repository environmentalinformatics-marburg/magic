ndviCell <- function(fire.scenes, 
                     fire.dates, 
                     fire.rst,
                     ndvi.rst,
                     fire.mat, 
                     ndvi.mat, 
                     id = 300,
                     n.cores = 2, 
                     ...) {
  
  # Required packages
  lib <- c("raster", "rgdal", "doParallel")
  sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))
  
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
      ndvi.cells <- cellsFromExtent(ndvi.rst[[id]], extent(tmp.shp))
      
      
      ## Identify preceding/succeeding valid layer in case of missing NDVI
      
      # One time step before fire
      gap.before <- 0
      na_in_ndvi <- any(is.na(t(ndvi.mat[[i-1]])[ndvi.cells]))
      
      while (na_in_ndvi) {
        gap.before <- gap.before + 1
        
        na_in_ndvi <- any(is.na(t(ndvi.mat[[i-1-gap.before]])[ndvi.cells]))
      }
      
      # Two time steps before fire
      gap.2_before <- 0
      na_in_ndvi <- any(is.na(t(ndvi.mat[[i-(gap.before+1)-2]])[ndvi.cells]))
      
      while (na_in_ndvi) {
        gap.2_before <- gap.2_before + 2
        
        na_in_ndvi <- any(is.na(t(ndvi.mat[[i-(gap.before+1)-2-gap.2_before]])[ndvi.cells]))
      }
      
      # One time step after fire
      gap.after <- 0
      na_in_ndvi <- any(is.na(t(ndvi.mat[[i+1]])[ndvi.cells]))
      
      while (na_in_ndvi) {
        gap.after <- gap.after + ifelse(gap.before %% 2 == 0, 2, 1)
        
        na_in_ndvi <- any(is.na(t(ndvi.mat[[i+1+gap.after]])[ndvi.cells]))
      }
      
      # Skip current iteration in case of preceding/succeeding fire distortion 
      # or missing fire data
      fire.before <- sapply(fire.mat[(i-(gap.before+1)-2-gap.2_before):(i-1)], function(k) t(k)[j])
      fire.after <- sapply(fire.mat[(i+1):(i+gap.after+1)], function(k) t(k)[j])
      
      if (any(c(fire.before > 0, is.na(fire.before),
                fire.after > 0, is.na(fire.after)), na.rm = TRUE)) return(NULL)
      
      # Subset valid NDVI layers and extract date of fire event
      tmp.ndvi <- ndvi.mat[c(i-(gap.before+1)-2-gap.2_before, i-1-gap.before, i+1+gap.after)]
      
      
      ## Relation between change difference from NDVI before to after the fire
      
      # Change from penultimate to ultimate NDVI
      ndvi.diff1 <- t(tmp.ndvi[[2]] - tmp.ndvi[[1]])[ndvi.cells]
      # Change from ultimate to subsequent NDVI
      ndvi.diff2 <- t(tmp.ndvi[[3]] - tmp.ndvi[[2]])[ndvi.cells]
            
      # Relative maximum difference between ultimate and subsequent NDVI
      ndvi.rel_diff <- ndvi.diff2 - ndvi.diff1
      ndvi.cell <- ndvi.cells[which(ndvi.rel_diff == min(ndvi.rel_diff))]
      
      
      ## Deviation from mean before and after fire
      
      # Calculate mean and deviation from mean
      ndvi.val1 <- t(tmp.ndvi[[2]])[ndvi.cell]
      ndvi.val2 <- t(tmp.ndvi[[3]])[ndvi.cell]
      
      ndvi.mean <- mean(t(tmp.ndvi[[2]])[ndvi.cells])
      
      ndvi.dev1 <- ndvi.val1 - ndvi.mean
      ndvi.dev2 <- ndvi.val2 - ndvi.mean
      
      
      ## Output
      
      # NDVI values
      ndvi.vals <- foreach(k = ndvi.cell, .combine = "c") %do% {
        round(sapply(tmp.ndvi[2:3], function(l) t(l)[k]) / 10000, digits = 3)
      }
      
      # NDVI temporal change
      ndvi.diff <- foreach(k = ndvi.cell, .combine = "c") %do% {
        round(c(ndvi.diff1[which(ndvi.cells == k)], 
                ndvi.diff2[which(ndvi.cells == k)]) / 10000, digits = 3)
      }
      
      # NDVI deviation from mean
      ndvi.meandev <- foreach(k = 1:length(ndvi.cell), .combine = "c") %do% {
        round(c(ndvi.dev1[k], ndvi.dev2[k]) / 10000, digits = 3)
      }
      
      # Return output
      return(data.frame(date = fire.dates[i], 
                        scene_fire = i, 
                        cell_fire = j, 
                        fire = rep(c(0, 1), length(ndvi.cell)),
                        cell_ndvi = rep(ndvi.cell, each = length(ndvi.cell)), 
                        ndvi = ndvi.vals, 
                        ndvi_diff = ndvi.diff, 
                        ndvi_meandev = ndvi.meandev))
    }
    
    return(tmp.out)
  }
  
  # Deregister parallel backend and return output
  stopCluster(cl)
  return(out)
}
  