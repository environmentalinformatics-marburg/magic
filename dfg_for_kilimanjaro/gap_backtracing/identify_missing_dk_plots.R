library(gdata)
library(rgdal)

ch_dir_crd <- "../coordinates/coords"
ch_fls_crd <- "PlotPoles_ARC1960_mod_20140807_final"

ch_fls_dk <- "kili_datenkontrolle.xlsx"

plt_dk <- sheetNames(ch_fls_dk)
plt_dk <- plt_dk[grep("COF1", plt_dk):length(plt_dk)]
plt_dk <- tolower(plt_dk)

shp_plt <- readOGR(dsn = ch_dir_crd, ch_fls_crd, stringsAsFactors = FALSE)
shp_plt <- subset(shp_plt, PoleType == "AMP")
shp_plt <- subset(shp_plt, PlotID != "gra0")

missing_id <- !(shp_plt@data[, 1] %in% plt_dk)
sort(shp_plt@data[missing_id, 1])
