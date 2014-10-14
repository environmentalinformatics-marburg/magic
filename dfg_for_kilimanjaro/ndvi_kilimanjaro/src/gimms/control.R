# Required packages
lib <- c("Rsenal", "doParallel", "MODIS")
sapply(lib, function(x) library(x, character.only = TRUE))

source("aggregateGimms.R")

# Parallelization
registerDoParallel(cl <- makeCluster(3))

# Download GIMMS data from 1980 to 2012
fls_gimms <- downloadGimms(decades = seq(1980, 2010, 10), 
                           dsn = "data")

# Rearrange GIMMS files according to timestamp
fls_gimms <- rearrangeGimms(dsn = "data", 
                            pattern = "^geo",
                            rename_yearmon = TRUE,
                            full.names = TRUE)

# Create .hdr companion file
fls_hdr <- createHdr(file = "gimms3g.hdr")


## Data processing

rst_gimms <- 
  foreach(i = fls_gimms, .packages = c("Rsenal", "zoo"), .combine = "stack", 
          .export = ls(envir = globalenv())) %dopar% {

    # Output name
    file_out <- paste0("data/rst/", basename(i))
    
    # Rasterize
    tmp_rst <- rasterizeGimms(file = i, 
                              headerfile = fls_hdr, 
                              file_out = file_out, 
                              format = "GTiff", overwrite = TRUE)
    
    # Crop
    tmp_rst_crp <- crop(tmp_rst, extent(c(37, 37.72, -3.4, -2.84)), snap = "out", 
                        filename = paste0(file_out, "_crp"), 
                        format = "GTiff", overwrite = TRUE)
    
    # Reproject
    tmp_rst_crp_utm <- projectRaster(tmp_rst_crp, crs = "+init=epsg:21037", 
                                     filename = paste0(file_out, "_crp_utm"), 
                                     format = "GTiff", overwrite = TRUE)
    
    return(tmp_rst_crp_utm)
  }


## Monthly aggregation

# Avl files
fls_gimms <- list.files("data/rst/", pattern = "_crp_utm.tif$", 
                        full.names = TRUE)

# Outnames
fls_out <- paste0(substr(basename(fls_gimms), 1, 9),
                  substr(basename(fls_gimms), 17, (nchar(basename(fls_gimms))-4)), 
                  "_aggmax")
fls_out <- paste0("data/rst/", unique(fls_out))

# Aggregation, `fun = max`
rst_gimms_agg <- aggregateGimms(files = fls_gimms, 
                                start = 4, stop = 9)

# Output storage
ls_gimms_agg <- lapply(seq(nlayers(rst_gimms_agg)), function(i) {
  writeRaster(rst_gimms_agg[[i]], filename = fls_out[i], 
              format = "GTiff", overwrite = TRUE)
})

# fls_gimms_agg <- list.files("data/rst/", pattern = "aggmax.tif$", 
#                             full.names = TRUE)
# ls_gimms_agg <- lapply(fls_gimms_agg, raster)
rst_gimms_agg <- stack(ls_gimms_agg)


## Whittaker smoothing

fls_gimms_agg <- list.files("data/rst/", pattern = "aggmax.tif$", 
                            full.names = TRUE)

# Setup `orgTime` object -> replace %Y%m with %Y%m%d (compatible to `as.Date` in
# `orgTime`)
org_gimms_agg <- basename(fls_gimms_agg)
org_gimms_agg <- sapply(org_gimms_agg, function(i) {
  gsub(substr(i, 4, 9), paste0(substr(i, 4, 9), "01"), i)
})
                           
org_gimms_agg <- orgTime(org_gimms_agg, nDays = "1 month", pillow = 0, 
                         pos1 = 4, pos2 = 11, format = "%Y%m%d")

rst_gimms_wht <- 
  whittaker.raster(fls_gimms_agg, timeInfo = org_gimms_agg, lambda = "6000", 
                   nIter = 3, outDirPath = "data/rst/", groupYears = FALSE, 
                   overwrite = TRUE)

# Save files separately
rst_gimms_wht <- foreach(i = rst_gimms_wht[[1]], j = fls_gimms_agg, 
                         .packages = lib, .combine = "stack") %dopar% {
  file_out <- paste0(substr(j, 1, nchar(j)-4), "_wht")
  writeRaster(i, filename = file_out, format = "GTiff", overwrite = TRUE)
}

# fls_gimms_wht <- list.files("data/rst", pattern = "_wht.tif$", full.names = TRUE)
# rst_gimms_wht <- stack(fls_gimms_wht)

# Deregister parallel backend
stopCluster(cl)