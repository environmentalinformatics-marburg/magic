# Function to split a single RasterLayer or RasterStack object into smaller tiles
splitRaster <- function(file, s = 2) {
  
  filename <- gsub(".tif", "", file)
  gdalinfo_str <- paste("/usr/bin/gdalinfo", file)
  
  # pick size of each side
  x <- as.numeric(gsub("[^0-9]", "", unlist(strsplit(system(gdalinfo_str, intern = TRUE)[3], ", "))))[1]
  y <- as.numeric(gsub("[^0-9]", "", unlist(strsplit(system(gdalinfo_str, intern = TRUE)[3], ", "))))[2]
  
  # t is nr. of iterations per side
  t <- s - 1
  for (i in 0:t) {
    for (j in 0:t) {
      # [-srcwin xoff yoff xsize ysize] src_dataset dst_dataset
      srcwin_str <- paste("-srcwin ", i * x/s, j * y/s, x/s, y/s)
      gdal_str <- paste0("/usr/bin/gdal_translate ", srcwin_str, " ", file, " ", filename, "_", i, "_", j, ".tif")
      system(gdal_str)
    }
  }
}
