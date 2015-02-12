library(gdata)
library(rgdal)

switch(Sys.info()[["sysname"]], 
       "Linux" = setwd("/media/permanent/kilimanjaro/gap_control/"), 
       "Windows" = setwd("C:/Permanent/kilimanjaro/gap_control/"))

fls_dk <- "kili_datenkontrolle.xlsx"

plt_dk <- sheetNames(fls_dk)
plt_dk <- plt_dk[grep("COF1", plt_dk):length(plt_dk)]
plt_dk <- tolower(plt_dk)

shp_plt <- readOGR("../coordinates/coords", 
                   "PlotPoles_ARC1960_mod_20140807_final")
shp_plt <- subset(shp_plt, PoleType == "AMP")
shp_plt <- subset(shp_plt, PlotID != "gra0")

missing_id <- !(as.character(shp_plt@data[, 1]) %in% plt_dk)
as.character(shp_plt@data[, 1])[missing_id]
