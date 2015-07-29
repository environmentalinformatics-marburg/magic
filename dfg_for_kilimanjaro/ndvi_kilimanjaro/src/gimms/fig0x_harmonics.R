library(Rsenal)
library(grid)
library(rasterVis)

source("../../ndvi/src/panel.smoothconts.R")

# dem
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")
dem <- projectRaster(dem, crs = "+init=epsg:4326")
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
rst_st <- projectRaster(rst_st, crs = "+init=epsg:4326", method = "ngb")
rst_st <- trim(rst_st)

fls_nd <- list.files("data/rst/harmonic/", pattern = "^GIMMS_nd", full.names = TRUE)
rst_nd <- stack(fls_nd)
rst_nd <- projectRaster(rst_nd, crs = "+init=epsg:4326", method = "ngb")
rst_nd <- trim(rst_nd)

fls_diff <- list.files("data/rst/harmonic/", pattern = "^diff.*.tif$", full.names = TRUE)
rst_diff <- lapply(fls_diff, function(i) {
  trim(projectRaster(raster(i), crs = "+init=epsg:4326"))
})

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
                         # xlab = list("Longitude", cex = 1.2), 
                         # ylab = list("Latitude", cex = 1.2), 
                         col.regions = hcl(h = col_month_max$h, c = 70, l = 65), 
                         main = "Month", 
                         sp.layout = list("sp.text", loc = c(37.025, -3.35), 
                                          txt = "a)", font = 2, cex = 1.2))

p_month_max_st_dem <- p_month_max_st + as.layer(p_dem)
p_month_max_st_dem_envin <- envinmrRasterPlot(p_month_max_st_dem, rot = 0)

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
                         # xlab = list("Longitude", cex = 1.2), 
                         # ylab = list("Latitude", cex = 1.2), 
                         col.regions = hcl(h = col_month_max$h, c = 70, l = 65), 
                         sp.layout = list("sp.text", loc = c(37.025, -3.35), 
                                          txt = "b)", font = 2, cex = 1.2))

p_month_max_nd_dem <- p_month_max_nd + as.layer(p_dem)
p_month_max_nd_dem_envin <- envinmrRasterPlot(p_month_max_nd_dem, rot = 0)

# diff month max
rcl_mat <- matrix(c(-7.5, -.5, -1, 
                    .5, 7.5, 1), ncol = 3, byrow = TRUE)
rst_diff_month_rcl <- reclassify(rst_diff[[1]], rcl_mat)
rst_diff_month_rcl[rst_diff_month_rcl[] > -.5 & rst_diff_month_rcl[] < .5] <- 0

rat_diff_month_rcl <- ratify(rst_diff_month_rcl)
rat <- levels(rat_diff_month_rcl)[[1]]
rat$month <- c("-", "0", "+")
levels(rat_diff_month_rcl) <- rat

p_diff_max_x <- levelplot(rat_diff_month_rcl, col.regions = rev(brewer.pal(9, "RdBu")), 
                          at = -1.5:1.5, scales = list(draw = TRUE), 
                          xlab = "Longitude", ylab = "Latitude")

p_diff_max_x <- spplot(rst_diff_month_rcl, col.regions = rev(brewer.pal(9, "RdBu")), 
                       at = -1.5:1.5, scales = list(draw = TRUE), 
                       # xlab = "Longitude", ylab = "Latitude", 
                       sp.layout = list("sp.text", loc = c(37.025, -3.35), 
                                        txt = "c)", font = 2, cex = 1.2))

p_diff_max_x_dem <- p_diff_max_x + as.layer(p_dem)
p_diff_max_x_dem_envin <- envinmrRasterPlot(p_diff_max_x_dem, rot = 0)

# diff ndvi max
cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
p_diff_max_y <- spplot(rst_diff[[2]], col.regions = cols_div(17), 
                       at = seq(-.175, .175, .025), scales = list(draw = TRUE), 
                       # xlab = "Longitude", ylab = "Latitude", 
                       sp.layout = list("sp.text", loc = c(37.025, -3.35), 
                                        txt = "d)", font = 2, cex = 1.2))

p_diff_max_y_dem <- p_diff_max_y + as.layer(p_dem)
p_diff_max_y_dem_envin <- envinmrRasterPlot(p_diff_max_y_dem, rot = 0)

p_comb <- latticeCombineGrid(list(p_month_max_st_dem_envin, 
                                  p_month_max_nd_dem_envin, 
                                  p_diff_max_x_dem_envin, 
                                  p_diff_max_y_dem_envin), 
                             layout = c(2, 2))

png("vis/harmonic/fig04__seasonality.png", width = 26 * .85, height = 30 * .85, 
    units = "cm", pointsize = 15, res = 300)
plot.new()

vp0 <- viewport(x = 0, y = .05, width = 1, height = .95, 
                just = c("left", "bottom"), name = "figure.vp")
pushViewport(vp0)
print(p_comb, newpage = FALSE)

## colorkey: seasonal shift
vp1 <- viewport(x = .3, y = .065,
                height = 0.07, width = .4,
                just = c("center", "bottom"),
                name = "key1.vp")
pushViewport(vp1)
draw.colorkey(key = list(col = rev(brewer.pal(9, "RdBu")), width = 1, height = .5,
                         at = seq(-1.5, 1.5, 1), 
labels = list(labels = c("-", "0", "+"), at = c(-1, 0, 1)), 
                         space = "bottom"), draw = TRUE)
grid.text("Seasonal shift", x = 0.5, y = -.1, just = c("centre", "top"), 
          gp = gpar(font = 2))

## colorkey: Delta NDVI_EOTmax
upViewport()
vp2 <- viewport(x = .7, y = .065,
                height = 0.07, width = .4,
                just = c("center", "bottom"),
                name = "key2.vp")
pushViewport(vp2)
draw.colorkey(key = list(col = cols_div(17), width = 1,
                         at = seq(-.175, .175, .025),
                         space = "bottom"), draw = TRUE)
grid.text(expression(Delta ~ "NDVI"[EOTmax]), x = 0.5, y = -.1, 
          just = c("centre", "top"), gp = gpar(font = 2))
grid.text(expression(bold(Delta ~ "NDVI"[EOTmax])), x = 0.5, y = -.1, 
          just = c("centre", "top"), gp = gpar(font = 2))

dev.off()
