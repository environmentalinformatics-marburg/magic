setwd("/media/fdetsch/XChange/kilimanjaro/ndvi/data/processed")

library(raster)
library(zoo)

# Outlier-adjusted data
fls_bf <- list.files(pattern = "^BF_SD_QA_MYD13Q1")
rst_bf <- stack(fls_bf)
dates <- gsub("A", "", sapply(strsplit(fls_bf, "\\."), "[[", 2))
indices <- as.numeric(as.factor(as.yearmon(dates, format = "%Y%j")))
rst_bf_agg <- stackApply(rst_bf, indices = indices, fun = max)

# Whittaker data
fls_wt <- list.files("whittaker_myd13q1", pattern = "^SCL_AGGMAX", full.names = TRUE)
rst_wt <- stack(fls_wt)

# Plot data
plt <- readOGR(dsn = "../coords/", 
               layer = "PlotPoles_ARC1960_mod_20140807_final")
plt_apoles <- subset(plt, PoleName == "A middle pole")

# Plot visualization
tmp <- plt_apoles[grep("sav5", plt_apoles$PlotID), ]
val <- extract(rst_bf_agg, tmp)
val_wt <- extract(rst_wt, tmp)

plot(as.numeric(val) / 10000 ~ unique(as.yearmon(dates, format = "%Y%j")), 
     type = "l", col = "grey65", xlab = "Time (months)", ylab = "NDVI")
lines(as.numeric(val_wt) ~ unique(as.yearmon(dates, format = "%Y%j")), lty = 2)
