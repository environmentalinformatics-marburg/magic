EotDeseason <- function(data, 
                        cycle.window = 12,
                        n.cores = NULL,
                        ...) {
  
  ### Environmental settings
  
  # Required packages
  lib <- c("raster", "parallel")
  sapply(lib, function(...) stopifnot(require(..., character.only = T)))
  
  # Parallelization
  if (is.null(n.cores)) 
    n.cores <- detectCores()
  
  clstr <- makePSOCKcluster(n.cores)
  clusterEvalQ(clstr, c(library(raster), library(rgdal)))
  
  
  ### Deseasoning
  
  # Calculate long-term monthly averages
  clusterExport(clstr, c("data", "cycle.window"), envir = environment())
  
  data.mv <- do.call("stack", rep(parLapply(clstr, 1:cycle.window, function(i) {
    calc(data[[seq(i, nlayers(data), cycle.window)]], fun = mean)
  }), nlayers(data) / cycle.window))
  
  # Subtract monthly averages from actually measured values
  data.dsn <- data - data.mv
    
  # Deregister parallel backend
  stopCluster(clstr)
  
  # Return output
  return(data.dsn)
}


# ### Call
# 
# library(raster)
# data <- stack(c(list.files("E:/programming/r/r_eot/data", pattern = "sst.*1983.*.rst$", full.names = TRUE, recursive = TRUE), 
#              list.files("E:/programming/r/r_eot/data", pattern = "sst.*1984.*.rst$", full.names = TRUE, recursive = TRUE)))
# data.dsn <- EotDeseason(data)