setwd("/media/fdetsch/XChange/kilimanjaro/ndvi/")

source("src/processMCD45A1.R")
source("src/processMCD14A1.R")
source("src/aggregateMCD14A1.R")

library(raster)

# Kili extent
template.ext.ll <- extent(37, 37.72, -3.4, -2.84)
template.rst.ll <- raster(ext = template.ext.ll)
template.rst.utm <- projectExtent(template.rst.ll, crs = "+init=epsg:21037")

rst_mcd45a1 <- processMCD45A1(indir = "data/MODIS_ARC/PROCESSED/fire_500m_clrk/", 
                              template = template.rst.utm, 
                              outdir = "data/mcd45a1/", 
                              ranks = 1:4)

rst_mcd14a1 <- processMCD14A1(indir = "data/MODIS_ARC/PROCESSED/fire_clrk/", 
                              template = template.rst.utm, 
                              outdir = "data/md14a1/", 
                              hdfdir = "data/MODIS_ARC/")

rst_mcd14a1_agg8day <- aggregateMCD14A1(st_year = "2001", 
                                        nd_year = "2013", 
                                        n = 8, 
                                        indir = "data/md14a1/", 
                                        outdir = "data/md14a1/aggregated/", 
                                        pattern = "^RCL.*.tif$")