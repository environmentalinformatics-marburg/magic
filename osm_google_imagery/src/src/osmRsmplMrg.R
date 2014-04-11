osmRsmplMrg <- function(path = ".", 
                        pattern = NULL,
                        rsmpl.exe = T,
                        path.rsmpl = ".", 
                        pattern.rsmpl = NULL,
                        file.rsmpl.mrg = ".",
                        n.cores = 2,
                        ...) {
  
  # Required packages
  lib <- c("doParallel", "raster", "rgdal")
  jnk <- sapply(lib, function(x) stopifnot(require(x, character.only = T)))
  
  # Parallelization
  registerDoParallel(cl <- makeCluster(n.cores))
  
  # Import raster data
  if (rsmpl.exe) {
    fls <- list.files(path = path, pattern = pattern, full.names = T)
    if (length(grep("rsmpl", fls)) > 0)
      fls <- fls[-grep("rsmpl", fls)]
    rst <- foreach(i = fls, .packages = lib) %dopar% stack(i)
    
    # Identify union extent of raster data             
    rst.ext <- Reduce("union", sapply(rst, extent))
    template <- raster(rst.ext, crs = projection(rst[[1]]))
    res(template) <- res(rst[[1]])
    
    # Resample raster data to template 
    rst.rsmpl <- foreach(i = rst, j = basename(fls), .packages = lib) %dopar% {
      crp <- crop(template, i)
      resample(i, crp, method = "ngb", 
               filename = paste0(path.rsmpl, "/", substr(j, 1, nchar(j) - 4), "_rsmpl"), 
               format = "GTiff", overwrite = T)
    }
  }
  
  # Import resampled raster data
  if (!exists("rst.rsmpl")) {
    fls.rsmpl <- list.files(path = path.rsmpl, pattern = pattern.rsmpl, 
                            full.names = T)
    rst.rsmpl <- foreach(i = fls.rsmpl, .packages = lib) %dopar% stack(i)
  }

  # Merge resampled raster data
  rst.rsmpl.mrg <- do.call(function(...) {
    merge(..., tolerance = 1, filename = file.rsmpl.mrg, overwrite = TRUE)
  }, rst.rsmpl)
  
  # Deregister parallel backend and return resampled and merged raster data
  stopCluster(cl)
  return(rst.rsmpl.mrg)
}