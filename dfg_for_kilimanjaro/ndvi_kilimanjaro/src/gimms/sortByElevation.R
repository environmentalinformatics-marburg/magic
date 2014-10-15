sortByElevation <- function(plot_names, 
                            plot_shape,
                            val, 
                            id_col = 1, 
                            ...) {
  
  library(dplyr)
  
  the60 <- plot_names
  the12 <- unique(substr(the60, 1, 3))
  
  ele_habs <- plot_shape@data %>%
    group_by(substr(plot_shape$PlotID, 1, 3)) %>%
    summarise(Elevation = mean(Z_DEM_HMP, na.rm = TRUE))
  names(ele_habs) <- c("Habitat", "Elevation")
  ele_habs <- ele_habs[order(ele_habs$Elevation), ]
  ele_habs <- ele_habs[ele_habs$Habitat %in% the12, ]
  
  prcp_mnthly_obs <- val
  prcp_mnthly_obs <- prcp_mnthly_obs[prcp_mnthly_obs[, id_col] %in% the60, ]
  prcp_mnthly_obs$Habitat <- substr(prcp_mnthly_obs[, id_col], 1, 3)
  prcp_mnthly_obs$Habitat <- factor(prcp_mnthly_obs$Habitat,
                                    levels = rev(ele_habs$Habitat))
  val <- prcp_mnthly_obs <- prcp_mnthly_obs[order(prcp_mnthly_obs$Habitat), ]
  val[, id_col] <- factor(val[, id_col], levels = val[, id_col])
  
  return(val)
  
}