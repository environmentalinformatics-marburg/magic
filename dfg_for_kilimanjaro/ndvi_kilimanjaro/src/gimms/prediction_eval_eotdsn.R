lib <- c("raster", "rgdal", "MODIS", "remote", "doParallel", "reshape2", 
         "ggplot2", "dplyr", "scales", "Rsenal", "Kendall", "RColorBrewer", 
         "latticeExtra", "zoo")
sapply(lib, function(x) library(x, character.only = TRUE))

source("sortByElevation.R")
source("kendallStats.R")

registerDoParallel(cl <- makeCluster(3))

# Temporal range
st <- "200301"
nd <- "201212"

## DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

## GIMMS NDVI3G
fls_gimms <- list.files("data/rst/whittaker", pattern = "_wht_aggmax.tif$", 
                        full.names = TRUE)
fls_gimms <- fls_gimms[grep(st, fls_gimms):grep(nd, fls_gimms)]
rst_gimms <- stack(fls_gimms)
rst_gimms_crp <- crop(rst_gimms, rasterToPolygons(rst_gimms[[1]]))
rst_gimms_crp <- deseason(rst_gimms_crp)


## MODIS

fls_modis_myd13 <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)
rst_modis_myd13 <- stack(fls_modis_myd13)
rst_modis_myd13 <- deseason(rst_modis_myd13)


### define index for training data
pred_ind <- 1:60

gimms_stck_pred <- rst_gimms_crp[[pred_ind]]
gimms_stck_eval <- rst_gimms_crp[[-pred_ind]]

# ndvi_modes <- foreach(i = c(rst_modis_myd13, rst_modis_max, rst_modis_med, 
#               rst_modis_tmpmax, rst_modis_tmpmed), .packages = lib) %dopar% { 

### create training (pred) and evaluation (eval) sets
mod_stck_pred <- rst_modis_myd13[[pred_ind]]
mod_stck_eval <- rst_modis_myd13[[-pred_ind]]



### calculate EOT
ndvi_modes <- eot(x = gimms_stck_pred, y = mod_stck_pred, n = 10, 
                  standardised = FALSE, reduce.both = TRUE, 
                  verbose = TRUE, write.out = TRUE, path.out = "data/eotdsn_eval")


### calculate number of modes necessary for explaining 95% variance
# nm <- nXplain(ndvi_modes, 0.95)
nm <- 10

### prediction using calculated intercept, slope and GIMMS NDVI values
mod_predicted <- predict(object = ndvi_modes,
                         newdata = gimms_stck_eval,
                         n = nm)

# ### prediction storage
projection(mod_predicted) <- projection(rst_gimms)

dir_out <- "data/rst/dwnscl"
file_out <- paste0(dir_out, "/gimms_ndvi3g_dwnscl_0812_dsn_reduceboth")
mod_predicted <- writeRaster(mod_predicted, filename = file_out, 
                             format = "GTiff", bylayer = FALSE, 
                             overwrite = TRUE)


################################################################################
### Model validation ###
################################################################################

# mod_predicted <- stack(list.files(dir_out, pattern = "dwnscl_0812", 
#                                   full.names = TRUE))

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

round(colMeans(scores), 3)
write.csv(round(scores, 3), "data/eot_eval/scores.csv", row.names = FALSE)

melt_scores <- melt(scores)

p <- ggplot(melt_scores, aes(factor(variable), value)) 
p <- p + geom_boxplot() + 
  theme_bw() + xlab("") + ylab("")
print(p)

# ### pca
# mat_prd <- as.matrix(mod_predicted)
# mat_obs <- as.matrix(mod_observed)
# 
# pca_prd <- prcomp(mat_prd)
# pca_obs <- prcomp(mat_obs)
# 
# mat_prd_pc1 <- predict(pca_prd, mat_prd, index = 1)
# mat_obs_pc1 <- predict(pca_obs, mat_obs, index = 1)
# 
# template_prd <- mod_predicted[[1]]
# template_prd[] <- mat_prd_pc1[, 2]
# plot(template_prd, zlim = c(-1.5, 1.5))
# 
# template_obs <- mod_observed[[1]]
# template_obs[] <- mat_obs_pc1[, 2]
# plot(template_obs, zlim = c(-1.5, 1.5))

# Note: work on non-denoised rasters
# mod_predicted_dns <- denoise(mod_predicted, 3, weighted = FALSE)
# mod_observed_dns <- denoise(mod_observed, 3, weighted = FALSE)
# mod_dns <- stack(mod_observed_dns, mod_predicted_dns)
mod <- stack(mod_observed, mod_predicted)

cols_div <- colorRampPalette(brewer.pal(11, "RdBu"))
cols_seq <- colorRampPalette(brewer.pal(9, "Blues"))

## r and referring p values
mod_r <- calc(mod, fun = function(x) {cor(x[1:60], x[61:120])})
mod_p <- calc(mod, fun = function(x) {summary(lm(x[1:60] ~ x[61:120]))$coefficients[2, 4]})


tmp <- mod_r
tmp[mod_p[] >= .001] <- NA
p_r <- spplot(tmp, at = seq(-1, 1, .25), col.regions = cols_div(100), 
              scales = list(draw = TRUE), xlab = "x", ylab = "y")
p_rsq <- spplot(tmp^2, at = seq(0, 1, .1), col.regions = cols_seq(100), 
                scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                                 list("sp.text", c(285000, 9680000), "Rsq", 
                                      font = 2, cex = 1.2)))

## lm
mod_obs_sl <- calc(mod_observed, fun = function(x) {
  model <- lm(x~seq(x))
  p <- summary(model)$coefficients[2,4]
  s <- summary(model)$coefficients[2,1]
  s[p>=.001|p<=-.001] <- NA
  return(s)
}, filename = "data/eotdsn_eval/mod_obs_dsn_sl_001", format = "GTiff", overwrite = TRUE)
mod_obs_sl <- raster("data/eotdsn_eval/mod_obs_dsn_sl_001.tif")

p_sl_obs <- spplot(mod_obs_sl, scales = list(draw = TRUE), 
                   col.regions = cols_div(100), at = seq(-.006, .006, .001))

mod_prd_sl <- calc(mod_predicted, fun = function(x) {
  model <- lm(x~seq(x))
  p <- summary(model)$coefficients[2,4]
  s <- summary(model)$coefficients[2,1]
  s[p>=.001|p<=-.001] <- NA
  return(s)
}, filename = "data/eotdsn_eval/mod_prd_dsn_sl_001", format = "GTiff", overwrite = TRUE)
mod_prd_sl <- raster("data/eotdsn_eval/mod_prd_dsn_sl_001.tif")

p_sl_prd <- spplot(mod_prd_sl, scales = list(draw = TRUE), 
                   col.regions = cols_div(100), at = seq(-.006, .006, .001))

latticeCombineGrid(list(p_sl_obs, p_sl_prd), layout = c(1, 2))

## highly significant mannkendall
mod_observed_dsn <- deseason(mod_observed)
mod_obs_mk <- calc(mod_observed_dsn, fun = function(x) {
  mk <- MannKendall(x)
  if (mk$sl < .001) return(mk$tau) else return(NA)
}, filename = "data/eotdsn_eval/mod_obs_dsn_mk_001", format = "GTiff", overwrite = TRUE)
mod_obs_mk <- raster("data/eot_eval/mod_obs_dsn_mk_001.tif")
val_obs_mk <- getValues(mod_obs_mk)

mod_predicted_dsn <- deseason(mod_predicted)
mod_prd_mk <- calc(mod_predicted_dsn, fun = function(x) {
  mk <- MannKendall(x)
  if (mk$sl < .001) return(mk$tau) else return(NA)
}, filename = "data/eotdsn_eval/mod_prd_dsn_mk_001", format = "GTiff", overwrite = TRUE)
mod_prd_mk <- raster("data/eot_eval/mod_prd_dsn_mk_001.tif")
val_prd_mk <- getValues(mod_prd_mk)

# Statistics
mk_stats <- rbind(kendallStats(mod_obs_mk), kendallStats(mod_prd_mk))


which(val_obs_mk > 0 )

p_mk_obs <- spplot(mod_obs_mk, at = seq(-1, 1, .25), col.regions = rev(cols(100)), 
                scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                                 list("sp.text", c(347500, 9680000), "MK-OBS", 
                                      font = 2, cex = 1.2)))
p_mk_prd <- spplot(mod_prd_mk, at = seq(-1, 1, .25), col.regions = rev(cols(100)), 
                   scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                   sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                                    list("sp.text", c(347500, 9680000), "MK-PRD", 
                                         font = 2, cex = 1.2)))

p_mk <- latticeCombineGrid(list(p_mk_obs, p_mk_prd), layout = c(1, 2))
png("vis/mk_obs_prd.png", width = 20, height = 30, units = "cm", res = 300, pointsize = 15)
print(p_mk)
dev.off()

## ioa
mod_ioa <- calc(mod, fun = function(x) ioa(x[1:60], x[61:120]))

cols_seq <- colorRampPalette(brewer.pal(9, "Reds"))
p_ioa <- spplot(mod_ioa, at = seq(0, 1, .125), col.regions = rev(cols(100)), 
                scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                                 list("sp.text", c(285000, 9680000), "IOA", 
                                      font = 2, cex = 1.2)))


p_rsq_ioa <- latticeCombineGrid(list(p_rsq, p_ioa), layout = c(1, 2))
png("vis/rsq_ioa.png", width = 20, height = 30, units = "cm", res = 300, pointsize = 15)
print(p_rsq_ioa)
dev.off()

## mannkendall scatter plots incl. regression line
mk_pred_val <- sapply(1:nrow(pred_vals), function(i) {
  MannKendall(pred_vals[i, ])$tau
})

mk_obs_val <- sapply(1:nrow(obs_vals), function(i) {
  MannKendall(obs_vals[i, ])$tau
})

xyplot(mk_pred_val ~ mk_obs_val) + 
  layer(panel.ablineq(lm(y~x)))

## mannkendall boxplots
bwplot(mk_obs_val, xlim = c(-1, 1))
bwplot(mk_pred_val, xlim = c(-1, 1))

### ioa
ioa_val <- sapply(1:nrow(pred_vals), function(i) {
  ioa(pred_vals[i, ], obs_vals[i, ])
})

fls_cf <- list.files("../../ndvi/data/processed/", pattern = "^BF_SD_QA_MYD.*.tif$", 
                     full.names = TRUE)
st <- grep("2003", fls_cf)[1]
nd <- grep("2012", fls_cf)[length(grep("2012", fls_cf))]
fls_cf <- fls_cf[st:nd]
rst_cf <- stack(fls_cf)
dates <- gsub("A", "", sapply(strsplit(basename(fls_cf), "\\."), "[[", 2))
indices <- as.numeric(as.factor(as.yearmon(dates, format = "%Y%j")))
rst_cf_agg <- stackApply(rst_cf, indices = indices, fun = max, na.rm = TRUE)

plot(obs_vals[which.min(ioa_val), ], type = "l", col = "grey65", ylim = c(0, 1))
lines(pred_vals[which.min(ioa_val), ])
lines(as.numeric(rst_cf_agg[which.min(ioa_val)] / 10000), lty = 2)
points(as.numeric(rst_cf_agg[which.min(ioa_val)] / 10000), pch = 20)

points(xyFromCell(mod_stck_eval[[1]], cell = which.min(ioa_val)), cex = 1)

library(lattice)
bwplot(ioa_val)


### visualise plots
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

plt <- readOGR(dsn = "data/coords/", 
               layer = "PlotPoles_ARC1960_mod_20140807_final")
plt <- subset(plt, PoleName == "A middle pole")

col_names <- sapply(strsplit(names(mod_observed), "_"), "[[", 4)

plt_obs <- extract(mod_observed, plt, df = TRUE)
plt_obs$ID <- as.character(plt@data$PlotID)
names(plt_obs)[2:ncol(plt_obs)] <- col_names
plt_obs <- sortByElevation(plot_names = official_plots, 
                           plot_shape = plt, 
                           val = plt_obs)
plt_obs_mlt <- melt(plt_obs, variable.name = "month", value.name = "ndvi_obs")
plt_obs_mlt$month <- as.character(plt_obs_mlt$month)

plt_prd <- extract(mod_predicted, plt, df = TRUE)
plt_prd$ID <- as.character(plt@data$PlotID)
names(plt_prd)[2:ncol(plt_prd)] <- col_names
plt_prd <- sortByElevation(plot_names = official_plots, 
                           plot_shape = plt, 
                           val = plt_prd)
plt_prd_mlt <- melt(plt_prd, variable.name = "month", value.name = "ndvi_prd")
plt_prd_mlt$month <- as.character(plt_prd_mlt$month)

plt_obs_prd <- merge(plt_obs_mlt, plt_prd_mlt, by = c(1, 2, 3))
plt_obs_prd_mlt <- melt(plt_obs_prd, variable.name = "type")

luc <- unique(plt_obs_prd_mlt$Habitat)

png("vis/comparison_obs_prd_08_12.png", width = 22, height = 27, units = "cm", 
    res = 300, pointsize = 15)
ggplot(aes(x = as.Date(paste0(month, "01"), format = "%Y%m%d"), y = value, 
           group = type, color = type), data = plt_obs_prd_mlt) + 
  geom_line() + 
  geom_line(aes(color = type), lty = 2, stat = "hline", 
            yintercept = "mean", lwd = .1) + 
  facet_wrap(~ ID, ncol = 5) + 
  labs(x = "Time (months)", y = "NDVI") + 
  #   scale_linetype_manual("", values = c("ndvi_obs" = 1, "ndvi_prd" = 2), guide = FALSE) + 
  scale_colour_manual("", values = c("ndvi_obs" = "grey75", "ndvi_prd" = "black"), guide = FALSE) + 
  scale_x_date(labels = date_format("%Y"), 
               breaks = date_breaks(width = "2 years"), 
               minor_breaks = waiver()) +
  theme_bw() + 
  theme(axis.text = element_text(size = 8), panel.grid = element_blank(), 
        strip.text = element_text(size = 6, lineheight = .01))
dev.off()

