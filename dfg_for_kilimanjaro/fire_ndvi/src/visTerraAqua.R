visTerraAqua <- function(rst,
                         cld = NULL, 
                         vza = NULL, 
                         plot_names, 
                         plot_shape,
                         ...) {
  
  lib <- c("doParallel", "raster", "rgdal", "reshape2", "matrixStats", "ggplot2")
  sapply(lib, function(x) library(x, character.only = TRUE))
  
  source("src/sortByElevation.R")
  
  registerDoParallel(cl <- makeCluster(2))
  
  ### NDVI MOD vs. MYD: plot basis
  ls_val <- foreach(i = rst, j = list("mod14a1", "myd14a1"), .packages = lib, 
                    .export = "sortByElevation") %dopar% {
    mat_val <- extract(i, plot_shape)
    df_val <- data.frame(PlotID = plot_shape@data$PlotID, mat_val)
    names(df_val)[2:ncol(df_val)] <- substr(names(df_val)[2:ncol(df_val)], 5, 11)
    df_val <- sortByElevation(plot_names = plot_names, plot_shape = plot_shape, 
                              val = df_val)
    mlt_val <- melt(df_val, id.vars = c(1, ncol(df_val)), variable.name = "date", 
                    value.name = toupper(j))
    mlt_val$date <- as.Date(mlt_val$date, format = "%Y%j")
    mlt_val[, toupper(j)] <- mlt_val[, toupper(j)] / 10000
    return(mlt_val)
  }
  
  p <- ggplot() + 
    geom_line(aes(x = date, y = MOD14A1), data = ls_val[[1]], color = "black", 
              alpha = .35) + 
    geom_line(aes(x = date, y = MYD14A1), data = ls_val[[2]], color = "grey", 
              alpha = .35) + 
    stat_smooth(aes(x = date, y = MOD14A1), data = ls_val[[1]], method = "lm", 
                color = "black", se = FALSE, lwd = 1, lty = 1) + 
    stat_smooth(aes(x = date, y = MYD14A1), data = ls_val[[2]], method = "lm", 
                color = "grey", se = FALSE, lwd = 1, lty = 1) + 
    facet_wrap(~ PlotID, ncol = 5, scales = "free_y") + 
    scale_x_date(labels = date_format("%Y"), 
                 breaks = date_breaks(width = "4 years"), 
                 minor_breaks = waiver()) +
    labs(x = "Time", y = "NDVI") + 
    theme_bw() + 
    theme(panel.grid = element_blank())
  
  ### Cloud frequency
  if (!is.null(cld)) {
    ls_cld <- foreach(i = cld, .packages = lib, .export = "sortByElevation") %dopar% {
      mat_cld <- extract(i, plot_shape)
      val_cld <- sapply(1:nrow(mat_cld), function(j) {
        val <- sum(is.na(mat_cld[j, ])) / ncol(mat_cld)
        return(round(val, 2))
      })
      df_cld <- data.frame(PlotID = plot_shape@data$PlotID, CLD = val_cld)
      df_cld <- sortByElevation(plot_names = plot_names, 
                                plot_shape = plot_shape, val = df_cld)
      return(df_cld)
    }
    
    p <- p + 
      geom_text(aes(label = paste("CLD:", CLD)), 
                data = ls_cld[[1]],
                x = -Inf, y = -Inf, hjust = -.2, vjust = -.4, size = 2.5)    
 } 

  ### View zenith angles
  if (!is.null(vza)) {
    ls_vza <- foreach(i = vza, .packages = lib, .export = "sortByElevation") %dopar% {
      mat_vza <- extract(i, plot_shape)
      med_vza <- rowMedians(mat_vza, na.rm = TRUE)
      df_vza <- data.frame(PlotID = plot_shape@data$PlotID, VZA = med_vza)
      df_vza <- sortByElevation(plot_names = plot_names, 
                                plot_shape = plot_shape, val = df_vza)
      return(df_vza)
    }
  
    p <- p + 
      geom_text(aes(label = paste("VZA:", VZA)), 
                    data = ls_vza[[1]],
                x = Inf, y = -Inf, hjust = 1.2, vjust = -.4, size = 2.5)    
  }
  
  stopCluster(cl)
  return(p)
  
}