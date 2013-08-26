probRst <- function(fire.scenes, 
                    fire.ts.fls, 
                    fire.rst, 
                    ndvi.rst, 
                    fire.mat, 
                    ndvi.mat, 
                    model, 
                    n.cores = 2, 
                    ...) {
  
  # Required packages
  lib <- c("raster", "rgdal", "foreach", "party")
  sapply(lib, function(x) stopifnot(require(x, character.only = T)))
  
  # Parallelization
  registerDoParallel(cl <- makeCluster(n.cores))
  
  # Loop through fire scenes
  out <- foreach(i = which(fire.scenes), .packages = lib) %dopar% {
                                    
    # Fire cells in current scene
    fire.cells <- which(t(fire.mat[[i]]) > 0)
    
    # Loop through single fire cells of current scene
    tmp.out <- foreach(j = fire.cells) %do% {
      
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
      
      
      ## Deviation from mean before and after fire
      
      # Calculate mean and deviation from mean
      ndvi.val1 <- t(tmp.ndvi[[2]])[ndvi.cells]
      ndvi.val2 <- t(tmp.ndvi[[3]])[ndvi.cells]
      
      ndvi.mean <- mean(t(tmp.ndvi[[2]])[ndvi.cells])
      
      ndvi.dev1 <- ndvi.val1 - ndvi.mean
      ndvi.dev2 <- ndvi.val2 - ndvi.mean
      
      
      ## Model input
      
      # NDVI values
      ndvi.vals <- round(ndvi.val2 / 10000, digits = 3)
      
      # NDVI temporal change
      ndvi.diff <- round(ndvi.diff2 / 10000, digits = 3)
      
      # NDVI deviation from mean
      ndvi.meandev <- round(ndvi.dev2 / 10000, digits = 3)
      
      # Merge data
      model.input <- data.frame(date = tmp.date, 
                                scene_fire = i, 
                                cell_fire = j, 
                                cell_ndvi = ndvi.cells, 
                                ndvi = ndvi.vals, 
                                ndvi_diff = ndvi.diff, 
                                ndvi_meandev = ndvi.meandev)
      
      # Predict fire probabilities
      model.output <- predict(model, newdata = model.input, type = "prob")
      
      tmp <- ndvi.rst[[300]]
      tmp[][-ndvi.cells] <- 0
      tmp[ndvi.cells] <- sapply(model.output, "[[", 2)
      
      # Return temporary output raster
      return(tmp)
    }
    
    # Reject NAs
    invalid.layers <- sapply(tmp.out, is.null)
    if (all(invalid.layers)) {
      return(NULL)
    } else {
      
      # Stack, overlay and return nonNA layers
      tmp.out <- stack(tmp.out[which(!invalid.layers)])
      return(overlay(tmp.out, fun = max))
    }
    
    # Return output raster  
    return(tmp.out)
  }
  
  # Stop cluster and return output
  stopCluster(cl)
  return(out)
}