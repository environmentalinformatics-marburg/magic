EotDenoise <- function(data,
                         k,
                         ...) {
  
  stopifnot(require(ade4))
  
  vals.df <- as.data.frame(getValues(data))
  
  pca.ls <- dudi.pca(vals.df, nf = k, scannf = FALSE)
  
  rcnstrct <- reconst(pca.ls, nf = k)
  
  rst <- data
  rst[] <- as.matrix(rcnstrct)
  
  return(rst)
  
}
                  
                  