cellHarmonics <- function(st, 
                          nd, 
                          st.start, st.end, 
                          nd.start, nd.end, 
                          product = "MOD13Q1", 
                          path.out = NULL,
                          n.cores = 2) {
  
  ## Environmental stuff
  
  # Packages
  lib <- c("raster", "rgdal", "doParallel", "Rsenal")
  sapply(lib, function(...) stopifnot(require(..., character.only = TRUE)))
  
  # Parallelization
  registerDoParallel(cl <- makeCluster(n.cores))
  
  
  ## Data processing
  
  # Extract values
  st.mat <- getValues(st)
  nd.mat <- getValues(nd)
  
  # Stop if start and end rasters have different number of cells
  if (nrow(st.mat) != nrow(nd.mat))
    stop("Start and end data have unequal number of cells.
         Check data integrity!")
  
  
  # Calculate differences in amplitude and phase per cell
  params <- foreach(i = seq(nrow(st.mat)), .packages = lib) %dopar% {
    
    fit.med <- foreach(j = list(st.mat, nd.mat), k = list(st.start, nd.start), 
                       l = list(st.end, nd.end)) %do% {
                         
        vectorHarmonics(j[i, ], st = k, nd = l)  
        
        #       # Cell time series
        #       tmp.ts <- ts(j[i, ], start = k, end = l, frequency = 12)
        #       
        #       if (all(is.na(tmp.ts))) {
        #         stop(paste("Time series of cell", i, "contains no valid values!"))
        #       } else {
        #         #         # Harmonic functions
        #         tmp.har <- harmonic(tmp.ts)
        #         
        #         # Linear model fitting
        #         tmp.mod <- lm(tmp.ts ~ tmp.har)
        #         tmp.fit <- ts(fitted(tmp.mod), start = st.start, end = st.end, 
        #                       frequency = 12)
        #         
        #         # Median
        #         tmp.fit.med <- apply(matrix(tmp.fit, ncol = 12, byrow = T), 2, 
        #                              FUN = median)
        #         # Moving average
        #         tmp.fit.med.rmean <- filter(tmp.fit.med, rep(1/3, 3), circular = T)
        #         
        #       }
}
    
    # Month with hightest NDVI + corresponding value
    st.max.x <- which(fit.med[[1]] == max(fit.med[[1]]))
    st.max.y <- fit.med[[1]][st.max.x]
    nd.max.x <- which(fit.med[[2]] == max(fit.med[[2]]))
    nd.max.y <- fit.med[[2]][nd.max.x]
    
    # Month with lowest NDVI + corresponding value
    st.min.x <- which(fit.med[[1]] == min(fit.med[[1]]))
    st.min.y <- fit.med[[1]][st.min.x]
    nd.min.x <- which(fit.med[[2]] == min(fit.med[[2]]))
    nd.min.y <- fit.med[[2]][nd.min.x]
    
    # Return output    
    return(list(st = list(max.x = st.max.x, 
                          max.y = st.max.y, 
                          min.x = st.min.x, 
                          min.y = st.min.y), 
                nd = list(max.x = nd.max.x, 
                          max.y = nd.max.y, 
                          min.x = nd.min.x, 
                          min.y = nd.min.y)))
  }
  
  # Rasterize calculated values
  param.rst <- foreach(h = seq(2)) %do% {
    foreach(i = seq(4), .combine = "stack", .packages = lib) %dopar% {
      raster(matrix(unlist(sapply(lapply(params, "[[", h), "[[", i)), 
                    ncol = ncol(st), nrow = nrow(st), byrow = T), template = st)
    }
  }
  param.rst <- foreach(i = param.rst, j = list("st", "nd")) %do% {
    names(i) <- paste(j, c("max_x", "max_y", "min_x", "min_y"), sep = "_")
    return(i)
  }
  
  if (!is.null(path.out)) {
    param.rst <- foreach(i = param.rst, j = list("st", "nd"), .packages = lib) %dopar% {
      names(i) <- paste(j, c("max_x", "max_y", "min_x", "min_y"), sep = "_")
      writeRaster(i, paste(path.out, "/", product, "_", j, sep = ""), 
                  format = "GTiff", overwrite = T, suffix = "names", bylayer = T)
    }
  }
    
  # Return output
  stopCluster(cl)
  return(param.rst)
}