uniqueFiresKendall <- function(template, 
                               cell_id, 
                               time_stamp = NA,
                               rst, 
                               fun = NULL,
                               period = NA,
                               ...) {
  
  # packages
  lib <- c("raster", "rgdal")
  jnk <- sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))
  
  # raster to polygon
  template[] <- NA
  template[cell_id] <- 1
  shp_tmp <- rasterToPolygons(template)  
  
  # mk value extraction
  ls_mk <- extract(rst, shp_tmp, fun = fun, ...)
  val_mk <- if (is.list(ls_mk)) do.call("c", ls_mk) else as.numeric(ls_mk)
  df_mk <- data.frame(period = period, 
                      month = time_stamp, 
                      cell = cell_id, 
                      ndvi_mk = val_mk)
  
  return(df_mk)
}