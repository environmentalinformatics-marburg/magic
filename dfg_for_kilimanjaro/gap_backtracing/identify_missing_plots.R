library(gdata)
library(rgdal)

fls_avl_navl <- "/media/permanent/kilimanjaro/gap_control/jn_logger_report.xls"
avl <- read.xls(fls_avl_navl, sheet = "Avl", na.strings = "")
navl <- read.xls(fls_avl_navl, sheet = "Navl", na.strings = "")

# duplicates
anyDuplicated(avl[, 1])
anyDuplicated(navl[, 1])

shp_plt <- readOGR("/media/permanent/kilimanjaro/coordinates/coords", 
                   "PlotPoles_ARC1960_mod_20140807_final")
shp_plt <- subset(shp_plt, PoleType == "AMP")
shp_plt <- subset(shp_plt, PlotID != "gra0")

plt <- toupper(as.character(shp_plt@data[, 1]))
plt_avl <- levels(avl[, 1])
plt_navl <- levels(navl[, 1])

id_missing <- !(plt %in% c(plt_avl, plt_navl))
plt_missing <- plt[id_missing]
plt_missing
