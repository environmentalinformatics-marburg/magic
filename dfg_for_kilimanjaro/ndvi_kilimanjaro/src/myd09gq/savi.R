savi <- function(red, 
                 nir, 
                 filename = NULL, 
                 ...) {
  
  savi <- 1.5 * (nir-red) / (nir+red+0.5)
  savi <- round(savi, digits = 3)
  
  if (!is.null(filename))
    savi <- writeRaster(savi, filename = filename, ...)

  return(savi)
}