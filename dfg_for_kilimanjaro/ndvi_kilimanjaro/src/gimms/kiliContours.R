kiliContours <- function(...) {
  
  source("../../ndvi/src/panel.smoothconts.R")
  
  # dem
  dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")
  dem_flipped <- flip(dem, "y")
  x <- coordinates(dem_flipped)[, 1]
  y <- coordinates(dem_flipped)[, 2]
  z <- dem_flipped[]
  
  levelplot(z ~ x * y, colorkey = FALSE, at = seq(1000, 6000, 1000), 
            panel = function(...) {
              panel.smoothconts(zlevs.conts = seq(1000, 5500, 500), 
                                labels = c(1000, "", 2000, "", 3000, "", 4000, "", 5000, ""), 
                                ...)
            })
  
}