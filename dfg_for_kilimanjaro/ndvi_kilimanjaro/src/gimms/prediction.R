source("../../ndvi/src/panel.smoothconts.R")

lib <- c("raster", "rgdal", "MODIS", "remote", "doParallel", "reshape2", 
         "ggplot2", "dplyr", "Kendall", "RColorBrewer", "rgeos", "Rsenal", 
         "latticeExtra", "gridExtra")
sapply(lib, function(x) library(x, character.only = TRUE))

registerDoParallel(cl <- makeCluster(3))

source("kendallStats.R")

### DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")
dem_flipped <- flip(dem, "y")
x <- coordinates(dem_flipped)[, 1]
y <- coordinates(dem_flipped)[, 2]
z <- dem_flipped[]

p_dem <- levelplot(z ~ x * y, colorkey = FALSE, at = seq(1000, 6000, 1000), 
                   panel = function(...) {
                     panel.smoothconts(zlevs.conts = seq(1000, 5500, 500), 
                                       labels = c(1000, "", 2000, "", 3000, "", 4000, "", 5000, ""),
                                       col = "grey50", ...)
                   })

# Old and new National Park borders
np_old_utm <- readOGR(dsn = "data/shp", 
                      layer = "fdetsch-kilimanjaro-national-park-1420535670531_epsg21037")
np_old_utm_sl <- as(np_old_utm, "SpatialLines")

np_new_utm <- readOGR(dsn = "data/shp", 
                      layer = "fdetsch-kilimanjaro-new_np-1420532792846_epsg21037")
np_new_utm_sl <- as(np_new_utm, "SpatialLines")

# Temporal range
st <- "200301"
nd <- "201112"

## GIMMS NDVI3G
fls_gimms <- list.files("data/rst/whittaker", pattern = "_wht_aggmax.tif$", 
                        full.names = TRUE)
fls_gimms <- fls_gimms[grep("198201", fls_gimms):grep(nd, fls_gimms)]
rst_gimms <- stack(fls_gimms)
fls_gimms_0311 <- fls_gimms[grep(st, fls_gimms):grep(nd, fls_gimms)]
rst_gimms_0311 <- stack(fls_gimms_0311)


### MODIS NDVI
fls_modis <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)
fls_modis_0311 <- fls_modis[grep(st, fls_modis):grep(nd, fls_modis)]
rst_modis_0311 <- stack(fls_modis_0311)

### calculate EOT
ndvi_modes <- eot(x = rst_gimms_0311, y = rst_modis_0311, n = 25, 
                  standardised = FALSE, reduce.both = FALSE, 
                  verbose = TRUE, write.out = TRUE, path.out = "data/eot")

### calculate number of modes necessary for explaining 98% variance
nm <- nXplain(ndvi_modes, 0.95)

### prediction using claculated intercept, slope and GIMMS NDVI values
mod_predicted <- predict(object = ndvi_modes,
                         newdata = rst_gimms,
                         n = nm)

projection(mod_predicted) <- projection(rst_gimms)

dir_out <- unique(dirname(fls_gimms))
file_out <- paste0(dir_out, "/gimms_ndvi3g_dwnscl_8211")
mod_predicted <- writeRaster(mod_predicted, filename = file_out, 
                             format = "GTiff", bylayer = FALSE, 
                             overwrite = TRUE)

mod_predicted <- stack("data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif")


### trend statistics

## linear trend (slope)

mod_predicted_dsn <- deseason(mod_predicted)
mod_predicted_dsn <- writeRaster(mod_predicted_dsn, bylayer = FALSE,
                                 "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211_dsn", 
                                 format = "GTiff", overwrite = TRUE)

rst_slp <- calc(mod_predicted_dsn, fun = function(x) {
  mod <- lm(x ~ seq(length(x)))
  slp <- coef(mod)[2]
  return(slp)
}, filename = "data/eot_eval_agg1km/lm_slp", format = "GTiff", overwrite = TRUE)


## mann-kendall

file_out <- paste0(file_out, "_mk")
mod_predicted_dsn_mk <- 
  foreach(i = c(1, .05, .01, .001), j = c("", "05", "01", "001")) %do%
  calc(mod_predicted_dsn, fun = function(...) {
    mk <- MannKendall(...)
    sl <- mk$sl
    tau <- mk$tau
    tau[abs(sl) >= i] <- NA
    return(tau)
  }, filename = paste0(file_out, j), format = "GTiff", overwrite = TRUE)

mod_predicted_mk <- list.files("data/rst/whittaker", pattern = "8211_mk.*.tif$", 
                               full.names = TRUE)
mod_predicted_mk <- lapply(mod_predicted_mk, raster)

cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
p_mk <- 
  spplot(mod_predicted_mk[[1]], col.regions = cols_div(100), ylab = "y", 
         at = seq(-.5, .5, .1), scales = list(draw = TRUE), xlab = "x", 
         par.settings = list(fontsize = list(text = 15)),
         sp.layout = list(list("sp.lines", np_old_utm_sl, lwd = 1.6, lty = 2), 
                          list("sp.lines", np_new_utm_sl, lwd = 1.6))) + 
  as.layer(p_dem)

p_mk_envin <- envinmrRasterPlot(p_mk)

png("vis/mk/gimms_mk_8211.png", width = 26, height = 18, units = "cm", 
    pointsize = 15, res = 300)
plot.new()
print(p_mk_envin)
dev.off()

kendallStats(mod_predicted_mk[[4]])

## comparison with pettorelli et al. 2012

# mannkendall raster with p < .05 
rst_mk_001 <- mod_predicted_mk[[4]]
rst_mk_05 <- mod_predicted_mk[[2]]

# reject pixels intersecting np border
id_intersect <- foreach(i =1:ncell(rst_mk_05), .packages = lib, 
                        .combine = "c") %dopar% {
                          rst <- rst_mk_05
                          rst[][-i] <- NA
                          
                          if (all(is.na(rst[]))) {
                            return(FALSE)
                          } else {
                          shp <- rasterToPolygons(rst)
                          return(gIntersects(np_new_utm_sl, shp))
                          }
                        }

rst_mk_05_rmb <- rst_mk_05
rst_mk_05_rmb[id_intersect] <- NA

rst_mk_001_rmb <- rst_mk_001
rst_mk_001_rmb[id_intersect] <- NA

# share of positive and negative trends inside np
val_mk_05_rmb <- extract(rst_mk_05_rmb, np_new_utm)[[1]]
sum(val_mk_05_rmb > 0, na.rm = TRUE) / sum(!is.na(val_mk_05_rmb))
sum(val_mk_05_rmb < 0, na.rm = TRUE) / sum(!is.na(val_mk_05_rmb))

val_mk_001_rmb <- extract(rst_mk_001_rmb, np_new_utm)[[1]]
sum(val_mk_001_rmb > 0, na.rm = TRUE) / sum(!is.na(val_mk_001_rmb))
sum(val_mk_001_rmb < 0, na.rm = TRUE) / sum(!is.na(val_mk_001_rmb))

# share of positive and negative trends outside np
rst_mk_001_rmb_out <- mask(rst_mk_001_rmb, 
                           as(np_new_utm[1, ], "SpatialPolygons"), inverse = TRUE)

sum(rst_mk_001_rmb_out[] > 0, na.rm = TRUE) / sum(!is.na(rst_mk_001_rmb_out[]))
sum(rst_mk_001_rmb_out[] < 0, na.rm = TRUE) / sum(!is.na(rst_mk_001_rmb_out[]))

### visualise plots
plt <- readOGR(dsn = "data/coords/", 
               layer = "PlotPoles_ARC1960_mod_20140807_final")
plt <- subset(plt, PoleName == "A middle pole")

official_plots <- c(paste0("cof", 1:5), 
                    paste0("fed", 1:5),
                    paste0("fer", 0:4), 
                    paste0("flm", c(1:4, 6)), 
                    paste0("foc", 1:5), 
                    paste0("fod", 1:5), 
                    paste0("fpd", 1:5), 
                    paste0("fpo", 1:5), 
                    paste0("gra", c(1:2, 4:6)), 
                    paste0("hel", 1:5), 
                    paste0("hom", 1:5), 
                    paste0("mai", 1:5), 
                    paste0("sav", 1:5))

plt <- subset(plt, PlotID %in% official_plots)

