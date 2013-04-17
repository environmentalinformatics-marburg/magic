EotControl <- function(pred, 
                       resp, 
                       n = 1, 
                       path.out, 
                       ...) {
  
  
  ### Environmental settings
  
  # Required functions
  source("src/EotCycle.R")
  
  
  ### Data processing
  
  # User-defined iterations
  for (z in seq(n)) {
    # Use initial response data set in case of first iteration
    if (z == 1) {
      tst <- EotCycle(pred = pred.stck.crp, 
                      resp = resp.stck.crp, 
                      n = z, 
                      path.out = path.out)
      # Use last entry of slot 'residuals' otherwise  
    } else if (z > 1) {
      tmp.tst <- EotCycle(pred = pred.stck.crp, 
                          resp = if(!is.list(tst$residuals)) tst$residuals else tst$residuals[[length(tst$residuals)]], 
                          n = z, 
                          path.out = path.out)
      tst <- mapply(FUN = append, tst, tmp.tst, SIMPLIFY = FALSE)
    }
  }
  
  # Return output list
  return(tst)
  
}
