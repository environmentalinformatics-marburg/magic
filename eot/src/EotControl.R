EotControl <- function(pred, 
                       resp = NULL, 
                       n = 1, 
                       path.out, 
                       ...) {
  
  
  ### Environmental settings
  
  
  # Required functions
  source("src/EotCycle.R")
 
  # Duplicate predictor set in case predictor and response are identical
  if (is.null(resp))
    resp <- pred
  
  
  ### EOT
  
  # Loop through annual RasterStacks
  pred.eot <- lapply(seq(pred), function(i) {
    
    # User-defined iterations
    for (z in seq(n)) {
      # Use initial response data set in case of first iteration
      if (z == 1) {
        pred.eot <- EotCycle(pred = pred[[i]], 
                        resp = resp[[i]],
                        n = z, 
                        path.out = path.out)
        # Use last entry of slot 'residuals' otherwise  
      } else if (z > 1) {
        tmp.pred.eot <- EotCycle(pred = pred[[i]], 
                            resp = if(!is.list(pred.eot$residuals)) pred.eot$residuals else pred.eot$residuals[[length(pred.eot$residuals)]], 
                            n = z, 
                            path.out = path.out)
        pred.eot <- mapply(FUN = append, pred.eot, tmp.pred.eot, SIMPLIFY = FALSE)
      }
    }
    
    return(pred.eot)
    
  })
  
  # Return output list
  return(pred.eot)
  
}
