codeMatches <- function(x, code = 1, single_obs = TRUE, ...) {
  
  # error selection, returns matching observation only
  if (single_obs) {
    
    return(subset(x, Code == code))
    
  } else {
    
    # error selection, returns entire sheet per matching plot
    error_id <- sapply(x, function(i) {
      code %in% i$Code
    })
    
    return(x[error_id])
  }
}