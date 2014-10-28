visMannKendall <- function(rst, 
                           dem,
                           p_value = NULL, 
                           ...) {
  
  lib <- c("raster", "Kendall", "RColorBrewer")
  sapply(lib, function(x) library(x, character.only = TRUE))
  
  # Mann-Kendall tau
  if (is.null(p_value)) {
    ndvi.mk <- overlay(rst, fun = function(x) MannKendall(x)$tau, ...)
    
  } else {
    # Mann-Kendall tau of significant pixels only
    ndvi.mk <- overlay(rst, fun = function(x) {
      mk <- MannKendall(x)
      if (mk$sl >= p_value) return(NA) else return(mk$tau)
    }, ...)
  }
  
  # Plotting
  spplot(ndvi.mk, scales = list(draw = TRUE), xlab = "x", ylab = "y", 
         col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
         sp.layout = list("sp.lines", rasterToContour(dem), col = "grey50"), 
         par.settings = list(fontsize = list(text = 15)), 
         at = seq(-1, 1, .2))
  
  
}