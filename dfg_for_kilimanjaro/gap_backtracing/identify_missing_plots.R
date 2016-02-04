options(stringsAsFactors = FALSE)

# packages
library(gdata)
library(rgdal)

# kili plots
ch_dir_crd <- "/media/permanent/kilimanjaro/coordinates/coords"
ch_fls_crd <- "PlotPoles_ARC1960_mod_20140807_final"

shp_plt <- readOGR(ch_dir_crd, ch_fls_crd)
shp_plt <- subset(shp_plt, PoleType == "AMP")
shp_plt <- subset(shp_plt, PlotID != "gra0")

# information from jimmy on available loggers
fls_avl_navl <- "jn_logger_report.xls"
avl <- read.xls(fls_avl_navl, sheet = "Avl", na.strings = "", )
navl <- read.xls(fls_avl_navl, sheet = "Navl", na.strings = "")

# # duplicates (deprecated as all duplicates have already been removed)
# anyDuplicated(avl[, 1])
# anyDuplicated(navl[, 1])

plt <- toupper(shp_plt@data[, 1])
plt_avl <- avl[, 1]
plt_navl <- navl[, 1]

id_missing <- !(plt %in% c(plt_avl, plt_navl))
plt_missing <- plt[id_missing]
plt_missing
