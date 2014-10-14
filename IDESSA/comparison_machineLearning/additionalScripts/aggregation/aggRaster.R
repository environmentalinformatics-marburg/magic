#author:Meike Kühnlein
aggRaster <- function(data, 
                      agg.level,
                      write.file = TRUE,
                      days, 
                      path.out,
                      process.incomplete = FALSE,
                      ...) {

  ################################################################################
  ##  
  ##  Parameters are as follows:
  ##  
  ##  data (list):                   List of raster files with each list entry containing
  ##                                 all hourly raster files of one single day.
  ##  agg.level (numeric):           Aggregation level in hours.
  ##  write.file (logical):          Should aggregated raster files be locally stored
  ##                                 (TRUE) or kept in memory (FALSE).
  ##  days (character):              Days with available hourly raster files.
  ##  path.out (character):          Path to output directory.
  ##  process.incomplete (logical) : Should incomplete raster data sets (e.g. two raster
  ##                                 files at agg.level = 3) be processed?
  ##  ...                            Further arguments to be passed.
  ##
  ################################################################################
  
  # Required packages
  library(rgdal)
  
  # Diurnal aggregation
  if (agg.level == 24) {
    
    data.agg <- lapply(seq(data), function(i) {
      if(length(rasters[[i]]) != 1){
        tmp <- stack(data[[i]])
        calc(tmp, fun = sum, na.rm = TRUE, 
             filename = ifelse(write.file, 
                               paste(path.out, days[i], "_24h.rst", sep = ""), 
                               ''), overwrite = TRUE)
      } else if(length(rasters[[i]]) == 1) {
        tmp <- data[[i]]
        #writeRaster(tmp, file=paste(path.out, days[i], "_24h.rst", sep = ""), overwrite = TRUE)
      }


    })
  
  # Aggregation of several hours per day  
  } else {
    
    data.agg <- lapply(seq(data), function(i) {
      
      lapply(seq(1, length(data[[i]]), agg.level), function(j) {
        # Number of rasters per day divisible by agg.level
        if ((j + agg.level - 1) <= length(data[[i]])) {
          tmp <- stack(data[[i]][seq(j, j + agg.level - 1)])
          calc(tmp, fun = sum, na.rm = TRUE, 
               filename = ifelse(write.file, 
                                 paste(path.out, days[i], "_", agg.level, "h_", j, ".rst", sep = ""),
                                 ''), overwrite = TRUE)
        # Number of rasters per day indivisible by agg.level
        } else {
          
          if (process.incomplete) {
            tmp <- stack(data[[i]][seq(j, length(data[[i]]))])
            
            if (nlayers(tmp) > 1) {
              calc(tmp, fun = sum, na.rm = TRUE, 
                   filename = ifelse(write.file, 
                                     paste(path.out, days[i], "_", agg.level, "h_", j, ".rst", sep = ""), 
                                     ''), overwrite = TRUE)
            } else {
              tmp
            }
          }
        }
      })
    })
    
  }
  
  # Return output
  return(data.agg)
  
}