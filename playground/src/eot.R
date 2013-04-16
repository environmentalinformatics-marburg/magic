
#### function definition #######################################################
eot <- function(pred, resp, n = 1) {
  
  stopifnot(require(raster))
  
  ## extract values from ratser stacks
  pred.vals <- getValues(pred)
  resp.vals <- getValues(resp)
  
  ## calculate and sum r.squared for all pixel combinations between pred & resp
  cat("calculating linear model...", "\n")
  x <- lapply(seq(nrow(pred.vals)), function(i) {
    
    tmp.lst <- lapply(seq(nrow(resp.vals)), function(j) {
      
      tmp <- summary(lm(resp.vals[j, ] ~ pred.vals[i, ]))$r.squared
      return(tmp)
      
    })
    
    do.call("sum", tmp.lst)
    
  })

  ## identify which pred pixel has highest sum of r.squared
  cat("locating EOT...", n, "\n")
  maxxy <- which(unlist(x) == max(unlist(x)))
  
  ## regression of identified pred pixel with all resp pixels
  resp.lm <- lapply(seq(nrow(resp.vals)), function(k) {
    
    lmyx <- lm(resp.vals[k, ] ~ pred.vals[maxxy, ])
#     tmp <- summary(lmyx)$r.squared
#     resids <- lmyx$residuals
#     
#     return(cbind(tmp, resids))
  })

  ## create raster of r.squared from step above
  rst.resp.rsq <- raster(nrows = nrow(resp), ncols = ncol(resp), 
                         xmn = xmin(resp), xmx = xmax(resp), 
                         ymn = ymin(resp), ymx = ymax(resp))
  rst.resp.rsq[] <- sapply(seq(resp.lm), function(i) {
    summary(resp.lm[[i]])$r.squared
  })
  
  ## create stack of residuals from step above
  stck.resp.resids <- lapply(seq(resp.lm), function(i) {
    resp.lm[[i]]$residuals
    })
  
  brck.resp.resids <- brick(nrows = nrow(resp), ncols = ncol(resp), 
                            xmn = xmin(resp), xmx = xmax(resp), 
                            ymn = ymin(resp), ymx = ymax(resp), 
                            nl = nlayers(resp))
  brck.resp.resids[] <- do.call("rbind", stck.resp.resids)
  
  ## regression of identified pred pixel with all pred pixels
  pred.rst.rsq <- sapply(seq(nrow(pred.vals)), function(l) {
    
    tmp <- summary(lm(pred.vals[l, ] ~ pred.vals[maxxy, ]))$r.squared
    return(tmp)
  })
 
  ## create raster of r.squared from step above
  rst.pred.rsq <- raster(nrows = nrow(pred), ncols = ncol(pred), 
                         xmn = xmin(pred), xmx = xmax(pred), 
                         ymn = ymin(pred), ymx = ymax(pred))
  rst.pred.rsq[] <- unlist(pred.rst.rsq)
  
  ## create output list
  out <- list(sum.rsq = unlist(x),
              max.xy = maxxy,
              rsq.predictor = rst.pred.rsq,
              rsq.response = rst.resp.rsq,
              residuals = brck.resp.resids)
  
  out.name.pred <- paste("eot", sprintf("%02.f", n), 
                         "pred.rsq", "grd", sep = ".")
  
  out.name.resp <- paste("eot", sprintf("%02.f", n), 
                         "resp.rsq", "grd", sep = ".")
  
  writeRaster(rst.pred.rsq, out.name.pred, overwrite = TRUE)
  writeRaster(rst.resp.rsq, out.name.resp, overwrite = TRUE)
  
  if (n > 1) 
    for (i in 2:n)
      eot(pred, brck.resp.resids)
  
  return(out)
  
}
