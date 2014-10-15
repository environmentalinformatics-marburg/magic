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
fls_gimms <- fls_gimms[grep(st, fls_gimms):grep(nd, fls_gimms)]
rst_gimms <- stack(fls_gimms)


### MODIS NDVI
fls_modis_myd13 <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)
rst_modis_myd13 <- stack(fls_modis_myd13)

### calculate EOT
ndvi_modes <- eot(x = rst_gimms, y = rst_modis_myd13, n = 10, 
                  standardised = FALSE, reduce.both = FALSE, 
                  verbose = TRUE, write.out = TRUE, path.out = "data/eot")

### calculate number of modes necessary for explaining 98% variance
nm <- nXplain(ndvi_modes, 0.92)

### prediction using claculated intercept, slope and GIMMS NDVI values
mod_predicted <- predict(object = ndvi_modes,
                         newdata = rst_gimms,
                         n = nm)

mod_observed <- rst_modis_myd13
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

col_names <- sapply(strsplit(names(mod_observed), "_"), "[[", 4)

plt_obs <- extract(mod_observed, plt, df = TRUE)
plt_obs$ID <- as.character(plt@data$PlotID)
names(plt_obs)[2:ncol(plt_obs)] <- col_names
plt_obs_mlt <- melt(plt_obs, variable.name = "month", value.name = "ndvi_obs")
plt_obs_mlt$month <- as.character(plt_obs_mlt$month)

plt_prd <- extract(mod_predicted, plt, df = TRUE)
plt_prd$ID <- as.character(plt@data$PlotID)
names(plt_prd)[2:ncol(plt_prd)] <- col_names
plt_prd_mlt <- melt(plt_prd, variable.name = "month", value.name = "ndvi_prd")
plt_prd_mlt$month <- as.character(plt_prd_mlt$month)

plt_obs_prd <- merge(plt_obs_mlt, plt_prd_mlt, by = c(1, 2))
plt_obs_prd_mlt <- melt(plt_obs_prd, variable.name = "type")

luc <- unique(substr(plt_obs_prd_mlt$ID, 1, 3))

# for (i in luc) {
#   df <- plt_obs_prd_mlt %>% filter(substr(ID, 1, 3) == i)
#   p <- ggplot(aes(x = as.Date(paste0(month, "01"), format = "%Y%m%d"), group = type, 
#                   color = type), data = df) + 
#     geom_line(aes(y = value)) + 
#     facet_wrap(~ ID) + 
#     labs(x = "Time (m)", y = "NDVI") + 
#     theme_bw()
#   print(p)
# }

png("vis/comparison_obs_prd.png", width = 22, height = 27, units = "cm", 
    res = 300, pointsize = 15)
ggplot(aes(x = as.Date(paste0(month, "01"), format = "%Y%m%d"), y = value, 
           group = type, color = type), 
       data = plt_obs_prd_mlt) + 
  geom_line() + 
  facet_wrap(~ ID, ncol = 5, scales = "free_y") + 
  labs(x = "Time (months)", y = "NDVI") + 
#   scale_linetype_manual("", values = c("ndvi_obs" = 1, "ndvi_prd" = 2), guide = FALSE) + 
  scale_colour_manual("", values = c("ndvi_obs" = "grey65", "ndvi_prd" = "grey25"), guide = FALSE) + 
  theme_bw() + 
  theme(axis.text = element_text(size = 8), panel.grid = element_blank(), 
        strip.text = element_text(size = 6, lineheight = .01))
dev.off()
