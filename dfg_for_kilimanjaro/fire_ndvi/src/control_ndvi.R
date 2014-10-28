lib <- c("raster", "doParallel")
sapply(lib, function(x) library(x, character.only = TRUE))

registerDoParallel(cl <- makeCluster(2))

source("src/visMannKendall.R")

### DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

### NDVI (2003-2013)
st_year <- "2003"
nd_year <- "2013"

foreach(i = c("mod13q1", "myd13q1"), .packages = lib, 
                  .export = "visMannKendall") %dopar% {

  fls_ndvi <- list.files(paste0("data/processed/whittaker_", i), 
                         pattern = "^WHT.*.tif$", full.names = TRUE)
  
  st <- grep(st_year, fls_ndvi)[1]
  nd <- grep(nd_year, fls_ndvi)[length(grep(nd_year, fls_ndvi))]
  
  fls_ndvi <- fls_ndvi[st:nd]
  rst_ndvi <- stack(fls_ndvi)
  
  png_out <- paste0("out/mk/", i, "_mk01_0313.png")
  png(png_out, units = "mm", width = 300, 
      res = 300, pointsize = 20)
  plot(visMannKendall(rst = rst_ndvi, 
                      dem = dem, 
                      p_value = .01, 
                      filename = paste0("out/mk/", i, "_mk01_0313"), 
                      format = "GTiff", overwrite = TRUE))
  dev.off()
  
  system(paste("convert -trim", png_out, png_out))
}