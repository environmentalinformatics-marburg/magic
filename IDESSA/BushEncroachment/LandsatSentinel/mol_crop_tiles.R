# crop 1 km tiles in the molopo region

library(raster)
library(rgdal)

# path to the input tiles
datasrc <- "F:/ludwig/input/"

# load sample points
spp <- readOGR("F:/ludwig/sample_points.shp")

for(h in seq(length(spp))){
  print(h)
  # load matching input tile
  cur <- stack(paste0(datasrc, spp[h,]$tile))
  
  # crop the 1 km tile
  tile <- crop(cur, y = c(spp[h,]@coords[1], 
                          spp[h,]@coords[1] + 1000,
                          spp[h,]@coords[2],
                          spp[h,]@coords[2] + 1000))
  
  #### VVI from the Rsenal Package ####
  #### eventually replace with function! ####
  ## separate visible bands
  red <- tile[[1]]
  green <- tile[[2]]
  blue <- tile[[3]]
  
  ## calculate vvi
  vvi <- (1 - abs((red - 30) / (red + 30))) * 
    (1 - abs((green - 50) / (green + 50))) * 
    (1 - abs((blue - 1) / (blue + 1)))
  
  result <- stack(tile, vvi)
  writeRaster(result, paste0("F:/ludwig/tiles_rgb_vvi/rgb_vvi", h, ".tif"),overwrite=TRUE)
  gc()  
  
}

