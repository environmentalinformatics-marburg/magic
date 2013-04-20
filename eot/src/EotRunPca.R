EotRunPca <- function(mat, 
                      ...) {
  
  # Perform PCA
  eigen(cov(apply(mat, 2, function(i) i - mean(i))))
  
}