EotDenoise <- function(data,
                       k,
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
  clstr <- makePSOCKcluster(n.cores <- 4)
  clusterExport(clstr, c("data", "recons"))
  clusterEvalQ(clstr, library(raster))

  # Insert reconstructed values in original data set
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
