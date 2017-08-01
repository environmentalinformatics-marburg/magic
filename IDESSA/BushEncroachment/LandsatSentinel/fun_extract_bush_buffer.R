# bush extraction based on buffered points per pixel
library(raster)
library(rgeos)
library(plyr)

funex <- function(sat, brgb, out){
  
  # calculate buffer size based on satellite data resolution
  widthb <- res(sat)[1] / 2
  sat <- crop(sat, brgb)
  # convert the raster to points and buffer them to square polygons matching the raster resolution
  p <- as(sat, 'SpatialPixels')
  spp <- SpatialPoints(p@coords, proj4string=CRS("+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
  buf <- gBuffer(spp, width = widthb, capStyle = "SQUARE", byid = TRUE)
  
  # function for returning percentage of bush coverage
  f50 <- function(x){
    z <- table(as.vector(x))["50"]
    return(z[[1]]/length(x[[1]]))
  }
  
  # loop over the buffers
  extr <- lapply(seq(buf), function(j){
    # extract satellite data for each buffer
    ex_sat <- extract(sat, buf[j], df = TRUE)
    # extract bush value for each buffer
    ex_lcc <- extract(brgb, buf[j])
    ex_sat$bush_perc <- f50(ex_lcc)
    # index name of the tile for future validation
    ex_sat$bush_class_tile <- names(brgb)
    return(ex_sat)
  })
  # combine to one data frame
  dfb <- do.call(rbind, extr)
  dfb$ID <- NULL
  
  write.csv(dfb, file=paste0(out, paste0("extraction_", brgb@data@names , ".csv")))
}