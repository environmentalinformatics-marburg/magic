dynFillOutliers <- function(data,
                            window.size,
                            pos.na,
                            ...) {
  
  # Required library
  library(caTools)
  
  # Calculation of running mean for the given window size
  tmp <- data
  tmp.mean <- runmean(x = tmp, k = window.size, endrule = "mean")
  
  # Fill current gap with running mean
  tmp[pos.na] <- tmp.mean[pos.na]
  
  # Output
  return(data.frame(pos.na = pos.na, value = tmp[pos.na]))
  
}