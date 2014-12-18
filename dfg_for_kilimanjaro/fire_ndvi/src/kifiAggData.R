kifiAggData <- function(data, 
                        n = 8, 
                        years = -999,
                        date.col = 1,
                        over.fun = sum, 
                        dsn = ".",
                        out.str = "data",
                        ...) {
  
  # Required packages
  library(raster)
  
  # Loop through single years
  tmp.ts.agg <- lapply(years, function(h) {
    
    if (h == -999) {
      tmp.ts <- data[, date.col]
    } else {
      tmp.ts <- data[grep(h, data[, date.col]), ]
    }
    
    # Aggregate every n layers of each year or whole time span
    tmp.ts.agg <- lapply(seq(1, nrow(tmp.ts), n), function(i) {
      if (length(na.omit(tmp.ts[i:(i+7), 2])) > 0) {
        tmp <- stack(as.character(na.omit(tmp.ts[i:(i+7), 2])))
      } else {
        tmp <- NA
      }
      
      if (class(tmp) != "logical") {
        
        # Aggregation
        time_out <- strftime(tmp.ts[i, date.col], format = "%Y%j")
        file_out <- paste(dsn, "/", out.str, "_", time_out, sep = "")
        overlay(tmp, fun = over.fun, unstack = TRUE, filename = file_out, ...)
      } else {
        NA
      }
    })
    
    return(tmp.ts.agg)
  })
  
  # Return output
  return(tmp.ts.agg)
}

# ### Call
# 
# kifiAggData(data = modis.fire.dly.ts.fls, 
#             years = modis.fire.ts.years[1:2], 
#             over.fun = max, 
#             dsn = "/media/pa_NDown/ki_modis_ndvi/data/overlay/md14a1_agg/", 
#             out.str = "md14a1",
#             format = "GTiff", overwrite = TRUE)