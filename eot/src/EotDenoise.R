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
  
  # Extract proj4string and extent of raster data
  tmp.prj <- projection(data)
  tmp.ext <- extent(data)
  # Unstack current RasterStack
  tmp.rst <- unstack(data)
  # Convert rasters to matrices
  tmp.mat <- lapply(tmp.rst, function(h) {
    as.matrix(h)
  })
  
  # Loop through single matrices
  clusterExport(clstr, c("tmp.mat", "tmp.prj", "tmp.ext"), envir = environment())
  
  tmp.rst.dns <- parLapply(clstr, tmp.mat, function(j) {
    
    # Perform PCA and extract eigenvalues 
    lambda <- EotRunPca(j)$values
    
    # Singular value decomposition
    s <- svd(j)
    
    # Execute image reconstruction based on k PCs
    z <- EotRecImage(s, k)
    
    # Convert reconstructed matrix to raster
    raster(z, crs = tmp.prj, 
           xmn = xmin(tmp.ext), xmx = xmax(tmp.ext), ymn = ymin(tmp.ext), ymx = ymax(tmp.ext))
    
  })
  
  # Stack and return reconstructed rasters
  data.dns <- do.call("stack", tmp.rst.dns)
    
  # Deregister parallel backend
  stopCluster(clstr)
  
  # Return output
  return(data.dns)
  
}