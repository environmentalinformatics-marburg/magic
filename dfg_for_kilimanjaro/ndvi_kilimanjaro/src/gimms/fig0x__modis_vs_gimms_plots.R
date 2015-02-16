## 1-km gimms
fls_gimms <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_gimms <- stack(fls_gimms)

st <- as.Date("1982-01-01")
nd <- as.Date("2011-12-01")
st_nd <- seq(st, nd, "month")

id_jan03 <- grep("2003-01-01", st_nd)
id_dec11 <- grep("2011-12-01", st_nd)

rst_gimms <- rst_gimms[[id_jan03:id_dec11]]

dates <- st_nd[id_jan03:id_dec11]

## modis
fls_modis_myd13 <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)

id_jan03 <- grep("200301", fls_modis_myd13)
id_dec11 <- grep("201112", fls_modis_myd13)

fls_modis_myd13 <- fls_modis_myd13[id_jan03:id_dec11]
rst_modis_myd13 <- stack(fls_modis_myd13)

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
plt <- subset(plt, PoleType == "AMP")

plt_obs <- extract(rst_modis_myd13, plt, df = TRUE)
plt_obs$ID <- as.character(plt@data$PlotID)
names(plt_obs)[2:ncol(plt_obs)] <- as.character(dates)
plt_obs <- sortByElevation(plot_names = official_plots, 
                           plot_shape = plt, 
                           val = plt_obs)
plt_obs_mlt <- melt(plt_obs, variable.name = "month", value.name = "ndvi_obs")
plt_obs_mlt$month <- as.character(plt_obs_mlt$month)

plt_prd <- extract(rst_gimms, plt, df = TRUE)
plt_prd$ID <- as.character(plt@data$PlotID)
names(plt_prd)[2:ncol(plt_prd)] <- as.character(dates)
plt_prd <- sortByElevation(plot_names = official_plots, 
                           plot_shape = plt, 
                           val = plt_prd)
plt_prd_mlt <- melt(plt_prd, variable.name = "month", value.name = "ndvi_prd")
plt_prd_mlt$month <- as.character(plt_prd_mlt$month)

plt_obs_prd <- merge(plt_obs_mlt, plt_prd_mlt, by = c(1, 2, 3))
plt_obs_prd_mlt <- melt(plt_obs_prd, variable.name = "type")

luc <- unique(plt_obs_prd_mlt$Habitat)

cols_type <- c("grey70", "grey30")
names(cols_type) <- c("ndvi_obs", "ndvi_prd")

p_plt_obs_prd <- ggplot(aes(x = as.Date(month), y = value, group = type, 
                            color = type), data = plt_obs_prd_mlt) + 
  geom_line(alpha = .65) + 
#   geom_line(aes(color = type), lty = 2, stat = "hline", 
#             yintercept = "mean", lwd = .1) + 
  facet_wrap(~ ID, ncol = 5) + 
  labs(x = "\nTime (months)", y = "NDVI\n") + 
  #   scale_linetype_manual("", values = c("ndvi_obs" = 1, "ndvi_prd" = 2), guide = FALSE) + 
  scale_colour_manual("", values = cols_type, guide = FALSE) + 
  scale_x_date(labels = date_format("%Y"), 
               breaks = date_breaks(width = "2 years"), 
               minor_breaks = waiver()) +
  theme_bw() + 
  theme(axis.text = element_text(size = 8), panel.grid = element_blank(), 
        strip.text = element_text(size = 6, lineheight = .01))

png(paste0("vis/comparison_plots_agg1km_0311_all.png"), width = 22, 
    height = 27, units = "cm", res = 300, pointsize = 15)
print(p_plt_obs_prd)
dev.off()
