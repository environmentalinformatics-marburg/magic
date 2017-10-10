## set working directory
setwd("D:/work/projects/bale/pub/p3")

## load required libraries
library(raster)
library(mapview)

## plots from 1st field survey
plots = read.csv2("data/Study Plots.csv")
coordinates(plots) = ~ Longitude + Latitude
proj4string(plots) = "+init=epsg:4326"

## settlements
settlements = shapefile("data/settlements.shp")
settlements = subset(settlements, type %in% c("towns", "villages"))

mapview(plots, col.regions = "orange") + settlements
