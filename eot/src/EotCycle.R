EotCycle <- function(pred, 
                     resp, 
                     n = 1,
                     path.out,
                     ...) {
  
  
  ### Environmental settings
    
  # Required packages
  stopifnot(require(raster))
  stopifnot(require(doParallel))
  
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
  
  # Calculate and summarize r-squared per pred pixel
  cat("calculating linear model...", "\n")
  x <- parLapply(clstr, seq(nrow(pred.vals)), function(i) {
    do.call(function(...) {sum(..., na.rm = TRUE)}, lapply(seq(nrow(resp.vals)), function(j) {
      cor(resp.vals[j,], pred.vals[i,])^2
    }))
  })  
  
  # Identify pred pixel with highest sum of r.squared
  cat("locating EOT...", n, "\n")
  maxxy <- which(unlist(x) == max(unlist(x), na.rm = TRUE))
  
  
  ### Regression of most explanatory pred pixel with resp pixels
  
  ## R and r-squared
  
  rst.resp.r <- raster(nrows = nrow(resp), ncols = ncol(resp), 
                       xmn = xmin(resp), xmx = xmax(resp), 
                       ymn = ymin(resp), ymx = ymax(resp))
  
  # Fit r in template
  clusterExport(clstr, "maxxy", envir = environment())
  rst.resp.r[] <- parSapply(clstr, seq(nrow(resp.vals)), function(i) {
    cor(pred.vals[maxxy, ], resp.vals[i, ])
  })
  
  # Fit r-squared in template
  rst.resp.rsq <- rst.resp.r^2
  
  ## Slope
  
  rst.resp.slp <- rst.resp.r
  rst.resp.slp[] <- parSapply(clstr, seq(nrow(resp.vals)), function(i) {
    tmp.lm <- lm(resp.vals[i, ] ~ pred.vals[maxxy, ])
    coef(tmp.lm)[2] 
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
  
  ## r-squared
  
  # Setup raster for r-squared
  rst.pred.r <- raster(nrows = nrow(pred), ncols = ncol(pred), 
                         xmn = xmin(pred), xmx = xmax(pred), 
                         ymn = ymin(pred), ymx = ymax(pred))
  
  # Fit r in template
  rst.pred.r[] <- parSapply(clstr, seq(nrow(pred.vals)), function(i) {
    cor(pred.vals[maxxy, ], pred.vals[i, ])
  })
  
  # Fit r-squared in template
  rst.pred.rsq <- rst.pred.r^2
  
  ## Slope
  
  rst.pred.slp <- rst.pred.r
  rst.pred.slp[] <- parSapply(clstr, seq(nrow(pred.vals)), function(i) {
    tmp.lm <- lm(pred.vals[i, ] ~ pred.vals[maxxy, ])
    coef(tmp.lm)[2] 
  })

  
  ### Output
  
  # Setup output list
  out <- list(sum.rsq = unlist(x),
              max.xy = maxxy,
              r.predictor = rst.pred.r,
              rsq.predictor = rst.pred.rsq,
              slp.predictor = rst.pred.slp,
              r.response = rst.resp.r,
              rsq.response = rst.resp.rsq,
              slp.response = rst.resp.slp,
              residuals = brck.resp.resids)
  
#   # Prepare output file names
#   out.name <- lapply(c("pred_r", "pred_rsq", "pred_slp", "resp_r", "resp_rsq", "resp_slp"), function(i) {
#     paste("eot", sprintf("%02.f", n), i, sep = "_")
#   })
#   
#   # Store r, r-squared and slope raster images
#   out.rst <- foreach(a = c(rst.pred.r, rst.pred.rsq, rst.pred.slp, rst.resp.r, rst.resp.rsq, rst.resp.slp), b = unlist(out.name)) %do% {
#                        writeRaster(a, paste(path.out, b, sep = "/"), format = "raster", overwrite = TRUE)
#                      }
  
  # Close cluster
  stopCluster(clstr)
  
  # Return output
  return(out)
  
}
