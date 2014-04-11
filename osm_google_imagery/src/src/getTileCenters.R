getTileCenters <- function(plt.rds, 
                           plt.res, 
                           ...) {

  #########################################################################################
  # Parameters are as follows:
  #
  # plt.rds (numeric): Overall radius around research plot.  
  # plt.res (numeric): Desired resolution (size) of each tile.    
  # ...:               Further arguments to be passed on to the function.
  #
  #########################################################################################
  
  # Count iterations of outer for-loop
  y <- 1
  
  for (i in seq(plt.rds * (-1) + plt.res, plt.rds - plt.res, plt.res * 2)) {
    
    # Count iterations of inner for-loop
    z <- 1
    
    for (j in seq(plt.rds * (-1) + plt.res, plt.rds - plt.res, plt.res * 2)) {
      
      if (z == 1) {
        tmp.in <- data.frame(i, j) 
      } else {
        tmp.in <- rbind(tmp.in, data.frame(i, j))
      }
      
      # Increment count of iterations (inner for-loop)
      z <- z + 1
      
    } # End of inner for-loop
    
    if (y == 1) {
      tmp.out <- tmp.in
    } else {
      tmp.out <- rbind(tmp.out, tmp.in)
    }
    
    # Increment count of iterations (outer for-loop)
    y <- y + 1
    
  } # End of outer for-loop
  
  # Convert data frame with relative coordinates to list
  tmp.out <- lapply(seq(nrow(tmp.out)), function(i) {
    tmp.out[i,]
  })
  
  # Return output list with relative coordinates
  return(tmp.out)
  
}