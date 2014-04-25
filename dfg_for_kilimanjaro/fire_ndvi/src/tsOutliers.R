# Taken from http://stats.stackexchange.com/questions/1142/simple-algorithm-for-online-outlier-detection-of-a-generic-time-series
#' Identify statistical outliers in time series
#' 
#' @export tsOutliers
tsOutliers <- function(x, 
                       lower.limit = .2, 
                       upper.limit = .8,
                       plot = FALSE,
                       index = FALSE,
                       ...) {
  
  # Convert input vector to time series
  x <- ts(x, ...)
  
  # Residuals
  if(frequency(x) > 1) {
    resid <- stl(x, s.window = "periodic", robust = T, 
                 na.action = na.exclude)$time.series[, 3]
  } else {
    tt <- 1:length(x)
    resid <- residuals(loess(x ~ tt, na.action = na.exclude))
  }
  
  # Calculate scores
  resid.q <- quantile(resid, prob = c(lower.limit, upper.limit), na.rm = T)
  iqr <- diff(resid.q)
  limits <- resid.q + 1.5 * iqr * c(-1, 1)
  score <- abs(pmin((resid - limits[1]) / iqr, 0) + 
                 pmax((resid - limits[2]) / iqr, 0))
  
  # Optional plotting
  if (plot) {
    plot(x)
    
    x2 <- ts(rep(NA,length(x)))
    x2[score > 0 & !is.na(score)] <- x[score > 0 & !is.na(score)]
    tsp(x2) <- tsp(x)
    points(x2, pch = 19, col = "red")
  }
  
  # Return output
  if (index) {
    return(which(score > 0 & !is.na(score)))
  } else {
    return(score)
  }
}
