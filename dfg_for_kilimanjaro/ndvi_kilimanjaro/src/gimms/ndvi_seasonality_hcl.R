library(rasterVis)
library(rgdal)
library(maptools)
library(Rsenal)

setwd("/media/permanent/xchange/gimms")

fls_st <- list.files("data/rst/harmonic/", pattern = "^GIMMS_st", full.names = TRUE)
rst_st <- stack(fls_st)

fls_nd <- list.files("data/rst/harmonic/", pattern = "^GIMMS_nd", full.names = TRUE)
rst_nd <- stack(fls_nd)

fls_diff <- list.files("data/rst/harmonic/", pattern = "^diff.*.tif$", full.names = TRUE)
rst_diff <- lapply(fls_diff, raster)
diff_max_x <- rst_diff[[1]]
diff_max_y <- rst_diff[[2]]


rst_month_max <- raster("data/rst/harmonic/GIMMS_st_st_max_x.tif")
rst_diff_month <- raster("data/rst/harmonic/diff_max_x.tif")
rst_diff_amp <- raster("data/rst/harmonic/diff_max_y.tif")

rcl_mat <- cbind(-7, -3, -3)
rst_diff_month_rcl <- reclassify(rst_diff_month, rcl_mat)

# df_hcl <- data.frame(cell = 1:ncell(rst_month_max), 
#                      h = -360/12 + rst_month_max[] * 360/12, 
#                      l = 60 + round(rst_diff_amp[], 1) * 30/max(abs(rst_diff_amp[])), # + rst_diff_month_rcl[] * 40/max(abs(rst_diff_month_rcl[]), na.rm = TRUE), # increasing chroma with higher values
#                      c = 65)# ) # decreasing luminance with higher values

# hcl color scheme prerequisites
val_month_max <- sort(unique(rst_month_max[]))
col_month_max <- data.frame(cell = 1:length(val_month_max), 
                            h = -360/12 + val_month_max * 360/12, 
                            l = 80,
                            c = 65)

# create raster with associated raster attribute table (rat)
# -> categorical variable
rat_month_max <- ratify(rst_month_max)
rat <- levels(rat_month_max)[[1]]
rat$month <- month.abb
rat$season <- c("DJF", "DJF", rep(c("MAM", "JJA", "SON"), each = 3), "DJF")
levels(rat_month_max) <- rat

# p_month_max <- 
#   levelplot(rat_month_max, col.regions = hcl(h = col_month_max$h, c = 70, l = 65))
# 
# rst_diff_month_rcl_flipped <- flip(rst_diff_month_rcl, "y")
# x <- coordinates(rst_diff_month_rcl_flipped)[, 1]
# y <- coordinates(rst_diff_month_rcl_flipped)[, 2]
# z <- rst_diff_month_rcl_flipped[]
# 
# p_month_diff <- levelplot(z ~ x * y, at = -3:3, colorkey = FALSE, 
#                           panel = function(...) {
#                             panel.smoothconts(contours = TRUE, zlevs.conts = -3:3, ...)
#                           })
# 
# png("vis/harmonic/h_month_max__l_80__c_65__8291_0211.png", width = 30, 
#     height = 25, units = "cm", res = 300, pointsize = 15)
# plot.new()
# print(p_month_max + as.layer(p_month_diff))
# dev.off()


### visualization

## polygon contours

# raster to polygon
spdf_diff_month_rcl <- rasterToPolygons(rst_diff_month_rcl)

# unique values (months)
val_diff_month_rcl <- sort(unique(spdf_diff_month_rcl@data$layer))

# create subset polygon layers by unique values
ls_sl_diff_month_rcl <- lapply(val_diff_month_rcl, function(i) {
  id_isi <- spdf_diff_month_rcl@data$layer == i
  sp_isi_diff_month_rcl <- unionSpatialPolygons(spdf_diff_month_rcl[id_isi, ], 
                                                IDs = spdf_diff_month_rcl[id_isi, ]@data$layer)
  sl_isi_diff_month_rcl <- as(sp_isi_diff_month_rcl, "SpatialLines")
  return(sl_isi_diff_month_rcl)  
})

# spplot(rat_month_max, col.regions = hcl(h = col_month_max$h, c = 70, l = 65),
#        sp.layout = list(list("sp.lines", ls_sl_diff_month_rcl[[1]], lty = 2, lwd = 3), 
#                         list("sp.lines", ls_sl_diff_month_rcl[[2]], lty = 2, lwd = 2), 
#                         list("sp.lines", ls_sl_diff_month_rcl[[3]], lty = 2, lwd = 1), 
#                         list("sp.lines", ls_sl_diff_month_rcl[[5]], lty = 1, lwd = 1), 
#                         list("sp.lines", ls_sl_diff_month_rcl[[6]], lty = 1, lwd = 2), 
#                         list("sp.lines", ls_sl_diff_month_rcl[[7]], lty = 1, lwd = 3)))

p_1 <- levelplot(rat_month_max, scales = list(draw = TRUE), 
                 xlab = list("x", cex = 1.5), ylab = list("y", cex = 1.5), 
                 par.settings = list("axis.text" = list(cex = 1.1)), 
                 col.regions = hcl(h = col_month_max$h, c = 70, l = 65)) + 
  layer(sp.lines(ls_sl_diff_month_rcl[[1]], lty = 3, lwd = 3.5)) + 
  layer(sp.lines(ls_sl_diff_month_rcl[[2]], lty = 3, lwd = 2.5)) + 
  layer(sp.lines(ls_sl_diff_month_rcl[[3]], lty = 3, lwd = 1.5)) + 
  layer(sp.lines(ls_sl_diff_month_rcl[[5]], lty = 1, lwd = 1)) + 
  layer(sp.lines(ls_sl_diff_month_rcl[[6]], lty = 1, lwd = 2)) + 
  layer(sp.lines(ls_sl_diff_month_rcl[[7]], lty = 1, lwd = 3)) 

png("vis/harmonic/h_month_max__l_80__c_65__8291_0211.png", width = 30, height = 25, 
    units = "cm", pointsize = 15, res = 300)
print(p_1)
dev.off()

# seasons instead of years


### second plot, maximum ndvi and amplitude shift

# plot maximum ndvi
cols_seq <- colorRampPalette(brewer.pal(7, "BrBG"))
p_ndvi_max <- levelplot(rst_st[[2]], col.regions = cols_seq(100), 
                        at = seq(-.05, .95, .05), margin = FALSE)
# # plot contours
# diff_max_y_flipped <- flip(diff_max_y)
# x <- coordinates(diff_max_y_flipped)[, 1]
# y <- coordinates(diff_max_y_flipped)[, 2]
# z <- diff_max_y_flipped[]
# 
# p_amp_max <- levelplot(z ~ x * y, at = seq(-.2, .1, .1), colorkey = FALSE, 
#                        panel = function(...) {
#                          panel.smoothconts(zlevs.conts = seq(-.2, .1, .1), ...)
#                        })
# 
# png("vis/harmonic/h_amp_max__c_65__l_80__8291_0211.png", width = 30, height = 25, 
#     units = "cm", pointsize = 15, res = 300)
# plot.new()
# print(p_ndvi_max + as.layer(p_amp_max))
# dev.off()

# raster to polygon
rcl <- matrix(c(-.25, -.15, -.2, 
                -.15, -.05, -.1, 
                -.05, .05, 0, 
                .05, .15, .1), byrow = TRUE, ncol = 3)
rcl <- matrix(c(-.175, -.125, -.15, 
                -.125, -.075, -.1, 
                -.075, -.025, -.05, 
                -.025, .025, 0, 
                .025, .075, .05, 
                .075, .125, .1), byrow = TRUE, ncol = 3)

diff_max_y_rcl <- reclassify(diff_max_y, rcl)
spdf_diff_max_y_rcl <- rasterToPolygons(diff_max_y_rcl)

# create subset polygon layers by defined classes
ls_sl_diff_max_y_rcl <- lapply(rcl[, 3], function(i) {
  id_isi <- spdf_diff_max_y_rcl@data$layer == i
  sp_isi_diff_max_y_rcl <- unionSpatialPolygons(spdf_diff_max_y_rcl[id_isi, ], 
                                                IDs = spdf_diff_max_y_rcl[id_isi, ]@data$layer)
  sl_isi_diff_max_y_rcl <- as(sp_isi_diff_max_y_rcl, "SpatialLines")
  return(sl_isi_diff_max_y_rcl)  
})

p_2 <- levelplot(rst_st[[2]], col.regions = cols_seq(100), scales = list(draw = TRUE),
                 xlab = list("x", cex = 1.5), ylab = list("y", cex = 1.5), 
                 par.settings = list("axis.text" = list(cex = 1.1)), 
                 at = seq(-.05, .95, .05), margin = FALSE) + 
  layer(sp.lines(ls_sl_diff_max_y_rcl[[1]], lty = 3, lwd = 4, col = "black")) + 
  layer(sp.lines(ls_sl_diff_max_y_rcl[[2]], lty = 3, lwd = 3, col = "black")) + 
  layer(sp.lines(ls_sl_diff_max_y_rcl[[3]], lty = 3, lwd = 2, col = "black")) +
  layer(sp.lines(ls_sl_diff_max_y_rcl[[5]], lty = 1, lwd = 1.5, col = "black")) +
  layer(sp.lines(ls_sl_diff_max_y_rcl[[6]], lty = 1, lwd = 3, col = "black")) 

png("vis/harmonic/h_amp_max__c_65__l_80__8291_0211.png", width = 30, height = 25, 
    units = "cm", pointsize = 15, res = 300)
print(p_2)
dev.off()
