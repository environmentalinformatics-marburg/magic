uniqueFires <- function(rst, 
                        n_cores = 1, 
                        ...) {
  
  # packages
  lib <- c("doParallel", "raster", "rgdal")
  jnk <- sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))
  
  # parallelization
  registerDoParallel(cl <- makeCluster(n_cores))
  
  # identify fire pixels per scene
  fires <- foreach(i = 1:nlayers(rst), .packages = lib, 
                   .combine = "rbind") %dopar% {
    
    # all pixels
    val <- getValues(rst[[i]])
    
    # fire pixels
    val_fire <- which(val > 0)
    
    if (length(val_fire) > 0) {
      df_fire <- data.frame(id = i, cell = val_fire)
    } else {
      df_fire <- data.frame(id = integer(), cell = integer())
    }
    
    return(df_fire)
  }
  
  # identify and remove duplicates
  dpl_id <- which(duplicated(fires$cell))
  dpl_val <- fires$cell[dpl_id]
  dpl_val <- unique(dpl_val)
  
  rm_id <- foreach(i = dpl_val, .combine = "c") %do% grep(i, fires$cell)
  fires <- fires[-rm_id, ]
  
  # stop cluster
  closeAllConnections()

  # return unique fire cell ids
  return(fires)
}