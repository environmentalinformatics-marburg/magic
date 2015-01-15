kendallStats <- function(rst, 
                         ...) {
  
  val <- getValues(rst)
  
  # Overall absolute and relative amount of highly significant GIMMS pixels
  nona_abs <- sum(!is.na(val))
  nona_rel <- nona_abs / ncell(rst)
  
  # Amount of positive significant pixels
  nona_pos <- sum(val > 0, na.rm = TRUE)
  nona_pos_rel <- nona_pos / nona_abs
  
  # Amount of negative significant pixels
  nona_neg <- sum(val < 0, na.rm = TRUE)
  nona_neg_rel <- nona_neg / nona_abs
  
  # Merge statistics
  stats <- data.frame(nona_abs = nona_abs, 
                      nona_rel = nona_rel, 
                      nona_pos = nona_pos, 
                      nona_pos_rel = nona_pos_rel, 
                      nona_neg = nona_neg, 
                      nona_neg_rel = nona_neg_rel)
  
  return(stats)
  
}