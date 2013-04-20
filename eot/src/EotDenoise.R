EotDenoise <- function(data,
                       k,
                       ...) {
  
  
  ### Environmental settings
  
  # Required packages
  stopifnot(require(parallel))
  stopifnot(require(raster))
  
  # Parallelization
  n.cores <- detectCores()
  clstr <- makePSOCKcluster(n.cores)
  
  # Load required packages and functions on cluster
  clusterEvalQ(clstr, c(library(raster), 
                        source("src/EotRunPca.R"), source("src/EotRecImage.R")))
  
  
  ### Image reconstruction
  
  # Loop through single RasterStacks
  clusterExport(clstr, c("data", "k"), envir = environment())
  
  data.dns <- parLapply(clstr, data, function(i) {
    
    # Unstack current RasterStack
    tmp.rst <- unstack(i)
    # Convert rasters to matrices
    tmp.mat <- lapply(tmp.rst, function(h) {
      as.matrix(h)
    })
    
    # Loop through single rasters of current RasterStack
    tmp.rst.dns <- lapply(tmp.mat, function(j) {
      
      # Perform PCA and extract eigenvalues 
      lambda <- EotRunPca(j)$values
      
      # Singular value decomposition
      s <- svd(j)
      
      # Execute image reconstruction based on k PCs
      z <- EotRecImage(s, k)
      
      # Convert reconstructed matrix to raster
      raster(z)
              
    })
    
    # Stack and return reconstructed rasters
    do.call("stack", tmp.rst.dns)
    
  })
  
  # Deregister parallel backend
  stopCluster(clstr)
  
  # Return output
  return(data.dns)
  
}