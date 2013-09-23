### Environmental stuff

# Workspace clearance
rm(list = ls(all = T))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/pa_NDown/ki_modis_ndvi/"}, 
       "Windows" = {path.wd <- "G:/ki_modis_ndvi"})
setwd(path.wd)

# Required packages and functions
lib <- c("raster", "rgdal", "doParallel", "zoo", "Rssa")
sapply(lib, function(...) require(..., character.only = T))

fun <- paste("src", c("gfGapLength.R", "gfNogapLength.R"), sep = "/")
sapply(fun, source)


### Data import

## Geographic extent

kili <- data.frame(x = c(37, 37.72), y = c(-3.4, -2.84), id = c("ll", "ur"))
coordinates(kili) <- c("x", "y")
projection(kili) <- CRS("+init=epsg:4326")
kili <- spTransform(kili, CRS("+init=epsg:32737"))


## NDVI data

# ndvi.rst <- foreach(i = c("NDVI.tif$", "pixel_reliability.tif$"), .packages = lib) %dopar% {
#   # List available files
#   ndvi.fls <- list.files("data/MODIS_ARC/PROCESSED", 
#                          pattern = i, recursive = T, full.names = T)
#   ndvi.fls <- ndvi.fls[order(substr(basename(ndvi.fls), 10, 16))]
#   
#   # Stack and crop files
#   ndvi.rst <- stack(ndvi.fls)
#   return(crop(ndvi.rst, extent(kili)))
# }

# Crop and reproject NDVI data
registerDoParallel(cl <- makeCluster(3))

ndvi.rst <- foreach(i = c("NDVI.tif$", "pixel_reliability.tif$")) %do% {
  tmp.fls <- list.files("data/MODIS_ARC/PROCESSED/md13_tmp/", 
                        pattern = i, recursive = T, full.names = T)
  tmp.fls <- tmp.fls[order(substr(basename(tmp.fls), 10, 16))]

  tmp.rst <- foreach(j = tmp.fls, .packages = lib, .combine = "stack") %dopar% 
    projectRaster(crop(raster(j), extent(37, 37.72, -3.4, -2.84)), 
                  crs = "+init=epsg:32737", method = "ngb", overwrite = T,
                  filename = paste("data/crop/md13q1", basename(j), sep = "/"))
  return(tmp.rst)
}

# Rejection of low quality cells
ndvi.rst_qa <- overlay(ndvi.rst[[1]], ndvi.rst[[2]], fun = function(x, y) {
  x[!y[] %in% c(0:2)] <- NA
  return(x)
})

# Store quality-controlled NDVI data
writeRaster(ndvi.rst_qa, "data/quality_control/QA", format = "GTiff", 
            bylayer = T, suffix = names(ndvi.rst[[1]]), overwrite = T)


### Gap filling

# Convert QA rasters to matrices
ndvi.mat_qa <- foreach(i = unstack(ndvi.rst_qa), .packages = lib) %dopar% {
  as.matrix(i)
}

# rowColFromCell -> for extracting values from matrix
ndvi.row_col <- foreach(i = seq(ncell(ndvi.rst_gf)), .packages = lib) %dopar% {
  rowColFromCell(ndvi.mat_gf[[1]], i)
}

## Small gaps (n <= 3) -> rollmean

# Loop through all cells
ts.rollmean <- foreach(i = seq(ncell(ndvi.rst_qa)), .packages = lib) %dopar% {
  
  # Cell time series from matrices
  tmp.ts <- sapply(ndvi.mat_qa, function(j) j[ndvi.row_col[[i]]])
  
  # Gap lengths
  tmp.pos.na <- which(is.na(tmp.ts))
  
  if (length(tmp.pos.na) > 0) {
    tmp.gaps <- do.call("rbind", gfGapLength(data.dep = tmp.ts, 
                                             pos.na = tmp.pos.na, 
                                             gap.limit = 999, 
                                             end.datetime = Sys.Date()))
    
    # Rollmean
    tmp.ts.rm <- rollapply(data = tmp.ts, width = 11, partial = T, 
                           FUN = function(...) round(mean(..., na.rm = T), 0))
    
    # Sufficiently small gaps
    tmp.small_gaps <- tmp.gaps[which(tmp.gaps[, 3] <= 9), ]
    
    if (nrow(tmp.small_gaps) > 0) {
      tmp.small_gaps <- do.call("c", lapply(seq(nrow(tmp.small_gaps)), function(j) {
        seq(tmp.small_gaps[j, 1], tmp.small_gaps[j, 2])
      }))
      
      # Replace identified gaps with rollmean
      tmp.ts[tmp.small_gaps] <- tmp.ts.rm[tmp.small_gaps]
    }
  }
  
  return(tmp.ts)
}

# Insert calculated values
ndvi.rst_gf9 <- do.call("brick", foreach(i = seq(nlayers(ndvi.rst_qa)), .packages = lib) %dopar% {
  tmp.val <- sapply(ts.rollmean, "[[", i)
  tmp.val.mat <- matrix(tmp.val, nrow = nrow(ndvi.rst_qa[[i]]), 
                        ncol = ncol(ndvi.rst_qa[[i]]), byrow = T)
  
  tmp.rst <- raster(tmp.val.mat, template = ndvi.rst[[1]][[i]])
  return(tmp.rst)
})

# # Store NDVI data filled by rollmean
# writeRaster(ndvi.rst_gf, "data/gap_filled/RM", format = "GTiff", 
#             bylayer = T, suffix = names(ndvi.rst[[1]]))

# # Import NDVI data filled by rollmean
# ndvi.fls_gf <- list.files("data/gap_filled", full.names = T)
# ndvi.fls_gf <- ndvi.fls_gf[order(substr(basename(ndvi.fls_gf), 13, 19))]
# ndvi.rst_gf <- stack(list.files("data/gap_filled", 
#                                 pattern = "RM_", full.names = T))


## Splines

# Convert NDVI raster data to matrices
ndvi.mat_gf3 <- foreach(i = unstack(ndvi.rst_gf3), .packages = lib) %dopar% {
  as.matrix(i)
}

# rowColFromCell -> for extracting values from matrix
ndvi.row_col <- foreach(i = seq(ncell(ndvi.rst_gf3)), .packages = lib) %dopar% {
  rowColFromCell(ndvi.mat_gf3[[1]], i)
}

# Loop through all cells
ts.spline <- foreach(i = seq(ncell(ndvi.rst_gf3)), .packages = lib) %dopar% {
  
  # NDVI cell time series
  tmp.ts <- sapply(ndvi.mat_gf3, function(j) j[ndvi.row_col[[i]]])
  
  # Missing values
  tmp.pos.na <- which(is.na(tmp.ts))
  
  # Fill missing values by spline interpolation
  if (length(tmp.pos.na) > 0)
    tmp.ts[tmp.pos.na] <- na.spline(tmp.ts, maxgap = 12)[tmp.pos.na]
    
  return(tmp.ts)
}

# Insert gap-filled time series in RasterStacks
ndvi.rst_gf3_sp12 <- do.call("stack", 
                           foreach(i = seq(nlayers(ndvi.rst_gf3)), .packages = lib) %dopar% {
  tmp.val <- sapply(ts.spline, "[[", i)
  tmp.val[tmp.val > 10000 | tmp.val < -2000] <- NA
  tmp.val.mat <- matrix(tmp.val, nrow = nrow(ndvi.rst_gf3[[i]]), 
                        ncol = ncol(ndvi.rst_gf3[[i]]), byrow = T)
  
  tmp.rst <- raster(tmp.val.mat, template = ndvi.rst_gf3[[i]])
  return(tmp.rst)
})

# Store gap-filled NDVI data
writeRaster(ndvi.rst.spline, "data/gap_filled/RM_SP", format = "GTiff", 
            overwrite = T, bylayer = T, suffix = names(ndvi.rst[[1]]))


## Longer gaps (n > 3) -> SSA

ts.ssa <- foreach(i = seq(ncell(ndvi.rst.spline)), .packages = lib) %dopar% {
  
  tmp.ts <- sapply(ndvi.mat_gf, function(j) j[ndvi.row_col[[i]]])
  
  # Gap lengths
  tmp.pos.na <- which(is.na(tmp.ts))
  
  if (length(tmp.pos.na) > 0) {
    tmp.gaps <- do.call(function(...) {
      tmp <- rbind(...)
      names(tmp) <- c("start", "end", "span")
      return(tmp)}, gfGapLength(data.dep = tmp.ts, 
                                pos.na = tmp.pos.na, 
                                gap.limit = 999, 
                                end.datetime = Sys.Date()))
    
    while (nrow(tmp.gaps) > 0) {
      
      # Identify lengths of continuous measurements
      tmp.no_gaps <- do.call("rbind", gfNogapLength(gap.lengths = tmp.gaps, 
                                                    data.dep = tmp.ts))
      
      # Deconstruct continuous measurement series
      tmp.ssa <- ssa(tmp.ts[tmp.no_gaps[1, 1]:tmp.no_gaps[1, 2]])
      # Forecast the next gap
      tmp.ts[tmp.gaps[1, 1]:tmp.gaps[1, 2]] <-
        forecast(tmp.ssa, groups = list(seq(nlambda(tmp.ssa))), len = tmp.gaps[1,3])$mean
      
      # Forecast time series 
      tmp.ts.sub <- ts(tmp.ts[tmp.no_gaps[1, 1]:tmp.no_gaps[1, 2]])
      tmp.ts[tmp.gaps[1, 1]:tmp.gaps[1, 2]] <- 
        forecast(tmp.ts.sub, h = tmp.gaps[1, 3])$mean
      
      # Update lengths of measurement gaps
      tmp.pos.na <- which(is.na(tmp.ts))
      if (length(tmp.pos.na) > 0) {
        tmp.gaps <- do.call(function(...) {
          tmp <- rbind(...)
          names(tmp) <- c("start", "end", "span")
          return(tmp)}, gfGapLength(data.dep = tmp.ts,
                                    pos.na = tmp.pos.na, 
                                    gap.limit = 999, 
                                    end.datetime = Sys.Date()))
      } else {
        tmp.gaps <- list()
      }
      
    }
    
#     # Replace gappy by filled time series
#     tmp <- rev(as.numeric(tmp.ki.rev@Parameter[["TEMP"]]))
#     i@Parameter[["TEMP"]] <- as.numeric(tmp)
  }
  
  return(tmp.ts)
  
})

# ## Longer gaps (n > 3) -> cubic spline forecast
# 
# fls.ki.ssa <- lapply(seq(ncell(ndvi.rst.spline)), function(i) {
#   
#   tmp.ts <- sapply(ndvi.mat_gf, function(j) j[ndvi.row_col[[i]]])
#   
#   # Gap lengths
#   tmp.pos.na <- which(is.na(tmp.ts))
#   
#   if (length(tmp.pos.na) > 0) {
#     tmp.gaps <- do.call(function(...) {
#       tmp <- rbind(...)
#       names(tmp) <- c("start", "end", "span")
#       return(tmp)}, gfGapLength(data.dep = tmp.ts, 
#                                 pos.na = tmp.pos.na, 
#                                 gap.limit = 999, 
#                                 end.datetime = Sys.Date()))
#     
#     while (length(tmp.gaps) > 0) {
#       
#       # Identify lengths of continuous measurements
#       tmp.no_gaps <- do.call("rbind", gfNogapLength(gap.lengths = tmp.gaps, 
#                                                     data.dep = tmp.ts))
#       
#       # Forecast the next gap using cubic spline forecasting
#       tmp.ts[tmp.gaps[1, 1]:tmp.gaps[1, 2]] <- 
#         as.numeric(splinef(tmp.ts[tmp.no_gaps[1, 1]:tmp.no_gaps[1, 2]], 
#                            h = tmp.gaps[1, 3])$mean)
#       
#       # Update lengths of measurement gaps
#       tmp.pos.na <- which(is.na(tmp.ts))
#       if (length(tmp.pos.na) > 0) {
#         tmp.gaps <- do.call(function(...) {
#           tmp <- rbind(...)
#           names(tmp) <- c("start", "end", "span")
#           return(tmp)}, gfGapLength(data.dep = tmp.ts,
#                                     pos.na = tmp.pos.na, 
#                                     gap.limit = 999, 
#                                     end.datetime = Sys.Date()))
#       } else {
#         ki.rev.na <- list()
#       }
#       
#     } # end of while loop
#     
#   }
#   
#   return(tmp.ts)
#   
# })
