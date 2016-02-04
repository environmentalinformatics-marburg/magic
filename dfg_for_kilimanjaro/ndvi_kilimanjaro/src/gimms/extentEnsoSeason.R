extentEnsoSeason <- function(i, ndvi, span = 7, ...) {
  
  # range extension
  if (span > 0) {
    dates <- i$Date
    
    dates_st <- dates[1]
    dates_nd <- dates[length(dates)]
    month(dates_nd) <- month(dates_nd) + span
    
    dates <- seq(dates_st, dates_nd, "month")
    
    if (dates[length(dates)] > ndvi_date[length(ndvi_date)]) {
      id_cut <- grep(ndvi_date[length(ndvi_date)], dates)
      dates <- dates[1:id_cut]
    }
  }
  
  # merge initial seasonal data with extension
  i_ext <- merge(data.frame(Date = dates), i, all = TRUE)
  
  # extract corresponding ndvi and calculate median
  ndvi_id <- which(ndvi_date %in% dates)
  rst_ndvi_sub <- ndvi[[ndvi_id]]
  mat_ndvi_sub <- as.matrix(rst_ndvi_sub)
  
  num_ndvi_sub_median <- apply(mat_ndvi_sub, 2, 
                               function(...) median(..., na.rm = TRUE))
  
  # merge ndvi with extended seasonal data
  i_ext$NDVI <- num_ndvi_sub_median
  i_ext$Month <- as.numeric(substr(i_ext$Date, 6, 7))
  
  # factorize month
  id_month_ext <- is.na(i_ext$Type)
  i_ext$Month[id_month_ext] <- paste0(i_ext$Month[id_month_ext], "a")
  i_ext$Month <- factor(i_ext$Month, levels = i_ext$Month)
  
  return(i_ext)
  
}