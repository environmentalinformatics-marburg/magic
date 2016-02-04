visMannKendall <- function(rst, 
#                            dem,
                           p_value = NULL, 
                           sp.layout = NULL,
                           at = seq(-1, 1, .2),
                           col.regions = NULL,
                           alpha.regions = 1,
                           ...) {
  
  lib <- c("raster", "Kendall", "rasterVis", "RColorBrewer")
  sapply(lib, function(x) library(x, character.only = TRUE))
  
  # Colors
  if (is.null(col.regions))
    col.regions <- colorRampPalette(brewer.pal(11, "BrBG"))
  
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
         col.regions = col.regions, 
#          sp.layout = list("sp.lines", rasterToContour(dem), col = "grey50"), 
         par.settings = list(fontsize = list(text = 15)), 
         at = at, alpha.regions = alpha.regions)
  
#   levelplot(ndvi.mk, scales = list(draw = TRUE), xlab = "x", ylab = "y", 
#             col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
#             par.settings = list(fontsize = list(text = 15)), 
#             at = seq(-1, 1, .2), margin = FALSE, 
#             xscale.components = xscale.components.default, 
#             yscale.components = yscale.components.default) + 
#     as.layer(contourplot(dem, at = seq(1000, 5000, 500), 
#                          labels = list(labels = labels, col = "grey75"), 
#                          label.style = "mixed"))
  
}