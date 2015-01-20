ndviPhaseShift <- function(x, y, 
                           z_max, z_min, 
                           rejectLowVariance = FALSE, 
                           varThreshold = .025) {
  val_diff <- x - y
  
  val_xp12 <- x + 12 # add 12 months to 'st' when y >> x 
  val_diff_xp12 <- y - val_xp12
  val_yp12 <- y + 12 # add 12 months to 'nd' when x >> y
  val_diff_yp12 <- val_yp12 - x
  
  id_p6 <- which(val_diff > 6)
  id_m6 <- which(val_diff < (-6))
  id <- which(abs(val_diff) <= 6)
  
  val_diff[id_p6] <- val_diff_yp12[val_diff > 6]
  val_diff[id_m6] <- val_diff_xp12[val_diff < (-6)]
  val_diff[id] <- (y - x)[id]
  
  if (rejectLowVariance) 
    val_diff[abs(z_max) < varThreshold & abs(z_min) < varThreshold] <- NA
  
  return(val_diff)
}