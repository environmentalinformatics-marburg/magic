################################################################################
##  
##  This R script performs several calculations related to ASTER-based NDVI in 
##  the Kilimanjaro research area. Calculations include mean value, standard 
##  deviation and corresponding coefficient of variation for a given moving
##  window. Prior to this, single ASTER tiles of bands V2 (red) and V3N
##  (near-infrared) are optionally being unzipped and merged, and the NDVI is
##  derived from these two bands. Calculated indices are being extracted for
##  each research plot and exported to CSV output file.
##  
################################################################################
##
##  Copyright (C) 2013 Florian Detsch
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##  Please send any comments, suggestions, criticism, or (for our sake) bug
##  reports to admin@environmentalinformatics-marburg.de
##
################################################################################


### Environmental settings

# Workspace clearence
rm(list = ls(all = TRUE))

# Required packages
library(parallel)
library(raster)
library(rgdal)

# Working directory
path.wd <- "E:/ki_aster_ndvi"
setwd(path.wd)

# Paths and files
path.zip <- "zip"
path.unzip <- "unzip"
path.ndvi <- "ndvi"
path.sd <- "sd"
path.sd_mrg <- "sd_mrg"
path.av <- "av"
path.av_mrg <- "av_mrg"
path.out <- "out"

file.coords <- "station_master.csv"


### Settings

# Unzip compressed files?
exe.unzip <- TRUE
# Execute NDVI calculation?
exe.ndvi <- TRUE
# Calculate standard deviation?
exe.sd <- TRUE
# Calculate mean value?
exe.av <- TRUE
# Merge sd images?
exe.sd.mrg <- TRUE
# Merge av images?
exe.av.mrg <- TRUE


### Parallelization

# Number of cores
n.cores <- detectCores()
# Cluster setup
clstr <- makePSOCKcluster(n.cores)


### Plot coordinates

# Import data
data.coords <- read.csv(file.coords, header = TRUE, stringsAsFactors = FALSE)[,c("PlotID", "Lon", "Lat")]
# Reject research plots with missing coordinates
data.coords <- data.coords[complete.cases(data.coords),]
# Reject "jul" research plots
data.coords <- data.coords[-grep("jul", data.coords$PlotID),]

# Set coordinates and coordinate reference system (CRS) of SpatialPointsDataFrame
coordinates(data.coords) <- c("Lon", "Lat")
projection(data.coords) <- CRS("+proj=longlat +datum=WGS84")

# Transform plot coordinates to UTM37S
data.coords.utm <- spTransform(data.coords, 
                               CRS("+proj=utm +zone=37 +south +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"))


### File processing

# Unzip compressed files (optional)
if (exe.unzip) {
  
  # List zip files
  ast14dmo.zip.fls <- list.files(path.zip, pattern = ".zip$", full.names = TRUE)
  
  # Export required variables to cluster
  clusterExport(clstr, c("path.unzip", "ast14dmo.zip.fls"))
  
  # Unzip red (V2) and near-infrared (V3N) ASTER bands from compressed files
  ast14dmo.unzip.fls <- unlist(parLapply(clstr, seq(ast14dmo.zip.fls), function(i) {
    unzip(ast14dmo.zip.fls[i], exdir = path.unzip, overwrite = TRUE, 
          files = c(as.character(unzip(ast14dmo.zip.fls[i], list = TRUE)$Name[grep("V2", unzip(ast14dmo.zip.fls[i], list = TRUE)$Name)]), 
                    as.character(unzip(ast14dmo.zip.fls[i], list = TRUE)$Name[grep("V3N", unzip(ast14dmo.zip.fls[i], list = TRUE)$Name)])))
  }))
  
} else {
  
  # List unzipped files
  ast14dmo.unzip.fls <- list.files(path.unzip, pattern = ".tif$", full.names = TRUE)
  
}

# Extract band information from each file and ...
ast14dmo.unzip.bnds <- unlist(lapply(seq(ast14dmo.unzip.fls), function(i) {
  tmp <- unlist(strsplit(basename(ast14dmo.unzip.fls[i]), "_"))
  substr(tmp[length(tmp)], 1, nchar(tmp[length(tmp)]) - 4)
}))
# ... seperate files with red and near-infrared information
ast14dmo.fls.red <- ast14dmo.unzip.fls[ast14dmo.unzip.bnds %in% "V2"]
ast14dmo.fls.nir <- ast14dmo.unzip.fls[ast14dmo.unzip.bnds %in% "V3N"]

# Filenames for NDVI images
ast14dmo.fls.ndvi <- lapply(seq(ast14dmo.fls.red), function(i) {
  tmp <- unlist(strsplit(basename(ast14dmo.fls.red[i]), "_"))
  paste(path.ndvi, "/", paste(tmp[-length(tmp)], collapse = "_"), "_ndvi.tif", sep = "")
})


### Calculate NDVI for each scene (optional)

if (exe.ndvi) {
  
  # Export required variables and load 'raster' package
  clusterExport(clstr, c("ast14dmo.fls.red", "ast14dmo.fls.nir", "ast14dmo.fls.ndvi"))
  clusterEvalQ(clstr, library(raster))
  
  ast14dmo.ndvi <- parLapply(clstr, seq(ast14dmo.fls.red), function(i) {
    
    # Import ASTER images as RasterLayer objects
    tmp.rst.red <- raster(ast14dmo.fls.red[i]) # Red band
    tmp.rst.nir <- raster(ast14dmo.fls.nir[i]) # NIR band
    
    # Stack red and near-infrared layer
    tmp.stck <- stack(tmp.rst.red, tmp.rst.nir)
    
    # Calculate NDVI
    overlay(tmp.stck, fun = function(x, y) {(y-x)/(y+x)}, 
            filename = ast14dmo.fls.ndvi[[i]], overwrite = TRUE)
  })
  
} else {
  
  # Export required variables and load 'raster' package
  clusterExport(clstr, "ast14dmo.fls.ndvi")
  clusterEvalQ(clstr, library(raster))
  
  ast14dmo.ndvi <- parLapply(clstr, seq(ast14dmo.fls.ndvi), function(i) {
    raster(ast14dmo.fls.ndvi[[i]])
  })
  
}


### Calculation of NDVI standard deviation (sd) and mean value (av) for a given matrix size

# Loop through different moving window sizes
for (z in c(500, 1000, 2000, 3000)) {  
  
  # Filenames for NDVI sd images
  ast14dmo.fls.sd <- lapply(seq(ast14dmo.fls.red), function(i) {
    tmp <- unlist(strsplit(basename(ast14dmo.fls.red[i]), "_"))
    paste(path.sd, "/", paste(tmp[-length(tmp)], collapse = "_"), "_sd_", z, "m.tif", sep = "")
  })
  
  # Filenames for NDVI mean images
  ast14dmo.fls.av <- lapply(seq(ast14dmo.fls.red), function(i) {
    tmp <- unlist(strsplit(basename(ast14dmo.fls.red[i]), "_"))
    paste(path.av, "/", paste(tmp[-length(tmp)], collapse = "_"), "_av_", z, "m.tif", sep = "")
  })
  
  # Export required variables to cluster
  clusterExport(clstr, c("ast14dmo.ndvi", "ast14dmo.fls.sd", "ast14dmo.fls.av", "z"))
  
  # Calculation of standard deviation (optional)
  if (exe.sd) {
    ast14dmo.sd <- parLapply(clstr, seq(ast14dmo.ndvi), function(i) {
      focal(ast14dmo.ndvi[[i]], fun = sd, na.rm = TRUE, 
            w = ifelse(ceiling(z/15) %% 2 != 0, ceiling(z/15), ceiling(z/15) + 1), 
            filename = ast14dmo.fls.sd[[i]], overwrite = TRUE)
    })
  } else {
    ast14dmo.sd <- parLapply(clstr, ast14dmo.fls.sd, function(i) {
      raster(i)
    })
  }
  
  # Calculation of mean value (optional)
  if (exe.av) {
    ast14dmo.av <- parLapply(clstr, seq(ast14dmo.ndvi), function(i) {
      focal(ast14dmo.ndvi[[i]], fun = mean, na.rm = TRUE, 
            w = ifelse(ceiling(z/15) %% 2 != 0, ceiling(z/15), ceiling(z/15) + 1), 
            filename = ast14dmo.fls.av[[i]], overwrite = TRUE)
    })
  } else {
    ast14dmo.av <- parLapply(clstr, ast14dmo.fls.av, function(i) {
      raster(i)
    })      
  }
  
  
  ### Extraction of NDVI CV (sd/av) for each plot
  
  # Merge single sd ASTER scenes
  if (exe.sd.mrg) {
    ast14dmo.sd.mrg <- Reduce(function(...) {
      merge(..., tolerance = 1)
    }, ast14dmo.sd)
    # Export resulting image to file
    writeRaster(ast14dmo.sd.mrg, paste(path.sd_mrg, "/AST14DMO_sd_", z, "m_mrg", sep = ""), format = "GTiff", overwrite = TRUE)
  } else {
    ast14dmo.sd.mrg <- raster(paste(path.sd_mrg, "/AST14DMO_sd_", z, "m_mrg.tif", sep = ""))
  }
  
  # Merge single av ASTER scenes
  if (exe.av.mrg) {
    ast14dmo.av.mrg <- Reduce(function(...) {
      merge(..., tolerance = 1)
    }, ast14dmo.av)
    # Export resulting image to file
    writeRaster(ast14dmo.av.mrg, paste(path.av_mrg, "/AST14DMO_av_", z, "m_mrg", sep = ""), format = "GTiff", overwrite = TRUE)
  } else {
    ast14dmo.av.mrg <- raster(paste(path.av_mrg, "/AST14DMO_av_", z, "m_mrg.tif", sep = ""))
  }
  
  # Calculate CV from sd and av
  ast14dmo.mrg <- overlay(ast14dmo.sd.mrg, ast14dmo.av.mrg, fun = function(x, y) {x/y}, 
                          filename = paste("mrg/AST14DMO", z, "m_mrg", sep = "_"), format = "GTiff", overwrite = TRUE)
  
  # Extract NDVI sd per plot
  data.coords.utm$ndvi_sd <- round(extract(ast14dmo.mrg, data.coords.utm), digits = 3)
  # Write resulting data frame to file
  write.csv(data.frame(data.coords.utm)[,c("PlotID", "ndvi_sd"),], 
            paste(path.out, "/ki_plot_ndvi_cv_", z, "m.csv", sep = ""), row.names = FALSE)
  
}


### Concatenate results for different plot radii

fls.out <- list.files(path.out, pattern = "m.csv$", full.names = TRUE)

tab.out <- lapply(seq(fls.out), function(i) {
  read.csv(fls.out[i], header = TRUE, stringsAsFactors = FALSE)
})

tab.out.1_2 <- merge(tab.out[[1]], tab.out[[2]], by = "PlotID")
tab.out.3_4 <- merge(tab.out[[3]], tab.out[[4]], by = "PlotID")

tab.out <- merge(tab.out.1_2, tab.out.3_4, by = "PlotID")
names(tab.out) <- c("PlotID", "ndvi_sd_1000m", "ndvi_sd_2000m", "ndvi_sd_3000m", "ndvi_sd_500m")

tab.out <- tab.out[c(1,5,2,3,4)]
write.csv(tab.out, paste(path.out, "ki_plot_ndvi_cv.csv", sep = "/"), 
          row.names = FALSE)

# Close cluster
stopCluster(clstr)