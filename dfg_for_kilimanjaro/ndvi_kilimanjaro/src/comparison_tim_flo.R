# KiLi plots
plt <- readOGR(dsn = "data/coords/", layer = "PlotPoles_ARC1960_mod_20140807_final")
plt <- subset(plt, PoleType == "AMP")
plt_wgs <- spTransform(plt, CRS("+init=epsg:21037"))

# Data Tim
fls_tim <- list.files("data/processed/whittaker_myd13q1/myd13_whit_midpoint_julian", 
                      pattern = "^myd13_ndvi_whit", full.names = TRUE)
rst_tim <- stack(fls_tim)
val_tim <- extract(rst_tim, plt_wgs)

# Data Flo
fls_flo <- list.files("data/processed/whittaker_myd13q1/", 
                      pattern = "^SCL_AGGMAX", full.names = TRUE)
fls_flo <- fls_flo[1:length(fls_tim)]
rst_flo <- stack(fls_flo)
val_flo <- extract(rst_flo, plt)

## Comparison

# Cof1
plot(val_tim[1, ], col = "grey65", type = "l")
lines(val_flo[1, ], lty = 2)

# Sav5
plot(val_tim[65, ], col = "grey65", type = "l")
lines(val_flo[65, ], lty = 2)
