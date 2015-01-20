rm(list = ls(all = TRUE))

lib <- c("raster", "rgdal", "MODIS", "remote", "doParallel", "reshape2", 
         "ggplot2", "dplyr", "scales", "Rsenal", "Kendall", "RColorBrewer", 
         "latticeExtra", "zoo")
sapply(lib, function(x) library(x, character.only = TRUE))

source("sortByElevation.R")
source("kendallStats.R")
source("downscaleEvaluation.R")

registerDoParallel(cl <- makeCluster(4))

# Temporal range
st <- "200301"
nd <- "201112"

## DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

## GIMMS NDVI3G
fls_gimms <- list.files("data/rst/whittaker", pattern = "_wht_aggmax.tif$", 
                        full.names = TRUE)
fls_gimms <- fls_gimms[grep(st, fls_gimms):grep(nd, fls_gimms)]
rst_gimms <- stack(fls_gimms)
rst_gimms_crp <- crop(rst_gimms, rasterToPolygons(rst_gimms[[1]]))
# rst_gimms_crp <- deseason(rst_gimms_crp)


## MODIS

fls_modis_myd13 <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)
fls_modis_myd13 <- fls_modis_myd13[grep(st, fls_modis_myd13):grep(nd, fls_modis_myd13)]
rst_modis_myd13 <- stack(fls_modis_myd13)
# rst_modis_myd13 <- deseason(rst_modis_myd13)

ls_scores_niter20 <- lapply(1:20, function(n_iter) {
  cat("No. of iteration:", n_iter, "\n")
# ls_scores_niter20 <- foreach(n_iter = 1:20) %do% {
  
  indices <- foreach(i = 1:12, .combine = "c") %do% {
    month_id <- seq(i, nlayers(rst_modis_myd13), 12)
    
    set.seed(i+n_iter)
    train_id <- sort(sample(month_id, 5))
    return(train_id)
  }
  
  fls_out <- c(paste("data/rst/dwnscl_agg1km/gimms_ndvi3g_dwnscl_0311_pureeval", 
                      c("noreduceboth", "reduceboth", "dsn_noreduceboth", "dsn_reduceboth"), 
                      formatC(n_iter, width = 2, flag = "0"), sep = "_"))
#   results_eot <- foreach(i = c(rep(FALSE, 2), rep(TRUE, 2)), j = c(FALSE, TRUE, FALSE, TRUE), 
#                          filename = fls_out, .packages = lib, .export = "downscaleEvaluation") %dopar%
    downscaleEvaluation(rst_pred = rst_modis_myd13, 
                        rst_resp = rst_gimms_crp, 
                        indices_train = indices, 
                        indices_test = (1:nlayers(rst_modis_myd13))[-indices],
                        n_eot = 25,
                        var = .95, 
                        dsn = FALSE, 
                        reduce.both = FALSE, 
                        filename = fls_out[1], overwrite = TRUE,
                        format = "GTiff", bylayer = FALSE)
  
  
  ################################################################################
  ### Model validation ###
  ################################################################################
  
  dsn <- FALSE
  i <- paste("0311_pureeval", "noreduceboth", formatC(n_iter, width = 2, flag = "0"), sep = "_")

#   ls_scores <- 
#   foreach(i = paste("0311_pureeval", c("noreduceboth", "reduceboth", "dsn_noreduceboth", "dsn_reduceboth"), sep = "_"), 
#                        j = c("REDUCE.BOTH = FALSE, DESEASON = FALSE", "REDUCE.BOTH = TRUE, DESEASON = FALSE", 
#                              "REDUCE.BOTH = FALSE, DESEASON = TRUE", "REDUCE.BOTH = TRUE, DESEASON = TRUE"), 
#                        dsn = c(FALSE, FALSE, TRUE, TRUE), .packages = lib) %dopar% {
                         obs_val <- rst_modis_myd13[[(1:nlayers(rst_modis_myd13))[-indices]]]
                         if (dsn) obs_val <- deseason(obs_val)
                         
                         tmp_fls <- list.files("data/rst/dwnscl_agg1km", pattern = i, full.names = TRUE)
                         tmp_rst <- stack(tmp_fls)
                         
                         tmp_val_obs <- getValues(obs_val)
                         tmp_val_prd <- getValues(tmp_rst)
                         
                         tmp_me <- colMeans(tmp_val_prd - tmp_val_obs, na.rm = TRUE)
                         tmp_mae <- colMeans(abs(tmp_val_prd - tmp_val_obs), na.rm = TRUE)
                         tmp_rmse <- sqrt(colMeans((tmp_val_prd - tmp_val_obs)^2, na.rm = TRUE))
                         tmp_r <- diag(cor(tmp_val_prd, tmp_val_obs, use = "complete.obs"))
                         tmp_rsq <- tmp_r^2
                         
                         tmp_scores <- data.frame(type = j, ME = tmp_me, MAE = tmp_mae, 
                                                  RMSE = tmp_rmse, R = tmp_r, Rsq = tmp_rsq)
#                          return(tmp_scores)
#                        }
#   
#   df_scores <- do.call("rbind", ls_scores)
#   return(df_scores)

  return(tmp_scores)
})
df_scores_niter20 <- do.call("rbind", ls_scores_niter20)
write.table(df_scores_niter20, "data/eot_eval_agg1km/scores_niter20.csv", 
          row.names = FALSE, col.names = TRUE, dec = ".", sep = ",")

mlt_scores <- melt(df_scores_niter20, id.vars = "type")

ggplot(aes(x = factor(variable), y = value), data = mlt_scores) + 
  geom_boxplot() + 
  geom_hline(aes(yintercept = 0), colour = "grey65", linetype = "dashed") + 
#   facet_wrap(~ type, ncol = 2) + 
  labs(x = "", y = "") + 
  theme_bw()

colMeans(df_scores_niter20[, 2:6])

# mod_predicted <- stack(list.files(dir_out, pattern = "dwnscl_0812", 
#                                   full.names = TRUE))
# 
# pred_vals <- getValues(mod_predicted)
# obs_vals <- getValues(mod_observed)
# 
# ### error scores
# ME <- colMeans(pred_vals - obs_vals, na.rm = TRUE)
# MAE <- colMeans(abs(pred_vals - obs_vals), na.rm = TRUE)
# RMSE <- sqrt(colMeans((pred_vals - obs_vals)^2, na.rm = TRUE))
# R <- diag(cor(pred_vals, obs_vals, use = "complete.obs"))
# Rsq <- R * R
# 
# 
# ### visualise error scores
# scores <- data.frame(ME, MAE, RMSE, R, Rsq)
# 
# round(colMeans(scores), 3)
# write.csv(round(scores, 3), "data/eot_eval/scores.csv", row.names = FALSE)
# 
# melt_scores <- melt(scores)
# 
# p <- ggplot(melt_scores, aes(factor(variable), value)) 
# p <- p + geom_boxplot() + 
#   theme_bw() + xlab("") + ylab("")
# print(p)

fls_prd <- list.files("data/rst/dwnscl_agg1km", pattern = "0311_pureeval", full.names = TRUE)
rst_prd <- lapply(fls_prd, stack)

cols_div <- colorRampPalette(brewer.pal(11, "RdBu"))
cols_seq <- colorRampPalette(brewer.pal(9, "Blues"))

mod_observed <- rst_modis_myd13[[(1:nlayers(rst_modis_myd13))[-indices]]]

predictions <- foreach(i = rst_prd, j = as.list(fls_prd), 
                       DESEASON = c(TRUE, TRUE, FALSE, FALSE), .packages = lib) %dopar% {
                         
                         
                         if (DESEASON) {
                           proj_old <- projection(mod_observed)
                           mod_observed <- deseason(mod_observed)
                           projection(mod_observed) <- proj_old  
                         }
                         
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
                         
                         mod_predicted <- i
                         mod <- stack(mod_observed, mod_predicted)
                         
                         dir_out <- "data/eot_eval_agg1km/"
                         fls_out <- paste0(dir_out, substr(basename(j), 1, nchar(basename(j))-4))
                         
                         ## r and referring p values
                         mod_r <- calc(mod, fun = function(x) {cor(x[1:48], x[49:96])}, 
                                       filename = paste0(fls_out, "_r"), format = "GTiff", overwrite = TRUE)
                         mod_p <- calc(mod, fun = function(x) {summary(lm(x[1:48] ~ x[49:96]))$coefficients[2, 4]}, 
                                       filename = paste0(fls_out, "_p"), format = "GTiff", overwrite = TRUE)
                         
                         tmp <- mod_r
                         tmp[mod_p[] >= .001] <- NA
                         p_r <- spplot(tmp, at = seq(-1, 1, .25), col.regions = cols_div(100), 
                                       scales = list(draw = TRUE), xlab = "x", ylab = "y")
                         p_rsq <- spplot(tmp^2, at = seq(0, 1, .1), col.regions = cols_seq(100), 
                                         scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                                         sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                                                          list("sp.text", c(285000, 9680000), "Rsq", 
                                                               font = 2, cex = 1.2)))
                         
                         ## lm -> slope
                         mod_obs_sl <- calc(if (DESEASON) mod_observed else deseason(mod_observed), fun = function(x) {
                           model <- lm(x ~ seq(x))
                           p <- summary(model)$coefficients[2, 4]
                           s <- summary(model)$coefficients[2, 1]
                           s[p >= .01 | p <= -.01] <- NA
                           return(s)
                         }, filename = paste0(fls_out, "_slp_obs"), format = "GTiff", overwrite = TRUE)
                         mod_obs_sl <- raster(paste0(fls_out, "_slp_obs.tif"))
                         
                         p_sl_obs <- spplot(mod_obs_sl, scales = list(draw = TRUE), 
                                            sp.layout = list("sp.lines", rasterToContour(dem), col = "grey75"),
                                            col.regions = rev(cols_div(100)), at = seq(-.008, .008, .002))
                         
                         mod_prd_sl <- calc(if (DESEASON) mod_predicted else deseason(mod_predicted), fun = function(x) {
                           model <- lm(x ~ seq(x))
                           p <- summary(model)$coefficients[2, 4]
                           s <- summary(model)$coefficients[2, 1]
                           s[p >= .01 | p <= -.01] <- NA
                           return(s)
                         }, filename = paste0(fls_out, "_slp_prd"), format = "GTiff", overwrite = TRUE)
                         mod_prd_sl <- raster(paste0(fls_out, "_slp_prd.tif"))
                         
                         p_sl_prd <- spplot(mod_prd_sl, scales = list(draw = TRUE), 
                                            sp.layout = list("sp.lines", rasterToContour(dem), col = "grey75"),
                                            col.regions = rev(cols_div(100)), at = seq(-.008, .008, .002))
                         
                         latticeCombineGrid(list(p_sl_obs, p_sl_prd), layout = c(1, 2))
                         
                         ## highly significant mannkendall
                         mod_obs_mk <- calc(if (DESEASON) mod_observed else deseason(mod_observed), fun = function(x) {
                           mk <- MannKendall(x)
                           if (mk$sl <= 1) return(mk$tau) else return(NA)
                         }, filename = paste0(fls_out, "_mk_obs"), format = "GTiff", overwrite = TRUE)
                         mod_obs_mk <- raster(paste0(fls_out, "_mk_obs.tif"))
                         val_obs_mk <- getValues(mod_obs_mk)
                         
                         mod_prd_mk <- calc(if (DESEASON) mod_predicted else deseason(mod_predicted), fun = function(x) {
                           mk <- MannKendall(x)
                           if (mk$sl <= 1) return(mk$tau) else return(NA)
                         }, filename = paste0(fls_out, "_mk_prd"), format = "GTiff", overwrite = TRUE)
                         mod_prd_mk <- raster(paste0(fls_out, "_mk_prd.tif"))
                         val_prd_mk <- getValues(mod_prd_mk)
                         
                         #   # Statistics
                         #   mk_stats <- rbind(kendallStats(mod_obs_mk), kendallStats(mod_prd_mk))
                         #   
                         #   
                         p_mk_obs <- spplot(mod_obs_mk, at = seq(-1, 1, .25), col.regions = rev(cols_div(100)), 
                                            scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                                            sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                                                             list("sp.text", c(347500, 9680000), "MK-OBS", 
                                                                  font = 2, cex = 1.2)))
                         p_mk_prd <- spplot(mod_prd_mk, at = seq(-1, 1, .25), col.regions = rev(cols_div(100)), 
                                            scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                                            sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                                                             list("sp.text", c(347500, 9680000), "MK-PRD", 
                                                                  font = 2, cex = 1.2)))
                         
                         p_mk <- latticeCombineGrid(list(p_mk_obs, p_mk_prd), layout = c(1, 2))
                         #   png("vis/mk_obs_prd.png", width = 20, height = 30, units = "cm", res = 300, pointsize = 15)
                         #   print(p_mk)
                         #   dev.off()
                         #  
                         
                         ## ioa
                         mod_ioa <- calc(mod, fun = function(x) ioa(x[1:48], x[49:96]), 
                                         filename = paste0(fls_out, "_ioa"), format = "GTiff", overwrite = TRUE)
                         
                         #   spplot(mod_ioa, col.regions = rev(cols_div(100)), scales = list(draw = TRUE), 
                         #          sp.layout = list("sp.lines", rasterToContour(dem), col = "grey75"))
                         # bwplot(mod_ioa[])
                         #   
                         # p_ioa <- spplot(mod_ioa, at = seq(0, 1, .125), col.regions = cols_seq(100), 
                         #                 scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                         #                 sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey75"), 
                         #                                  list("sp.text", c(285000, 9680000), "IOA", 
                         #                                       font = 2, cex = 1.2)))
                         # 
                         # p_rsq_ioa <- latticeCombineGrid(list(p_rsq, p_ioa), layout = c(1, 2))
                         # png("vis/rsq_ioa.png", width = 20, height = 30, units = "cm", res = 300, pointsize = 15)
                         # print(p_rsq_ioa)
                         # dev.off()
                         
                         # ## mannkendall scatter plots incl. regression line
                         # mk_pred_val <- sapply(1:nrow(pred_vals), function(i) {
                         #   MannKendall(pred_vals[i, ])$tau
                         # })
                         # 
                         # mk_obs_val <- sapply(1:nrow(obs_vals), function(i) {
                         #   MannKendall(obs_vals[i, ])$tau
                         # })
                         # 
                         # xyplot(mk_pred_val ~ mk_obs_val) + 
                         #   layer(panel.ablineq(lm(y~x)))
                         # 
                         # ## mannkendall boxplots
                         # bwplot(mk_obs_val, xlim = c(-1, 1))
                         # bwplot(mk_pred_val, xlim = c(-1, 1))
                         
                         
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
                         
                         p_plt_obs_prd <- ggplot(aes(x = as.Date(paste0(month, "01"), format = "%Y%m%d"), y = value, 
                                                     group = type, color = type), data = plt_obs_prd_mlt) + 
                           geom_point(aes(color = type), size = 1) + 
                           #     geom_line() + 
                           #     geom_line(aes(color = type), lty = 2, stat = "hline", 
                           #               yintercept = "mean", lwd = .1) + 
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
                         
                         png(paste0("vis/comparison_plots_agg1km_0311_pureeval", basename(fls_out), ".png"), width = 22, 
                             height = 27, units = "cm", res = 300, pointsize = 15)
                         print(p_plt_obs_prd)
                         dev.off()
                         
                         return(list(r = mod_r, p = mod_p, sl_obs = mod_obs_sl, sl_prd = mod_prd_sl, 
                                     mk_obs = mod_obs_mk, mk_prd = mod_prd_mk, ioa = mod_ioa))
                       }

latticeCombineGrid(
  list(
    spplot(predictions[[1]]$sl_obs, col.regions = cols_div(100), at = seq(-.007, .007, .001), 
           sp.layout = list("sp.lines", rasterToContour(dem), col = "grey75")), 
    spplot(predictions[[1]]$sl_prd, col.regions = cols_div(100), at = seq(-.007, .007, .001), 
           sp.layout = list("sp.lines", rasterToContour(dem), col = "grey75"))
  ), layout = c(1, 2))

latticeCombineGrid(
  list(
    spplot(predictions[[1]]$r^2, col.regions = cols_seq(100), at = seq(0, 1, .05), 
           sp.layout = list("sp.lines", rasterToContour(dem), col = "grey75")), 
    spplot(predictions[[1]]$ioa, col.regions = cols_seq(100), at = seq(0.5, 1, .05), 
           sp.layout = list("sp.lines", rasterToContour(dem), col = "grey75"))
  ), layout = c(1, 2))
