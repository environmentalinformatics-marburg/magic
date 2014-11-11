lib <- c("raster", "rgdal", "MODIS", "remote", "doParallel", "reshape2", 
         "ggplot2", "dplyr")
sapply(lib, function(x) library(x, character.only = TRUE))

registerDoParallel(cl <- makeCluster(3))

# Temporal range
st <- "200301"
nd <- "201212"

## GIMMS NDVI3G
fls_gimms <- list.files("data/rst/whittaker", pattern = "_wht_aggmax.tif$", 
                        full.names = TRUE)
fls_gimms <- fls_gimms[grep("198201", fls_gimms):length(fls_gimms)]
rst_gimms <- stack(fls_gimms)
fls_gimms_0312 <- fls_gimms[grep(st, fls_gimms):grep(nd, fls_gimms)]
rst_gimms_0312 <- stack(fls_gimms_0312)


### MODIS NDVI
fls_modis_myd13 <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)
rst_modis_myd13 <- stack(fls_modis_myd13)

### calculate EOT
ndvi_modes <- eot(x = rst_gimms_0312, y = rst_modis_myd13, n = 10, 
                  standardised = FALSE, reduce.both = FALSE, 
                  verbose = TRUE, write.out = TRUE, path.out = "data/eot")

### calculate number of modes necessary for explaining 98% variance
nm <- nXplain(ndvi_modes, 0.92)

### prediction using claculated intercept, slope and GIMMS NDVI values
mod_predicted <- predict(object = ndvi_modes,
                         newdata = rst_gimms,
                         n = nm)

projection(mod_predicted) <- projection(rst_gimms)

dir_out <- unique(dirname(fls_gimms))
file_out <- paste0(dir_out, "/gimms_ndvi3g_dwnscl_8212")
mod_predicted <- writeRaster(mod_predicted, filename = file_out, 
                             format = "GTiff", bylayer = FALSE, 
                             overwrite = TRUE)

# mod_predicted <- stack(file_out)

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

