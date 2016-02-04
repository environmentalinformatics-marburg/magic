fillOutliers <- function(data,
                         window.size = 4,
                         ...) {
  
  library(caTools)
  
  data.gf <- data.frame(do.call("cbind", lapply(1:ncol(data), function(i) {
    tmp <- as.numeric(data[,i])
    tmp.mean <- runmean(x = as.numeric(data[,i]), k = window.size, endrule = "mean")
    
    # Fill previously rejected outliers with running mean
    tmp[which(is.na(tmp))] <- tmp.mean[which(is.na(tmp))]
    tmp
  })))
  
  names(data.gf) <- names(data)
  rownames(data.gf) <- rownames(data)
  
  return(data.gf)
  
}