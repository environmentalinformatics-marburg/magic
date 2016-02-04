rejectOutliers <- function(data,
                           window.size = 10,
                           ...) {
  
  library(caTools)
    
  data.sd <- data.frame(do.call("cbind", lapply(1:ncol(data), function(i) {
    tmp <- as.numeric(data[,i])
    tmp.mean <- runmean(x = as.numeric(data[,i]), k = window.size, endrule = "mean")
    tmp.sd <- sd(tmp.mean)
    
    # Reject outliers (+/- 2*SD)
    tmp[which(tmp < (tmp.mean - 2 * tmp.sd) | tmp > (tmp.mean + 2 * tmp.sd))] <- NA
    tmp
  })))
  
  names(data.sd) <- names(data)
  rownames(data.sd) <- rownames(data)
  
  return(data.sd)
  
}