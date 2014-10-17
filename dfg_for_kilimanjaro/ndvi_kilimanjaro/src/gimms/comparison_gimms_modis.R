### Environmental stuff

# Working directory
setwd("/media/fdetsch/XChange/kilimanjaro/gimms3g/gimms3g/")

# Packages
lib <- c("raster", "doParallel", "reshape2", "plyr", "dplyr", "ggplot2", 
         "Rsenal", "scales")
sapply(lib, function(x) library(x, character.only = TRUE))

# Parallelization
registerDoParallel(cl <- makeCluster(3))

# Temporal range
st <- "200301"
nd <- "201212"


### GIMMS

# Data import
fls_gimms <- list.files("data/rst/whittaker", pattern = "_crp_utm_wht_aggmax", 
                        full.names = TRUE)
st_gimms <- grep(st, fls_gimms)[1]
nd_gimms <- grep(nd, fls_gimms)[length(grep(nd, fls_gimms))]
fls_gimms <- fls_gimms[st_gimms:nd_gimms]
rst_gimms <- stack(fls_gimms)

# Date information
dates <- substr(basename(fls_gimms), 4, 9)

# Removal of margin
template <- rasterToPolygons(rst_gimms[[1]])
rst_gimms_crp <- crop(rst_gimms, template)

# Melting
mat_gimms_crp <- getValues(rst_gimms_crp)
df_gimms_crp <- data.frame(cell = 1:nrow(mat_gimms_crp), mat_gimms_crp)
names(df_gimms_crp)[2:ncol(df_gimms_crp)] <- dates
df_gimms_crp_mlt <- melt(df_gimms_crp, id.vars = 1, variable.name = "month", 
                         value.name = "gimms")

### MODIS

# Data import
fls_modis <- list.files("data/modis", pattern = "^SCL_AGGMAX_WHT", 
                        full.names = TRUE)
st_modis <- grep(st, fls_modis)
nd_modis <- grep(nd, fls_modis)
fls_modis <- fls_modis[st_modis:nd_modis]
rst_modis <- stack(fls_modis)

# MODIS pixel extraction per GIMMS pixel and 0.1, 0.5, 0.9 quantile calculation
ls_modis_stats <- foreach(i = 1:nlayers(rst_modis), 
                           .packages = c("raster", "rgdal")) %dopar% {
  val <- extract(rst_modis[[i]], template)
  val_stats <- lapply(val, function(j) {
    matrix(quantile(j, probs = c(.1, .5, .9)), ncol = 3, byrow = TRUE)
  })
  val_stats <- do.call("rbind", val_stats)
  return(val_stats)
}

# Merge 0.1, 0.5, and 0.9 quantile data
ls_modis_stats_mlt <- foreach(g = 1:3, h = c("quan10", "quan50", "quan90")) %do% {
  val <- do.call("cbind", lapply(ls_modis_stats, function(i) {
    i[, g]
  }))
  df_val <- data.frame(cell = 1:nrow(val), val)
  names(df_val)[2:ncol(df_val)] <- dates
  df_val_mlt <- melt(df_val, id.vars = 1, variable.name = "month", 
                     value.name = paste("modis", h, sep = "_"))
  return(df_val_mlt)
}
df_modis_stats_mrg <- Reduce(function(...) merge(..., by = c("cell", "month")), 
                              ls_modis_stats_mlt)

# Merge with corresponding GIMMS data and reformat
df_gimms_modis_stats_mrg <- merge(df_gimms_crp_mlt, df_modis_stats_mrg, 
                                  by = c("cell", "month"))

df_gimms_modis_stats_mrg$cell <- factor(df_gimms_modis_stats_mrg$cell, 
                                         levels = 1:length(unique(df_gimms_modis_stats_mrg$cell)))
df_gimms_modis_stats_mrg$date <- as.Date(paste0(df_gimms_modis_stats_mrg$month, "01"), 
                                          format = "%Y%m%d")

# IOA calculation
df_ioa <- ddply(df_gimms_modis_stats_mrg, .(df_gimms_modis_stats_mrg$cell), 
                summarise, ioa = round(ioa(gimms, modis_quan50), 2))
names(df_ioa)[1] <- "cell"


### Plotting
png("vis/comparison_gimms_modis.png", width = 30, height = 20, units = "cm", 
    res = 300, pointsize = 10)
ggplot(aes(x = date), data = df_gimms_modis_stats_mrg) + 
  geom_ribbon(aes(ymin = modis_quan10, ymax = modis_quan90), 
              fill = "darkolivegreen", alpha = .25) + 
  geom_line(aes(y = modis_quan50), color = "darkolivegreen4", lwd = 1, lty = 1) + 
  geom_line(aes(y = gimms), lwd = 1, color = "grey20") + 
  geom_text(aes(label = paste("IOA:", ioa)), data = df_ioa,
            x = Inf, y = -Inf, hjust = 1.2, vjust = -.4, size = 2.5) +
  facet_wrap(~ cell, ncol = 9) + 
  scale_x_date(labels = date_format("%Y"), breaks = date_breaks("4 years"), 
               minor_breaks = date_breaks("2 years"), 
               limits = as.Date(c("2003-01-01", "2012-12-01"))) + 
  theme_bw() + 
  labs(x = "Time (months)", y = "NDVI")
dev.off()

# Deregister parallel backend
stopCluster(cl)
