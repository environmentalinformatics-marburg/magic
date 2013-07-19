EotCycle <- function(pred, 
                     resp, 
                     resp.eq.pred = F,
                     n = 1,
                     write.out,
                     path.out,
                     names.out,
                     n.cores = NULL,
                     ...) {
  
  
  ### Environmental settings
  
  # Required packages and functions
  lib <- c("raster", "doParallel", "Rcpp")
  sapply(lib, function(...) stopifnot(require(..., character.only = T)))
  
  sourceCpp("src/EotCppFun.cpp")
  
  
  ### Identification of the most explanatory pred pixel
  
  # Extract pixel entries from RasterStack objects
  pred.vals <- getValues(pred)
  resp.vals <- getValues(resp)
  
  # Calculate and summarize R-squared per pred pixel
  cat("Calculating linear model ...", "\n")
  x <- predRsquaredSum(pred_vals = pred.vals, resp_vals = resp.vals)
  # Replace missing values (land masses) with 0
  x[which(is.na(x))] <- 0 
  
  # Identify pred pixel with highest sum of r.squared
  cat("Locating ", n, ". EOT ...", "\n", sep = "")
  maxxy <- which(x == max(x, na.rm = TRUE))
  
  
  ### Regression of most explanatory pred pixel with resp pixels
    
  ## Fit lm
  
  # lm(resp.vals[i, ] ~ pred.vals[maxxy, ]) with T statistics
  resp.lm.param.t <- respLmParam(pred.vals, resp.vals, maxxy - 1) # C++ starts at 0!
  # Calculate p value from T statistics
  resp.lm.param.p <- lapply(resp.lm.param.t, function(i) {
    tmp <- i
    tmp[[5]] <- 2 * pt(-abs(tmp[[5]]), df = tmp[[6]])
    
    return(tmp)
  })  
  
  
  ## Rasterize lm parameters
  
  # RasterLayer template for R-squared, slope and p value
  rst.resp.template <- raster(nrows = nrow(resp), ncols = ncol(resp), 
                         xmn = xmin(resp), xmx = xmax(resp), 
                         ymn = ymin(resp), ymx = ymax(resp))
  
  rst.resp.r <- rst.resp.rsq <- rst.resp.slp <- rst.resp.p <- rst.resp.template

  # RasterBrick template for residuals
  brck.resp.resids <- brick(nrows = nrow(resp), ncols = ncol(resp), 
                            xmn = xmin(resp), xmx = xmax(resp), 
                            ymn = ymin(resp), ymx = ymax(resp), 
                            nl = nlayers(resp))
  
  # R
  rst.resp.r[] <- sapply(resp.lm.param.p, "[[", 1)
  # R-squared
  rst.resp.rsq[] <- sapply(resp.lm.param.p, "[[", 1) ^ 2
  # Slope
  rst.resp.slp[] <- sapply(resp.lm.param.p, "[[", 3)
  # P value
  rst.resp.p[] <- sapply(resp.lm.param.p, "[[", 5)
  # Residuals
  brck.resp.resids[] <- matrix(sapply(resp.lm.param.p, "[[", 4), 
                               ncol = nlayers(pred), byrow = TRUE)
  
  
  ### Regression of most explanatory pred pixel with pred pixels
  
  # Following code is only executed when pred and resp are not equal
  if (!resp.eq.pred) {
    
    ## Fit lm
    
    # lm(pred.vals[i, ] ~ pred.vals[maxxy, ]) with T statistics
    pred.lm.param.t <- respLmParam(pred.vals, pred.vals, maxxy - 1) # C++ starts at 0!
    # Calculate p value from T statistics
    pred.lm.param.p <- lapply(pred.lm.param.t, function(i) {
      tmp <- i
      tmp[[5]] <- 2 * pt(-abs(tmp[[5]]), df = tmp[[6]])
      
      return(tmp)
    })  
    
    
    ## Rasterize lm parameters
    
    # RasterLayer template for R-squared, slope and p value
    rst.pred.template <- raster(nrows = nrow(pred), ncols = ncol(pred), 
                                xmn = xmin(pred), xmx = xmax(pred), 
                                ymn = ymin(pred), ymx = ymax(pred))
    
    rst.pred.r <- rst.pred.rsq <- rst.pred.slp <- rst.pred.p <- rst.pred.template
    
    # RasterBrick template for residuals
    brck.pred.resids <- brick(nrows = nrow(pred), ncols = ncol(pred), 
                              xmn = xmin(pred), xmx = xmax(pred), 
                              ymn = ymin(pred), ymx = ymax(pred), 
                              nl = nlayers(pred))
    
    # R
    rst.pred.r[] <- sapply(pred.lm.param.p, "[[", 1)
    # R-squared
    rst.pred.rsq[] <- sapply(pred.lm.param.p, "[[", 1) ^ 2
    # Slope
    rst.pred.slp[] <- sapply(pred.lm.param.p, "[[", 3)
    # P value
    rst.pred.p[] <- sapply(pred.lm.param.p, "[[", 5)
    # Residuals
    brck.pred.resids[] <- matrix(sapply(pred.lm.param.p, "[[", 4), 
                                 ncol = nlayers(pred), byrow = TRUE)
    
    
    ### Output
    
    # Output returned by function
    out <- list(sum.rsq = x,
                max.xy = maxxy,
                r.predictor = rst.pred.r,
                rsq.predictor = rst.pred.rsq,
                slp.predictor = rst.pred.slp,
                p.predictor = rst.pred.p,
                resid.predictor = brck.pred.resids,
                r.response = rst.resp.r,
                rsq.response = rst.resp.rsq,
                slp.response = rst.resp.slp,
                p.response = rst.resp.p,
                resid.response = brck.resp.resids)
    
    # Output storage (optional)
    if (write.out) {
      out.name <- lapply(c("pred_r", "pred_rsq", "pred_slp", "pred_p", "pred_resids", 
                           "resp_r", "resp_rsq", "resp_slp", "resp_p", "resp_resids"), 
                         function(i) {
                           paste(names.out, "eot", sprintf("%02.f", n), i, sep = "_")
                         })
      
      registerDoParallel(clstr <- makeCluster(if (is.null(n.cores)) detectCores() else n.cores))
      foreach(a = c(rst.pred.r, rst.pred.rsq, rst.pred.slp, rst.pred.p, brck.pred.resids,
                    rst.resp.r, rst.resp.rsq, rst.resp.slp, rst.resp.p, brck.resp.resids), 
              b = unlist(out.name), .packages = "raster") %dopar% {
                writeRaster(a, paste(path.out, b, sep = "/"), format = "raster", overwrite = TRUE)
              }
      stopCluster(clstr)
    }
    
  } else {
        
    # Output returned by function
    out <- list(sum.rsq = x,
                max.xy = maxxy,
                r.response = rst.resp.r,
                rsq.response = rst.resp.rsq,
                slp.response = rst.resp.slp,
                p.response = rst.resp.p,
                resid.response = brck.resp.resids)
    
    # Output storage (optional)
    if (write.out) {
      out.name <- lapply(c("resp_r", "resp_rsq", "resp_slp", "resp_p", "resp_resids"), 
                         function(i) {
                           paste(names.out, "eot", sprintf("%02.f", n), i, sep = "_")
                         })
      
      registerDoParallel(clstr <- makeCluster(if (is.null(n.cores)) detectCores() else n.cores))
      foreach(a = c(rst.resp.r, rst.resp.rsq, rst.resp.slp, rst.resp.p, brck.resp.resids), 
              b = unlist(out.name), .packages = "raster") %dopar% {
                writeRaster(a, paste(path.out, b, sep = "/"), format = "raster", overwrite = TRUE)
                      }
      stopCluster(clstr)
    }
  }
  
  # Return output
  return(out)
}