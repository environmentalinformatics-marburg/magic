EotRecImage <- function(s, 
                        k = 1, 
                        ...) {
  
  # Reconstruct decomposed matrix
  U <- s$u[,1:k]
  D <- matrix(0, k, k)
  diag(D) <- s$d[1:k]
  V <- s$v[,1:k]
  xhat <- U %*% D %*% t(V)
  
  # Return output
  return(xhat)
  
}