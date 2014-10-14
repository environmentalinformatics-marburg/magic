aggregateGimms <- function(files,
                           start = 4,
                           stop = 8, 
                           fun = max,
                           ...) {

  library(raster)
  
  dates <- substr(basename(files), start, stop)
  indices <- as.numeric(as.factor(dates))
  
  rst <- stack(files)
  rst_agg <- stackApply(rst, indices = indices, fun = fun, ...)
  
  return(rst_agg)
}