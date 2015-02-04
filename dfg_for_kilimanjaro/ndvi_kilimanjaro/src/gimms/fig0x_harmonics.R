library(Rsenal)
library(grid)

source("../../ndvi/src/panel.smoothconts.R")

# dem
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")
dem_flipped <- flip(dem, "y")
x <- coordinates(dem_flipped)[, 1]
y <- coordinates(dem_flipped)[, 2]
z <- dem_flipped[]

p_dem <- levelplot(z ~ x * y, colorkey = FALSE, at = seq(1000, 6000, 1000), 
                   panel = function(...) {
                     panel.smoothconts(zlevs.conts = seq(1000, 5500, 500), 
                                       labels = c(1000, "", 2000, "", 3000, "", 4000, "", 5000, ""), 
                                       ...)
                   })

# gimms seasonality
fls_st <- list.files("data/rst/harmonic/", pattern = "^GIMMS_st", full.names = TRUE)
rst_st <- stack(fls_st)

fls_nd <- list.files("data/rst/harmonic/", pattern = "^GIMMS_nd", full.names = TRUE)
rst_nd <- stack(fls_nd)

fls_diff <- list.files("data/rst/harmonic/", pattern = "^diff.*.tif$", full.names = TRUE)
rst_diff <- lapply(fls_diff, raster)

# st month max
rat_month_max <- ratify(rst_st[[1]])
rat <- levels(rat_month_max)[[1]]
rat$month <- month.abb
levels(rat_month_max) <- rat

val_month_max <- sort(unique(rst_st[[1]]))
col_month_max <- data.frame(cell = 1:length(val_month_max), 
                            h = -360/12 + val_month_max * 360/12, 
                            l = 80,
                            c = 65)

p_month_max_st <- spplot(rst_st[[1]], scales = list(draw = TRUE), at = .5:12.5, 
                         xlab = list("", cex = 1.5), ylab = list("", cex = 1.5), 
                         col.regions = hcl(h = col_month_max$h, c = 70, l = 65), 
                         main = "Month")

p_month_max_st_dem <- p_month_max_st + as.layer(p_dem)
p_month_max_st_dem_envin <- envinmrRasterPlot(p_month_max_st_dem)

# nd month max
rat_month_max <- ratify(rst_nd[[1]])
rat <- levels(rat_month_max)[[1]]
rat$month <- month.abb
levels(rat_month_max) <- rat

val_month_max <- sort(unique(rst_st[[1]]))
col_month_max <- data.frame(cell = 1:length(val_month_max), 
                            h = -360/12 + val_month_max * 360/12, 
                            l = 80,
                            c = 65)

p_month_max_nd <- spplot(rst_nd[[1]], scales = list(draw = TRUE), at = .5:12.5, 
                         xlab = list("x", cex = 1.5), ylab = list("y", cex = 1.5), 
                         col.regions = hcl(h = col_month_max$h, c = 70, l = 65))

p_month_max_nd_dem <- p_month_max_nd + as.layer(p_dem)
p_month_max_nd_dem_envin <- envinmrRasterPlot(p_month_max_nd_dem)

# diff month max
rcl_mat <- cbind(-7, -3, -3)
rst_diff_month_rcl <- reclassify(rst_diff[[1]], rcl_mat)

p_diff_max_x <- spplot(rst_diff_month_rcl, col.regions = rev(brewer.pal(9, "RdBu")), 
                       at = -3.5:3.5, scales = list(draw = TRUE), 
                       xlab = "x", ylab = "y")

p_diff_max_x_dem <- p_diff_max_x + as.layer(p_dem)
p_diff_max_x_dem_envin <- envinmrRasterPlot(p_diff_max_x_dem)

# diff ndvi max
cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
p_diff_max_y <- spplot(rst_diff[[2]], col.regions = cols_div(17), 
                       at = seq(-.175, .175, .025), scales = list(draw = TRUE), 
                       xlab = "x", ylab = "y")

p_diff_max_y_dem <- p_diff_max_y + as.layer(p_dem)
p_diff_max_y_dem_envin <- envinmrRasterPlot(p_diff_max_y_dem)

p_comb <- latticeCombineGrid(list(p_month_max_st_dem_envin, 
                                  p_month_max_nd_dem_envin, 
                                  p_diff_max_x_dem_envin, 
                                  p_diff_max_y_dem_envin), 
                             layout = c(2, 2))

png("vis/harmonic/p_comb.png", width = 26, height = 30, units = "cm", 
    pointsize = 15, res = 600)
plot.new()
print(p_comb)

downViewport(trellis.vpname(name = "figure"))
vp1 <- viewport(x = 0.25, y = -.05,
                height = 0.07, width = 0.4,
                just = c("centre", "top"),
                name = "key.vp")
pushViewport(vp1)
draw.colorkey(key = list(col = rev(brewer.pal(9, "RdBu")), width = 1,
                         at = seq(-3.5, 3.5, 1),
                         space = "bottom"), draw = TRUE)
grid.text("Seasonal shift (months)", x = 0.5, y = -.05, just = c("centre", "top"))
upViewport()
vp2 <- viewport(x = 0.76, y = -.05,
                height = 0.07, width = 0.4,
                just = c("centre", "top"),
                name = "key.vp")
pushViewport(vp2)
draw.colorkey(key = list(col = cols_div(17), width = 1,
                         at = seq(-.175, .175, .025),
                         space = "bottom"), draw = TRUE)
grid.text(expression(Delta ~ "NDVI"[max]), x = 0.5, y = -.05, just = c("centre", "top"))

dev.off()
