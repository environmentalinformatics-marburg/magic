# Prepare model dataset (Sentinel and aerial images)

rm(list=ls())
# Set path ---------------------------------------------------------------------
#filepath_base <- "/media/hanna/data/IDESSA_Bush/MODIS/"
filepath_base <- "/media/memory01/casestudies/hmeyer/IDESSA_LandCover/Woody_MODIS/"
path_temp <- paste0(filepath_base,"/tmp/")
path_raster <- paste0(filepath_base,"raster/")
path_rdata <- paste0(filepath_base, "rdata/")
path_source <- "/home/hmeyer/hmeyer/magic/IDESSA/BushEncroachment/AerialImages_MODIS/ProcessMODIS/"


# Libraries --------------------------------------------------------------------
library(doParallel)
library(foreach)
library(raster)
library(rgdal)
library(maptools)
library(mapview)
library(rgeos)

source(paste0(path_source, "functions.R"))

# Additional settings ----------------------------------------------------------
rasterOptions(tmpdir = path_temp)



# Load MODIS data stack --------------------------------------
MODIS <- stack(paste0(path_raster,"MODISstack.tif"))


# Extract samples --------------------------------------------------------------
# Read aerial files (must be same projection as low resolution datasets)
aerial_files <- list.files(paste0(path_raster, "aerial_images_sinu/"),
                           recursive = TRUE, full.names = TRUE, 
                           pattern = glob2rx("*_RECT.tif"))

# Compute extent of all aerial files
polyg_highres <- extentRasterFiles(aerial_files)
saveRDS(polyg_highres, file = paste0(path_rdata, "polyg_highres.rds"))

# Compute extent of low resolution file
polyg_lowres <- raster2Polygon(sen)
saveRDS(polyg_lowres, file = paste0(path_rdata, "polyg_lowres.rds"))

# Crop lowres raster to individual rasters based on polygons and set raster
# values to pixel ID within original lowres raster
lowres_crops <- rasterCrops(rst = sen[[1]], polyg = polyg_highres)
names(lowres_crops) <- aerial_files
lowres_crops <- lowres_crops[grep("NULL", 
                                  sapply(lowres_crops, class), invert = TRUE)]

# Sample n pixel ids from lowres data
lowres_sample_ids <- rasterSample(lowres_crops, n = 444000)
names(lowres_sample_ids) <- names(lowres_crops)

# Extract pixels from highres data based on sample locations in lowres data
aerial_files_extract_sample <- highResExtractSample(
  lowres_raster = sen[[1]], 
  sample_ids = lowres_sample_ids,
  path_highres_results = path_rdata)

# Extract pixels from lowres data based on sample locations in lowres data
lowres_sample_values <- sen[unlist(lowres_sample_ids, recursive = TRUE,
                                   use.names = FALSE)]

saveRDS(lowres_sample_values, file = paste0(path_rdata, "lowres_sample_values.rds"))

