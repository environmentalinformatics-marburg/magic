kiliBingImage <- function(projection = "+init=epsg:21037", 
                          ...) {
 
  # package
  lib <- c("raster", "rgdal", "OpenStreetMap")
  jnk <- sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))
  
  # gimms extent
  template <- extent(c(36.99033, 37.74099, -3.415092, -2.83096))
  
  kili.map <- openproj(openmap(upperLeft = c(ymax(template), xmin(template)), 
                               lowerRight = c(ymin(template), xmax(template)), 
                               type = "bing", ...), 
                       projection = projection)
  
  return(kili.map)
}