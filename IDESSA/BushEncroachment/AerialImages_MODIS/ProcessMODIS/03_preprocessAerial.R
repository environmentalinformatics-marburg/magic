# Prepare model dataset (MODIS and aerial images)
rm(list=ls())
# Set path ---------------------------------------------------------------------
#filepath_base <- "/media/hanna/data/IDESSA_Bush/MODIS/"
filepath_base <- "/media/memory01/casestudies/hmeyer/IDESSA_LandCover/Woody_MODIS/"
#datapath <- paste0(filepath_base,"raster/MODIS/")
#auxpath <-paste0(filepath_base,"/auxiliary/")
path_aerial <- "/media/memory01/casestudies/hmeyer/IDESSA_LandCover/AerialImages/"
path_temp <- paste0(filepath_base,"/tmp/")
path_raster <- paste0(filepath_base,"raster/")
path_source <- "/home/hmeyer/magic/IDESSA/BushEncroachment/AerialImages_MODIS/ProcessMODIS/"

dir.create(paste0(path_raster, "aerial_images_sinu/"))
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
#MODIS <- stack(paste0(path_raster,"MODISstack.tif"))


# Pre-process high resolution aerial raster data -------------------------------
aerial_prj <- CRS("+proj=tmerc +lat_0=0 +lon_0=23 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0")

# Reproject aerial files to satellite projection (if necessary)
aerial_files <- list.files(path_aerial,
                           recursive = TRUE, full.names = TRUE, 
                           pattern = glob2rx("*_RECT.tif"))


warpRaster(files = aerial_files, source_prj = aerial_prj, 
           target_prj = "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs", 
           outpath = paste0(path_raster, "aerial_images_sinu/"),
           resampling = "near")

