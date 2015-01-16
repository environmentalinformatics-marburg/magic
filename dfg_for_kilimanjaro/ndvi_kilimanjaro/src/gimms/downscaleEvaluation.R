downscaleEvaluation <- function(rst_pred, 
                                rst_resp, 
                                indices_train,
                                indices_test,
                                nm = NULL,
                                n_eot = 10,
                                var = .95,
                                reduce.both = FALSE,
                                dsn = FALSE,
                                ...) {
  
  if (dsn) {
    rst_pred <- deseason(rst_pred)
    rst_resp <- deseason(rst_resp)
  }
  
  gimms_stck_pred <- rst_resp[[indices_train]]
  gimms_stck_eval <- rst_resp[[indices_test]]
  
  mod_stck_pred <- rst_pred[[indices_train]]                  # MODIS [[1:60]]
  mod_stck_eval <- rst_pred[[indices_test]] # MODIS [[61:120]]
  
  
  ### calculate EOT
  ndvi_modes <- eot(x = gimms_stck_pred, y = mod_stck_pred, n = n_eot, 
                    standardised = FALSE, reduce.both = reduce.both, 
                    verbose = TRUE, write.out = TRUE, path.out = "data/eot_eval")
  
  
  ### calculate number of modes necessary for explaining 95% variance
  if (is.null(nm))
    nm <- nXplain(ndvi_modes, var)
  
  ### prediction using calculated intercept, slope and GIMMS NDVI values
  mod_predicted <- predict(object = ndvi_modes,
                           newdata = gimms_stck_eval,
                           n = nm)
  
  # ### prediction storage
  projection(mod_predicted) <- projection(gimms_stck_eval)
  
  mod_predicted <- writeRaster(mod_predicted, ...)
  
  return(mod_predicted)
}