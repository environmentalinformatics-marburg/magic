EotControl <- function(pred, 
                       resp = NULL, 
                       n = 1, 
                       path.out = ".", 
                       names.out,
                       cycle.window = 12, 
                       ...) {
  
  
  ### Environmental settings
  
  
  # Required functions
  source("src/EotCycle.R")
  
  # Duplicate predictor set in case predictor and response are identical
  if (is.null(resp))
    resp <- pred
  
  # Split input RasterStack by given cycle.window
  
  
  
  ### EOT
  
  # Loop through annual RasterStacks
  pred.eot <- lapply(seq(1, nlayers(pred), cycle.window), function(i) {
    
    # User-defined iterations
    for (z in seq(n)) {
      # Use initial response data set in case of first iteration
      if (z == 1) {
        pred.eot <- EotCycle(pred = pred[[i:(i+cycle.window-1)]], 
                             resp = resp[[i:(i+cycle.window-1)]],
                             n = z, 
                             path.out = path.out, 
                             names.out = names.out[ceiling(i/cycle.window)])
        # Use last entry of slot 'residuals' otherwise  
      } else if (z > 1) {
        tmp.pred.eot <- EotCycle(pred = pred[[i:(i+cycle.window-1)]], 
                                 resp = if(!is.list(pred.eot$residuals)) pred.eot$residuals else pred.eot$residuals[[length(pred.eot$residuals)]], 
                                 n = z, 
                                 path.out = path.out, 
                                 names.out = names.out[ceiling(i/cycle.window)])
        pred.eot <- mapply(FUN = append, pred.eot, tmp.pred.eot, SIMPLIFY = FALSE)
      }
    }
    
    return(pred.eot)
    
  })
  
  # Return output list
  return(pred.eot)
  
}
