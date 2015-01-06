multiVectorHarmonics <- function(rst, 
                                 time_info, 
                                 intervals, 
                                 width,
                                 FUN = sum,
                                 melt_data = TRUE,
                                 ...) {
  
  stopifnot(require(Rsenal))
  
  if (length(width) > 1 & length(width) != length(intervals))
    stop("Arguments 'intervals' and 'width' must be of equal length!")
  
  # Loop through start years (e.g. 2001, 2004, ...)
  ls_harm_sum <- lapply(seq(intervals), function(h) {
    
    # Identify current start and stop year
    year_st <- intervals[h]
    
    if (length(width) == 1) window <- width else window <- width[h]
    year_nd <- year_st + window - 1
    
    # Get RasterLayer indices from supplied time information (format: "%Y%m")
    id_st <- grep(year_st, time_info)[1]
    id_nd <- grep(year_nd, time_info)[length(grep(year_nd, time_info))]
    
    rst_st_nd <- rst[[id_st:id_nd]]
    
    # Summarize active fire pixels per RasterLayer
    val_sum <- sapply(1:nlayers(rst_st_nd), function(i) {
      sum(rst_st_nd[[i]][], na.rm = TRUE)
    })
    
    # Fit harmonic trend model
    harm_sum <- vectorHarmonics(val_sum, st = c(year_st, 1), 
                                nd = c(year_nd, 12), ...)
    harm_sum[harm_sum < 0] <- 0
    
    # Merge time information with calculated values and return
    df_harm_sum <- data.frame(formatC(1:12, width = 2, flag = 0), harm_sum)
    names(df_harm_sum) <- c("month", paste(year_st, year_nd, sep = "-"))
    
    return(df_harm_sum)
  })
  
  # Merge single intervals and return (melted) data
  df_harm_agg <- Reduce(function(...) merge(..., by = "month"), ls_harm_sum)
  
  if (melt_data) {
    stopifnot(require(reshape2))
    mlt_harm_agg <- melt(df_harm_agg, id.vars = 1, variable.name = "interval")
    return(mlt_harm_agg)
  } else {
    return(df_harm_agg)
  }
}