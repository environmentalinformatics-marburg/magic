### environmental stuff -----

## packages
library(Rsenal)
library(grid)
library(rasterVis)

## functions
source("R/ndviPhaseShift.R")


### data processing -----

ssn <- vector("list", 3); n <- 1

for (area in c("alb", "hai", "sch")) {
  
  # gimms seasonality
  fls_st <- list.files("out/harmonics", full.names = TRUE, 
                       pattern = paste("^MCD13Q1", area, "st", sep = ".*"))
  rst_st <- stack(fls_st)

  fls_nd <- list.files("out/harmonics", full.names = TRUE, 
                       pattern = paste("^MCD13Q1", area, "nd", sep = ".*"))
  rst_nd <- stack(fls_nd)
  
  # Start variance (maximum - minimum)
  st_diff_max_min <- rst_st[[2]] - rst_st[[4]]
  
  # End variance (maximum - minimum)
  nd_diff_max_min <- rst_nd[[2]] - rst_nd[[4]]
  
  # Shift in maximum NDVI
  diff_max_y <- overlay(rst_st[[2]], rst_nd[[2]], fun = function(x, y) {
    return(y - x)
  })
  
  # Shift in minimum NDVI
  diff_min_y <- overlay(rst_st[[4]], rst_nd[[4]], fun = function(x, y) {
    return(y - x)
  })
  
  # Shift in months regarding NDVI maximum
  diff_max_x <- overlay(rst_st[[1]], rst_nd[[1]], 
                        st_diff_max_min, nd_diff_max_min,
                        fun = function(x, y, z_max, z_min) 
                          ndviPhaseShift(x, y, z_max, z_min, 
                                         rejectLowVariance = TRUE, 
                                         varThreshold = .04))
  
  # Shift in months regarding NDVI minimum
  diff_min_x <- overlay(rst_st[[3]], rst_nd[[3]], 
                        st_diff_max_min, nd_diff_max_min, 
                        fun = function(x, y, z_max, z_min) 
                          ndviPhaseShift(x, y, z_max, z_min, 
                                         rejectLowVariance = TRUE, 
                                         varThreshold = .04))
  
  rst_diff <- list(diff_max_x, diff_max_y, diff_min_x, diff_min_y)

  # diff month max
  rcl_mat <- matrix(c(-7.5, -.5, -1, 
                      .5, 7.5, 1), ncol = 3, byrow = TRUE)
  rst_diff_month_rcl <- reclassify(rst_diff[[1]], rcl_mat)
  rst_diff_month_rcl[rst_diff_month_rcl[] > -.5 & rst_diff_month_rcl[] < .5] <- 0
  
  rat_diff_month_rcl <- ratify(rst_diff_month_rcl)
  rat <- levels(rat_diff_month_rcl)[[1]]
  lvl <- unlist(rat)
  rat$month <- c(if (-1 %in% lvl) "-", 
                 if (0 %in% lvl) "0", 
                 if (1 %in% lvl) "+")
  levels(rat_diff_month_rcl) <- rat
  
  p_diff_max_x <- levelplot(rat_diff_month_rcl, col.regions = rev(brewer.pal(9, "RdBu")), 
                            at = -1.5:1.5, scales = list(draw = TRUE, cex = .7), 
                            xlab = "Longitude", ylab = "Latitude")
  
  p_diff_max_x <- spplot(rst_diff_month_rcl, col.regions = rev(brewer.pal(9, "RdBu")), 
                         at = -1.5:1.5, scales = list(draw = TRUE, cex = .7), 
                         colorkey = FALSE, main = list(area, cex = 1.4),
                         maxpixels = ncell(rst_diff_month_rcl),
                         # xlab = "Longitude", ylab = "Latitude", 
                         sp.layout = list("sp.text", loc = c(37.04, -3.36), 
                                          txt = "c)", font = 2, cex = .75))
  
  # diff ndvi max
  cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
  p_diff_max_y <- spplot(rst_diff[[2]], col.regions = cols_div(20), 
                         maxpixels = ncell(rst_diff[[2]]),
                         at = seq(-.07, .07, .01), scales = list(draw = TRUE), 
                         # xlab = "Longitude", ylab = "Latitude", 
                         sp.layout = list("sp.text", loc = c(37.04, -3.36), 
                                          txt = "d)", font = 2, cex = .75))
  
  ssn[[n]] <- list(p_diff_max_x, p_diff_max_y)
  n <- n + 1
  
  # p_comb <- latticeCombineGrid(list(p_diff_max_x, 
  #                                   p_diff_max_y), layout = c(2, 1))
  # 
  # ## manuscript version
  # png(paste0(ch_dir_data, "out/seasonality.png"), width = 20, 
  #     height = 12, units = "cm", res = 500)
  # plot.new()
  # 
  # vp0 <- viewport(x = 0, y = .05, width = 1, height = .95, 
  #                 just = c("left", "bottom"), name = "figure.vp")
  # pushViewport(vp0)
  # print(p_comb, newpage = FALSE)
  # 
  # ## colorkey: seasonal shift
  # vp1 <- viewport(x = .275, y = .065,
  #                 height = 0.07, width = .3,
  #                 just = c("center", "bottom"),
  #                 name = "key1.vp")
  # pushViewport(vp1)
  # draw.colorkey(key = list(col = rev(brewer.pal(9, "RdBu")), width = 1, height = .5,
  #                          at = seq(-1.5, 1.5, 1), 
  #                          labels = list(labels = c("-", "0", "+"), at = c(-1, 0, 1)), 
  #                          space = "bottom"), draw = TRUE)
  # grid.text("Seasonal shift", x = 0.5, y = -.1, just = c("centre", "top"), 
  #           gp = gpar(font = 2, cex = .85))
  # 
  # ## colorkey: Delta NDVI_EOTmax
  # upViewport()
  # vp2 <- viewport(x = .725, y = .065,
  #                 height = 0.07, width = .3,
  #                 just = c("center", "bottom"),
  #                 name = "key2.vp")
  # pushViewport(vp2)
  # draw.colorkey(key = list(col = cols_div(17), width = 1,
  #                          at = seq(-.175, .175, .025),
  #                          space = "bottom"), draw = TRUE)
  # grid.text(expression(bold(Delta ~ "NDVI"[EOTmax])), x = 0.5, y = -.1, 
  #           just = c("centre", "top"), gp = gpar(font = 2, cex = .85))
  # 
  # dev.off()
}