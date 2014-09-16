ndvi <- function(red, 
                 nir,
                 filename = NULL,
                 ...) {
  
  ndvi <- (nir-red) / (nir+red)
  ndvi <- round(ndvi, digits = 3)
  
  if (any(ndvi[] > 1, na.rm = TRUE))
    ndvi[ndvi[] > 1] <- 1
  
  if (!is.null(filename))
    ndvi <- writeRaster(ndvi, filename = filename, ...)
  
  return(ndvi)  
}