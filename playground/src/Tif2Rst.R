Tif2Rst <- function(path.in = ".", 
                    path.out = ".",
                    pattern = NULL, 
                    multiple.bands = FALSE,
                    ...) {
  
 
################################################################################
##  
##  This function is intended for converting GeoTiff (or any other supported 
##  raster format) to IDRISI raster format.
##  
##  Parameters are as follows:
##
##  path.in (character):      Directory containing input files.
##  path.out (character):     Output directory. 
##  pattern (character):      Optional pattern to filter for specific files in 
##                            input directory. See ?regex for further details.
##  multiple.bands (logical): Are the files to be processed multilayered?
##  ...                       Further arguments to be passed.
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

  
  # Required packages
  library(parallel)
  
  
  ### Parallelization
  
  # Number of cores on local machine
  n.cores <- detectCores()
  # Cluster setup
  clstr <- makePSOCKcluster(n.cores)
  
  # Load required packages on cluster
  clusterEvalQ(clstr, library(raster))

  
  ### Data processing
  
  # List of raster files
  fls.tif <- list.files(path = path.in, pattern = pattern)
  
  # Export required objects to cluster
  clusterExport(clstr, c("path.in", "path.out", "fls.tif"), envir = environment())
  
  # Loop through raster files
  parLapply(clstr, seq(fls.tif), function(i) {
    
    # Multilayered file
    if (multiple.bands) {
      # Import multi-channel raster files as RasterStack objects
      tmp.rst <- stack(paste(path.in, fls.tif[i], sep = "/"))
      
      # Export single layers to IDRISI raster files (*.rst)
      writeRaster(tmp.rst, paste(path.out, "/", substr(fls.tif[i], 1, nchar(fls.tif[i]) - 4), sep = ""), 
                  format = "IDRISI", bylayer = TRUE, suffix = "numbers", overwrite = TRUE)
      
    # Singlelayered file  
    } else {
      # Import single-channel raster files as RasterLayer object
      tmp.rst <- raster(paste(path.in, fls.tif[i], sep = "/"))
      
      # Export single layer to IDRISI raster files (*.rst)
      writeRaster(tmp.rst, paste(path.out, "/", substr(fls.tif[i], 1, nchar(fls.tif[i]) - 4), sep = ""), 
                  format = "IDRISI", overwrite = TRUE)
    } 
    
  })

  # Close cluster
  stopCluster(clstr)
  
  print("Files successfully converted to IDRISI raster format!")
  
}


# ### Call
#
# Tif2Rst(path.in = "E:/ki_aster_ndvi/ndvi_mrg", 
#         path.out = "E:/ki_aster_ndvi/ndvi_mrg", 
#         pattern = "ndvi.*tif$", 
#         multiple.bands = FALSE)