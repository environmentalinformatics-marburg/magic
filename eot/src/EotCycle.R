EotCycle <- function(pred, 
                     resp, 
                     n = 1,
                     path.out,
                     ...) {
  
  
  ### Environmental settings
    
  # Required packages
  stopifnot(require(raster))
  stopifnot(require(parallel))
  
  # Parallelization
  n.cores <- detectCores()
  clstr <- makePSOCKcluster(n.cores)
  
  
  ### Data processing
  
  # Extract values from RasterStack objects
  pred.vals <- getValues(pred)
  resp.vals <- getValues(resp)
  # Export extracted values to cluster
  clusterExport(clstr, c("pred.vals", "resp.vals"), envir = environment())
  
  
  ### Identification of the most explanatory pred pixel
  
  # Calculate and summarize R-squared per pred pixel
  cat("calculating linear model...", "\n")
  x <- parLapply(clstr, seq(nrow(pred.vals)), function(i) {
    do.call("sum", lapply(seq(nrow(resp.vals)), function(j) {
      cor(resp.vals[j,], pred.vals[i,])^2
    }))
  })  
  
  # Identify pred pixel with highest sum of r.squared
  cat("locating EOT...", n, "\n")
  maxxy <- which(unlist(x) == max(unlist(x), na.rm = TRUE))
  
  
  ### Regression of most explanatory pred pixel with resp pixels
  
  ## R-squared
  
  # Setup raster for R-squared
  rst.resp.rsq <- raster(nrows = nrow(resp), ncols = ncol(resp), 
                         xmn = xmin(resp), xmx = xmax(resp), 
                         ymn = ymin(resp), ymx = ymax(resp))
  
  # Fit R-squared in template
  clusterExport(clstr, "maxxy", envir = environment())
  rst.resp.rsq[] <- parSapply(clstr, seq(nrow(resp.vals)), function(i) {
    cor(pred.vals[maxxy, ], resp.vals[i, ])^2
  })
  
  ## Residuals
  
  # Setup brick for residuals
  brck.resp.resids <- brick(nrows = nrow(resp), ncols = ncol(resp), 
                            xmn = xmin(resp), xmx = xmax(resp), 
                            ymn = ymin(resp), ymx = ymax(resp), 
                            nl = nlayers(resp))

  # Regression of identified pred pixel with all resp pixels
  resp.resids <- parLapply(clstr, seq(nrow(resp.vals)), function(i) {
    tmp.lm <- lm(resp.vals[i, ] ~ pred.vals[maxxy, ]) # Linear model
    resid(tmp.lm) # Residuals
  }) 
  
  # Fit residuals in template
  brck.resp.resids[] <- do.call("rbind", resp.resids)
  
  
  ### Regression of most explanatory pred pixel with pred pixels
  
  ## R-squared
  
  # Setup raster for R-squared
  rst.pred.rsq <- raster(nrows = nrow(pred), ncols = ncol(pred), 
                         xmn = xmin(pred), xmx = xmax(pred), 
                         ymn = ymin(pred), ymx = ymax(pred))
  
  # Fit R-squared in template
  rst.pred.rsq[] <- parSapply(clstr, seq(nrow(pred.vals)), function(i) {
    cor(pred.vals[maxxy, ], pred.vals[i, ])^2
  })
  
  
  ### Output
  
  # Setup output list
  out <- list(sum.rsq = unlist(x),
              max.xy = maxxy,
              rsq.predictor = rst.pred.rsq,
              rsq.response = rst.resp.rsq,
              residuals = brck.resp.resids)
  
  # Store R-squared raster images
  out.name.pred <- paste("eot", sprintf("%02.f", n), 
                         "pred_rsq", sep = "_")
  out.name.resp <- paste("eot", sprintf("%02.f", n), 
                         "resp_rsq", sep = "_")
  
  writeRaster(rst.pred.rsq, paste(path.out, out.name.pred, sep = "/"), format = "raster", overwrite = TRUE)
  writeRaster(rst.resp.rsq, paste(path.out, out.name.resp, sep = "/"), format = "raster", overwrite = TRUE)
  
  # Close cluster
  stopCluster(clstr)
  
  # Return output
  return(out)
  
}
