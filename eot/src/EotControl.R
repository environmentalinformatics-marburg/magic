EotControl <- function(pred, 
                       resp = NULL, 
                       n = 1, 
                       write.out = F,
                       path.out = ".", 
                       names.out = NULL,
                       cycle.window = NULL, 
                       ...) {
  
  
  ### Environmental settings
  
  # Required functions
  source("src/EotCycle.R")
  
  # Duplicate predictor set in case predictor and response are identical
  if (is.null(resp)) {
    resp <- pred  
    resp.eq.pred = T
  } else {
    resp.eq.pred = F
  }
  
  # Cycle window if not provided
  if (is.null(cycle.window))
    cycle.window <- nlayers(pred)
  
  
  ### EOT
  
  # Loop through RasterStacks by specified cycle.window (e.g. 12 for one year)
  pred.eot <- lapply(seq(1, nlayers(pred), cycle.window), function(i) {
    
    # User-defined iterations
    for (z in seq(n)) {
      # Use initial response data set in case of first iteration
      if (z == 1) {
        pred.eot <- EotCycle(pred = pred[[i:(i+cycle.window-1)]], 
                             resp = resp[[i:(i+cycle.window-1)]],
                             resp.eq.pred = resp.eq.pred,
                             n = z, 
                             write.out = write.out,
                             path.out = path.out, 
                             names.out = if (!is.null(names.out) | write.out) {
                               names.out[ceiling(i/cycle.window)]
                             } else {
                               NULL
                             })
        # Use last entry of slot 'residuals' otherwise  
      } else if (z > 1) {
        tmp.pred.eot <- EotCycle(pred = pred[[i:(i+cycle.window-1)]], 
                                 resp = if(!is.list(pred.eot$resid.predictor)) {
                                   pred.eot$resid.predictor 
                                 } else {
                                   pred.eot$resid.predictor[[length(pred.eot$resid.predictor)]] 
                                 }, 
                                 resp.eq.pred = resp.eq.pred,
                                 n = z, 
                                 write.out = write.out,
                                 path.out = path.out, 
                                 names.out = if (!is.null(names.out) | write.out) {
                                   names.out[ceiling(i/cycle.window)]
                                 } else {
                                   NULL
                                 })
        pred.eot <- mapply(FUN = append, pred.eot, tmp.pred.eot, SIMPLIFY = FALSE)
      }
    }
    
    return(pred.eot)
    
  })
  
  # Return output list
  return(pred.eot)
  
}
