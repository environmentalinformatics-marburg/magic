### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/pa_NDown/ki_modis_ndvi/"}, 
       "Windows" = {path.wd <- "G:/ki_modis_ndvi"})
setwd(path.wd)

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal", "kza", "Rsenal")
sapply(lib, function(x) stopifnot(require(x, character.only = T)))

# Parallelization
registerDoParallel(cl <- makeCluster(4))


### Data import

ndvi.fill <- lapply(c("MOD13Q1", "MYD13Q1"), function(h) {
  
## MODIS NDVI 

  # List files and order by date
  ndvi.fls <- list.files("data/quality_control/", pattern = h, 
                         recursive = T, full.names = T)
  
  ndvi.dates <- substr(basename(ndvi.fls), 13, 19)
  ndvi.years <- unique(substr(basename(ndvi.fls), 13, 16))
  
  ndvi.fls <- ndvi.fls[order(ndvi.dates)]
  
  # Setup time series
  ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
    seq(as.Date(paste(i, "01", ifelse(h == "MOD13Q1", "01", "09"), sep = "-")), 
        as.Date(paste(i, "12", "31", sep = "-")), 16)
  }))
  
  # Merge time series with available NDVI files
  ndvi.ts.fls <- merge(data.frame(date = ndvi.ts), 
                       data.frame(date = as.Date(ndvi.dates, format = "%Y%j"), 
                                  file = ndvi.fls, stringsAsFactors = F), 
                       by = "date", all.x = T)
  
  # Import raster files
  ndvi.rst <- foreach(i = seq(nrow(ndvi.ts.fls)), .packages = lib) %dopar% {
    if (is.na(ndvi.ts.fls[i, 2])) {
      NA
    } else {
      raster(ndvi.ts.fls[i, 2])
    }
  }
  
  # Convert rasters to matrices
  ndvi.mat <- foreach(i = ndvi.rst, .packages = lib) %dopar% {
    if (is.logical(i)) 
      return(NA)
    else
      as.matrix(i)
  }
  
  
  ### Imputation
    
  # Identify first valid raster
  first.valid <- ndvi.rst[[which(!sapply(ndvi.rst, is.logical))[1]]]
  
  ndvi.fill <- foreach(i = seq(ncell(first.valid)), 
                       .packages = lib) %dopar% {
    source("src/gfGapLength.R")
                         
    # Cell time series
    tmp <- sapply(ndvi.mat, function(j) t(j)[i])
    
    # Maximum gap length
    pos.na <- which(is.na(tmp))
    s <- max(sapply(gfGapLength(tmp, pos.na, gap.limit = 999), "[[", 3))
    
    # Kolmogorov-Zurbenko Adaptive (KZA)
    tmp.fill <- round(kza(tmp, m = 5, k = s + 1, impute_tails = T)$kz)
    tmp[pos.na] <- tmp.fill[pos.na]
    
    return(tmp)
  }
  
  return(ndvi.fill)
})

# Rasterize numeric vectors
ndvi.fls <- list.files("data/quality_control/", pattern = "MYD13Q1", 
                       recursive = T, full.names = T)
template <- raster(ndvi.fls[1])

ndvi.fill.rst <- foreach(i = ndvi.fill, h = seq(length(ndvi.fill))) %do% {
  print(h)
  n.layers <- unique(sapply(i, length))
  
  if (length(n.layers) > 1)
    stop("Number of observations per pixel is not equal.\n 
         Please check data integrity!")
  
  foreach(j = seq(n.layers), .packages = lib, .combine = "stack") %dopar% {
    tmp.val <- sapply(i, "[[", j)
    tmp.mat <- matrix(tmp.val, ncol = ncol(template), nrow = nrow(template), 
                      byrow = T)
    tmp.rst <- raster(tmp.mat, template = template)
    return(tmp.rst)
  }
}

tst <- foreach(h = c("MOD13Q1", "MYD13Q1"), g = c(1, 2), .packages = lib) %dopar% {
  # List files and order by date
  ndvi.fls <- list.files("data/quality_control/", pattern = h, 
                         recursive = T, full.names = T)
  
  ndvi.dates <- substr(basename(ndvi.fls), 13, 19)
  ndvi.years <- unique(substr(basename(ndvi.fls), 13, 16))
  
  ndvi.fls <- ndvi.fls[order(ndvi.dates)]
  
  # Setup time series
  ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
    seq(as.Date(paste(i, "01", ifelse(h == "MOD13Q1", "01", "09"), sep = "-")), 
        as.Date(paste(i, "12", "31", sep = "-")), 16)
  }))
  
  # Merge time series with available NDVI files
  ndvi.ts.fls <- merge(data.frame(date = ndvi.ts), 
                       data.frame(date = as.Date(ndvi.dates, format = "%Y%j"), 
                                  file = ndvi.fls, stringsAsFactors = F), 
                       by = "date", all.x = T)
  
  names(ndvi.fill.rst[[g]]) <- strftime(ndvi.ts.fls[, 1], format = "%Y%j")
  writeRaster(ndvi.fill.rst[[g]], bylayer = T, 
              filename = paste("data/gap_filled/KZA_", h, ".A", sep = ""), 
              format = "GTiff", overwrite = T, suffix = "names")
}