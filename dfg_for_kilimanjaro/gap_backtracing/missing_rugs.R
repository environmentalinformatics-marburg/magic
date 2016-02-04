# kili plots
ch_dir_crd <- "/media/permanent/kilimanjaro/coordinates/coords"
ch_fls_crd <- "PlotPoles_ARC1960_mod_20140807_final"

shp_plt <- readOGR(ch_dir_crd, ch_fls_crd)
shp_plt <- subset(shp_plt, PoleType == "AMP")
shp_plt <- subset(shp_plt, PlotID != "gra0")

plt <- toupper(shp_plt@data[, 1])

# missing rug loggers on equipped (official) plots
avl_is_official <- avl$PlotID %in% plt

rug_avl <- sapply(1:nrow(avl), function(i) {
  is_rug <- avl[i, 2:4] == "rug"
  any(is_rug, na.rm = TRUE)
})

avl_missing_rug <- avl[!rug_avl & avl_is_official, ]

# missing rug loggers on unequipped (official) plots
navl_is_official <- navl$PlotID %in% plt

rug_navl <- sapply(1:nrow(navl), function(i) {
  is_rug <- navl[i, 2] == "rug"
  any(is_rug, na.rm = TRUE)
})

navl_missing_rug <- navl[rug_navl & navl_is_official, ]

sort(c(avl_missing_rug$PlotID, navl_missing_rug$PlotID))
