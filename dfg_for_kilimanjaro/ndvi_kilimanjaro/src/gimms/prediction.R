lib <- c("raster", "rgdal", "MODIS", "remote", "doParallel", "reshape2", "ggplot2")
sapply(lib, function(x) library(x, character.only = TRUE))

registerDoParallel(cl <- makeCluster(3))

# Temporal range
st <- "200301"
nd <- "201212"

## GIMMS

fls_gimms <- list.files("data/rst/", pattern = "_wht.tif$", full.names = TRUE)
fls_gimms <- fls_gimms[grep(st, fls_gimms):grep(nd, fls_gimms)]
rst_gimms <- stack(fls_gimms)


## MODIS

# MYD09GQ 
# with stateCheck(c(1, 0, 1, 1, 1, 1)) based on MYD09GA
fls_modis_max <- list.files("../../evapotranspiration/myd09gq/processed/max", 
                            pattern = "^NDVI_FixedLambda6000_20", full.names = TRUE)
fls_modis_max <- fls_modis_max[grep(st, fls_modis_max):grep(nd, fls_modis_max)]
rst_modis_max <- stack(fls_modis_max)

fls_modis_med <- list.files("../../evapotranspiration/myd09gq/processed/median", 
                            pattern = "^NDVI_FixedLambda6000_20", full.names = TRUE)
fls_modis_med <- fls_modis_med[grep(st, fls_modis_med):grep(nd, fls_modis_med)]
rst_modis_med <- stack(fls_modis_med)

# stateCheck(c(1, 0, 0, 1, 0, 1))
fls_modis_tmpmax <- 
  list.files("../../evapotranspiration/myd09gq/tmp/processed/max", 
             pattern = "^NDVI_FixedLambda6000_20", full.names = TRUE)
fls_modis_tmpmax <- fls_modis_tmpmax[grep(st, fls_modis_tmpmax):grep(nd, fls_modis_tmpmax)]
rst_modis_tmpmax <- stack(fls_modis_tmpmax)

fls_modis_tmpmed <- 
  list.files("../../evapotranspiration/myd09gq/tmp/processed/max", 
             pattern = "^NDVI_FixedLambda6000_20", full.names = TRUE)
fls_modis_tmpmed <- fls_modis_tmpmed[grep(st, fls_modis_tmpmed):grep(nd, fls_modis_tmpmed)]
rst_modis_tmpmed <- stack(fls_modis_tmpmed)

# MYD13Q1 (Flo)
fls_modis_myd13 <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)
rst_modis_myd13 <- stack(fls_modis_myd13)

# # MYD13Q1 (Tim)
# fls_motim_myd13 <- list.files("../../ndvi/data/processed/whittaker_myd13q1/myd13_whit_midpoint_julian", 
#                               pattern = "^myd13_ndvi_whit.*.tif$", full.names = TRUE)
# rst_motim_myd13 <- stack(fls_motim_myd13)
# rst_motim_myd13_prj <- 
#   projectRaster(rst_motim_myd13, crs = CRS("+init=epsg:21037"), 
#                 filename = paste0(unique(dirname(fls_motim_myd13)), "/rpj"), 
#                 format = "GTiff", bylayer = TRUE, suffix = basename(fls_motim_myd13), 
#                 overwrite = TRUE)

# load("gimmsKiliNDVI.RData")
# rst_gimms <- gimmsKiliNDVI
# load("modisKiliNDVI.RData")
# rst_modis <- modisKiliNDVI

### define index for training data
pred_ind <- 1:60

gimms_stck_pred <- rst_gimms[[pred_ind]]
gimms_stck_eval <- rst_gimms[[-pred_ind]]

# ndvi_modes <- foreach(i = c(rst_modis_myd13, rst_modis_max, rst_modis_med, 
#               rst_modis_tmpmax, rst_modis_tmpmed), .packages = lib) %dopar% { 

### create training (pred) and evaluation (eval) sets
mod_stck_pred <- rst_modis_myd13[[pred_ind]]
mod_stck_eval <- rst_modis_myd13[[-pred_ind]]

### calculate EOT
ndvi_modes <- eot(x = gimms_stck_pred, y = mod_stck_pred, n = 10, 
                  standardised = FALSE, reduce.both = FALSE, 
                  verbose = TRUE, write.out = TRUE, path.out = "eot")

#   return(ndvi_modes)
# }

# plot(ndvi_modes[[5]])


### calculate number of modes necessary for explaining 98% variance
nm <- nXplain(ndvi_modes, 0.9)

### prediction using claculated intercept, slope and GIMMS NDVI values
mod_predicted <- predict(object = ndvi_modes,
                         newdata = gimms_stck_eval,
                         n = nm)

mod_observed <- mod_stck_eval
pred_vals <- getValues(mod_predicted)
obs_vals <- getValues(mod_observed)

### error scores
ME <- colMeans(pred_vals - obs_vals, na.rm = TRUE)
MAE <- colMeans(abs(pred_vals - obs_vals), na.rm = TRUE)
RMSE <- sqrt(colMeans((pred_vals - obs_vals)^2, na.rm = TRUE))
R <- diag(cor(pred_vals, obs_vals, use = "complete.obs"))
Rsq <- R * R


### visualise error scores
scores <- data.frame(ME, MAE, RMSE, R, Rsq)
melt_scores <- melt(scores)

p <- ggplot(melt_scores, aes(factor(variable), value)) 
p <- p + geom_boxplot() + 
  theme_bw() + xlab("") + ylab("")
print(p)


### visualise plots
plt <- readOGR(dsn = "data/coords/", 
               layer = "PlotPoles_ARC1960_mod_20140807_final")
plt_apoles <- subset(plt, PoleName == "A middle pole")

col_names <- sapply(strsplit(names(mod_observed), "_"), "[[", 4)

plt_obs <- extract(mod_observed, plt_apoles, df = TRUE)
plt_obs$ID <- as.character(plt_apoles@data$PlotID)
names(plt_obs)[2:ncol(plt_obs)] <- col_names
plt_obs_mlt <- melt(plt_obs, variable.name = "month", value.name = "ndvi_obs")
plt_obs_mlt$month <- as.character(plt_obs_mlt$month)

plt_prd <- extract(mod_predicted, plt_apoles, df = TRUE)
plt_prd$ID <- as.character(plt_apoles@data$PlotID)
names(plt_prd)[2:ncol(plt_prd)] <- col_names
plt_prd_mlt <- melt(plt_prd, variable.name = "month", value.name = "ndvi_prd")
plt_prd_mlt$month <- as.character(plt_prd_mlt$month)

plt_obs_prd <- merge(plt_obs_mlt, plt_prd_mlt, by = c(1, 2))
plt_obs_prd_mlt <- melt(plt_obs_prd, variable.name = "type")

luc <- unique(substr(plt_obs_prd_mlt$ID, 1, 3))

for (i in luc) {
  df <- plt_obs_prd_mlt %>% filter(substr(ID, 1, 3) == i)
  p <- ggplot(aes(x = as.Date(paste0(month, "01"), format = "%Y%m%d"), group = type, 
                  color = type), data = df) + 
    geom_line(aes(y = value)) + 
    facet_wrap(~ ID) + 
    labs(x = "Time (m)", y = "NDVI") + 
    theme_bw()
  print(p)
}
