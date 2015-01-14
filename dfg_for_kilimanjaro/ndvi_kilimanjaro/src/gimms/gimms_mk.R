library(rasterVis)
library(Kendall)
library(RColorBrewer)
library(doParallel)

source("../../ndvi/src/visMannKendall.R")

setwd("/media/envin/XChange/kilimanjaro/gimms3g/gimms3g/")

registerDoParallel(cl <- makeCluster(3))

# Temporal range
st <- "200301"
nd <- "201212"

# DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

### GIMMS

# Data import
fls_gimms <- list.files("data/rst/whittaker", pattern = "_crp_utm_wht_aggmax_dsn", 
                        full.names = TRUE)
st_gimms <- grep(st, fls_gimms)[1]
nd_gimms <- grep(nd, fls_gimms)[length(grep(nd, fls_gimms))]
fls_gimms <- fls_gimms[st_gimms:nd_gimms]
rst_gimms <- stack(fls_gimms)

template <- rasterToPolygons(rst_gimms[[1]])
rst_gimms_crp <- crop(rst_gimms, template)

# Kendall's tau
rst_gimms_mk <- calc(rst_gimms_crp, fun = function(...) {
  mk <- MannKendall(...)$tau
  return(mk)
})

rst_gimms_p <- calc(rst_gimms_crp, fun = function(...) {
  p <- MannKendall(...)$sl
  return(p)
})

rst_gimms_mk_p001 <- calc(rst_gimms_crp, fun = function(...) {
  mk <- MannKendall(...)
  sl <- mk$sl
  tau <- mk$tau
  tau[abs(sl) >= .001] <- NA
  return(tau)
})

### MODIS

# Data import
fls_modis <- list.files("data/modis", pattern = "^DSN_SCL_AGGMAX_WHT", 
                        full.names = TRUE)
st_modis <- grep(st, fls_modis)
nd_modis <- grep(nd, fls_modis)
fls_modis <- fls_modis[st_modis:nd_modis]
rst_modis <- stack(fls_modis)

# MODIS pixel extraction per GIMMS pixel, mean and 0.1, 0.5, 0.9 quantile calculation
rst_modis_med <- foreach(i = 1:nlayers(rst_modis), .combine = "stack",
                         .packages = c("raster", "rgdal")) %dopar% {
                           tmp <- rst_gimms_crp[[i]]
                           tmp[] <- NA
                           
                           val <- extract(rst_modis[[i]], template)
                           med <- sapply(val, function(j) median(j, na.rm = TRUE))
                           
                           tmp[] <- med
                           return(tmp)
                         }


### Statistics

# Overall absolute and relative amount of highly significant pixels
nona_abs <- sum(!is.na(rst_gimms_mk_p001[]))
nona_rel <- nona_abs / ncell(rst_gimms_mk_p001)

# Amount of positive significant pixels
nona_pos <- sum(rst_gimms_mk_p001[] > 0, na.rm = TRUE)
nona_pos_rel <- nona_pos / nona_abs

# Amount of negative significant pixels
nona_neg <- sum(rst_gimms_mk_p001[] < 0, na.rm = TRUE)
nona_neg_rel <- nona_neg / nona_abs


### Visualization

p_mk <- foreach(i = list(rst_gimms_crp, rst_modis), j = list("gimms", "modis"),
                .packages = c("raster", "rgdal"), .export = "visMannKendall") %do% {
  p <- visMannKendall(rst = i, 
                      dem = dem, 
                      p_value = .001, 
                      filename = paste0("vis/mk/", j, "_mk001_0313"), 
                      format = "GTiff", overwrite = TRUE)

  return(p)
}

rst_gimms_mk001 <- raster("vis/mk/gimms_mk001_0313.tif")
# p_gimms_mk001 <- visMannKendall(rst = rst_gimms_crp, 
#                                 dem = dem, 
#                                 p_value = .001, col.regions = c("red", "black"),
#                                 at = seq(-1, 1, 1), alpha.regions = .4,
#                                 filename = "vis/mk/gimms_mk001_0313", 
#                                 colorkey = list(draw = FALSE),
#                                 format = "GTiff", overwrite = TRUE)
# 
rst_modis_mk001 <- raster("vis/mk/modis_mk001_0313.tif")
# shp_modis_mk001 <- as(rst_modis_mk001, "SpatialPolygons")
# shp_modis_mk001_sp <- unionSpatialPolygons(shp_modis_mk001, rep(1, length(shp_modis_mk001)))
# shp_modis_mk001_spdf <- as(shp_modis_mk001_sp, "SpatialPolygonsDataFrame")
# 
# p_gimms_mk001_borders <- spplot(shp_modis_mk001_spdf, scales = list(draw = TRUE), 
#                                 xlab = "x", ylab = "y", col.regions = "transparent", 
#                                 at = c(-1, 0, 1))
# 
# p_modis_mk001 <- visMannKendall(rst = rst_modis, 
#                                 dem = dem, 
#                                 p_value = .001, 
#                                 col.regions = c("red", "black"),
#                                 at = seq(-1, 1, 1),
#                                 filename = "vis/mk/modis_mk001_0313", 
#                                 format = "GTiff", overwrite = TRUE)

levelplot(rst_gimms_mk001, colorkey = FALSE, margin = FALSE,
          col.regions = c("red", "black"), alpha.regions = .4, 
          at = seq(-1, 1, 1)) + 
  as.layer(levelplot(rst_modis_mk001, col.regions = c("red", "black"), 
                     at = seq(-1, 1, 1))) + 
  as.layer(contourplot(dem, labels = FALSE, col = "grey65", cuts = 10, lwd = 1.2))


### Statistics (sequel)

# Identic arithmetic sign, MODIS vs. GIMMS
val_modis_mk001 <- extract(rst_modis_mk001, rasterToPolygons(rst_gimms_mk001))
med_modis_mk001 <- sapply(val_modis_mk001, function(i) median(i, na.rm = TRUE))

df_gimms_modis_mk001 <- data.frame(gimms = rst_gimms_mk001[!is.na(rst_gimms_mk001)], 
                                   modis = med_modis_mk001)
sum((df_gimms_modis_mk001$gimms > 0 & df_gimms_modis_mk001$modis > 0) |
      (df_gimms_modis_mk001$gimms < 0 & df_gimms_modis_mk001$modis < 0))

# Number of GIMMS pixels encompassing significant Aqua MODIS pixels
val_modis <- extract(rst_modis_mk001, rasterToPolygons(rst_gimms[[1]]))
med_modis <- sapply(val_modis, function(i) median(i, na.rm = TRUE))
sum(!is.na(med_modis))

stopCluster(cl)