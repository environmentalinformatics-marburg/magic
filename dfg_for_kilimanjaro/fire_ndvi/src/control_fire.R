setwd("/media/envin/XChange/kilimanjaro/ndvi/")

source("src/processMCD45A1.R")
source("src/processMCD14A1.R")
source("src/aggregateMCD14A1.R")

library(raster)

# Kili extent
template.ext.ll <- extent(37, 37.72, -3.4, -2.84)
template.rst.ll <- raster(ext = template.ext.ll)
template.rst.utm <- projectExtent(template.rst.ll, crs = "+init=epsg:21037")

# rst_mcd45a1 <- processMCD45A1(indir = "data/MODIS_ARC/PROCESSED/fire_500m_clrk/", 
#                               template = template.rst.utm, 
#                               outdir = "data/mcd45a1/", 
#                               ranks = 1:4)

rst_mcd14a1 <- lapply(c("low", "nominal", "high"), function(i) {
  processMCD14A1(indir = "data/MODIS_ARC/PROCESSED/fire_clrk/", 
                 exe_crop = ifelse(i == "low", FALSE, TRUE), exe_merge = TRUE,
                 template = template.rst.utm, 
                 outdir = paste0("data/md14a1/", i), 
                 hdfdir = "data/MODIS_ARC/", 
                 confidence = i)
})

for (i in c("low", "nominal", "high"))
  aggregateMCD14A1(st_year = "2001", 
                   nd_year = "2013", 
                   n = "month", 
                   indir = paste0("data/md14a1/", i), 
                   outdir = paste0("data/md14a1/", i, "/aggregated/"), 
                   pattern = "^RCL.*.tif$")