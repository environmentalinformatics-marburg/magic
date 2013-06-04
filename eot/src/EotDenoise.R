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
  clusterEvalQ(clstr, c(library(raster), library(rgdal), 
                        source("src/EotRecImage.R")))
  
  
  ### Image reconstruction
  
  # Extract proj4string and extent of raster data
  tmp.prj <- projection(data)
  tmp.ext <- extent(data)
  
  # Convert RasterStack to matrix with spatial locations (== pixels) by column and time steps by row
  tmp.mat <- t(as.matrix(data))
  
  # Perform singular value decomposition (SVD)
  s <- svd(tmp.mat)

  # Reconstruct matrix based on k PCs
  z <- EotRecImage(s, k)
  
  # Convert reconstructed matrix to RasterStack
  clusterExport(clstr, c("z", "data", "tmp.prj", "tmp.ext"), envir = environment())
  
  data.dns <- stack(parLapply(clstr, seq(nrow(z)), function(i) {
    mat <- matrix(z[i, ], nrow = dim(data[[i]])[1], ncol = dim(data[[i]])[2], byrow = TRUE)
    raster(mat, crs = tmp.prj, 
           xmn = xmin(tmp.ext), xmx = xmax(tmp.ext), ymn = ymin(tmp.ext), ymx = ymax(tmp.ext))
  }))
  
  # Deregister parallel backend
  stopCluster(clstr)
  
  # Return output
  return(data.dns)
  
}