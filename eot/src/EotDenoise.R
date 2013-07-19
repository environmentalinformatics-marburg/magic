EotDenoise <- function(data,
                       k,
                       n.cores = NULL, 
                       ...) {

  # Required packages
  stopifnot(require(doParallel))
  
  # PCA
  data.vals <- data[]
  data.vals_pca <- prcomp(data.vals)
  
  eivecs <- data.vals_pca$rotation[, 1:k]
  pvals <- data.vals_pca$x[, 1:k]
  cent <- data.vals_pca$center
  
  # Reconstruction
  recons <- lapply(seq(nrow(eivecs)), function(i) {
    rowSums(t(eivecs[i, ] * t(pvals))) + cent[i]
  })
  
  # Parallelization
  if (is.null(n.cores)) 
    n.cores <- detectCores()
  
  clstr <- makeCluster(n.cores)
  clusterEvalQ(clstr, library(raster))

  # Insert reconstructed values in original data set
  clusterExport(clstr, c("data", "recons"), envir = environment())
  data.tmp <- do.call("brick", parLapply(clstr, seq(recons), function(i) {
    tmp.data <- data[[i]]
    tmp.recons <- recons[[i]]

    tmp.data[] <- tmp.recons
    return(tmp.data)
  }))

  # Deregister parallel backend
  stopCluster(clstr)

  # Return denoised data set
  return(data)
}
