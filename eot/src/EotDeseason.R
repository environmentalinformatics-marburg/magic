EotDeseason <- function(data, 
                        ...) {
  
  
  ### Environmental settings
  
  # Required packages
  stopifnot(require(raster, quietly = TRUE))
  stopifnot(require(parallel, quietly = TRUE))
  
  # Parallelization
  n.cores <- detectCores()
  clstr <- makePSOCKcluster(n.cores)
  
  clusterEvalQ(clstr, c(library(raster), library(rgdal)))
  
  
  ### Deseasoning
  
  # Calculate long-term averages per monthly
  if (is.list(data))
    data.mv <- do.call(function(...) {overlay(..., fun = "mean", na.rm = TRUE)}, data)
  else
    stop(paste("Argument 'data' must be a list of almost two elements.")) 
  
  # Subtract monthly averages from actually measured values
  clusterExport(clstr, c("data", "data.mv"), envir = environment())
  
  data.dsn <- parLapply(clstr, data, function(i) {
    overlay(i, data.mv, fun = function(x, y) {x - y})
  })
  
  # Deregister parallel backend
  stopCluster(clstr)
  
  # Return output
  return(data.dsn)
  
}


# ### Call
# 
# library(raster)
# data <- list(stack(list.files("D:/programming/r/r_eot/data", pattern = "sst.*1983.*.rst$", full.names = TRUE, recursive = TRUE)), 
#              stack(list.files("D:/programming/r/r_eot/data", pattern = "sst.*1984.*.rst$", full.names = TRUE, recursive = TRUE)))
# data.dsn <- EotDeseason(data)