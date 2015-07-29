### environmental stuff

## working directory
library(Orcs)
setwdOS()

## packages
library(raster)
library(rgdal)
library(grid)

## functions
source("repositories/magic/dfg_for_kilimanjaro/fire_ndvi/src/panel.smoothconts.R")

## input filepath
ch_dir_fig <- "publications/paper/detsch_et_al__ndvi_dynamics/figures/"
ch_dir_data <- paste0(ch_dir_fig, "data/")
ch_dir_eval <- paste0(ch_dir_data, "eot_eval_agg1km/")


### data processing

## rmse
ch_fls_rmse <- paste0(ch_dir_eval, "rmse_niter20.tif")
rst_rmse <- raster(ch_fls_rmse)

# ## rmse standard error
# ch_fls_rmse_se <- paste0(ch_dir_eval, "rmse_se_niter20.tif")
# rst_rmse_se <- raster(ch_fls_rmse_se)

# linear regression slope
ch_fls_slp <- paste0(ch_dir_eval, "lm_slp.tif")
rst_slp <- raster(ch_fls_slp)
rst_slp <- rst_slp * 360

# slope > rmse
rst_slp_gt_rmse <- overlay(rst_slp, rst_rmse, fun = function(x, y) {
  sapply(1:length(x), function(i) {
    if (abs(x[i]) > abs(y[i]))
      return(x[i])
    else 
      return(NA)
  })
}, filename = paste0(ch_dir_eval, "slp_gt_rmse"), format = "GTiff", 
overwrite = TRUE)
rst_slp_gt_rmse <- trim(projectRaster(rst_slp_gt_rmse, crs = "+init=epsg:4326"))

## visualization

# dem labeled contours
dem <- raster("kilimanjaro/coordinates/coords/DEM_ARC1960_30m_Hemp.tif")
dem <- trim(projectRaster(dem, crs = "+init=epsg:4326"))
dem_flipped <- flip(dem, "y")
x <- coordinates(dem_flipped)[, 1]
y <- coordinates(dem_flipped)[, 2]
z <- dem_flipped[]

p_dem <- levelplot(z ~ x * y, colorkey = FALSE, at = seq(1000, 6000, 1000), 
                   panel = function(...) {
                     panel.smoothconts(zlevs.conts = seq(1000, 5500, 500), 
                                       labels = c(1000, "", 2000, "", 3000, "", 4000, "", 5000, ""),
                                       col = "grey50", ...)
                   })

# national park boundaries
np_old_utm <- readOGR(dsn = paste0(ch_dir_data, "shp/"), 
                      layer = "fdetsch-kilimanjaro-national-park-1420535670531")
np_old_utm_sl <- as(np_old_utm, "SpatialLines")

np_new_utm <- readOGR(dsn = paste0(ch_dir_data, "shp/"), 
                      layer = "fdetsch-kilimanjaro-1420532792846")
np_new_utm_sl <- as(np_new_utm, "SpatialLines")

# figure slope
cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
p_slp_gt_rmse <- 
  spplot(rst_slp_gt_rmse, col.regions = cols_div(100), 
         xlab = "Longitude", ylab = "Latitude", at = seq(-.25, .25, .05), 
         scales = list(draw = TRUE), colorkey = FALSE,
         par.settings = list(fontsize = list(text = 15)),
         sp.layout = list(list("sp.lines", np_old_utm_sl, lwd = 1.6, lty = 2), 
                          list("sp.lines", np_new_utm_sl, lwd = 1.6))) + 
  as.layer(p_dem)

p_slp_gt_rmse_envin <- envinmrRasterPlot(p_slp_gt_rmse, rot = 0)

# png("vis/eval/slp_gt_rmse.png", width = 26, height = 18, units = "cm", 
#     pointsize = 15, res = 300)
# plot.new()
# print(p_slp_gt_rmse_envin)
# dev.off()

# figure mann-kendall 
mod_predicted_mk <- list.files(paste0(ch_dir_data, "rst/"), 
                               pattern = "8211_mk.*.tif$", full.names = TRUE)
mod_predicted_mk <- lapply(mod_predicted_mk, function(i) {
  trim(projectRaster(raster(i), crs = "+init=epsg:4326", method = "ngb"))
})

cols_div <- brewer.pal(10, "BrBG")
p_mk <- 
  spplot(mod_predicted_mk[[1]], col.regions = brewer.pal(10, "BrBG"), 
         xlab = "Longitude", ylab = "", colorkey = FALSE,
         at = seq(-.5, .5, .1), scales = list(draw = TRUE),  
         par.settings = list(fontsize = list(text = 15)),
         sp.layout = list(list("sp.lines", np_old_utm_sl, lwd = 1.6, lty = 2), 
                          list("sp.lines", np_new_utm_sl, lwd = 1.6))) + 
  as.layer(p_dem)

p_mk_envin <- envinmrRasterPlot(p_mk, rot = 0)

# combine figures
p_comb <- latticeCombineGrid(list(p_slp_gt_rmse_envin, p_mk_envin), 
                             layout = c(2, 1))

p_comb <- latticeCombineGrid(list(p_slp_gt_rmse, p_mk), layout = c(2, 1))

png(paste0(ch_dir_data, "vis/fig03__longterm_trends.png"), height = 26*.7, 
    width = 40*.7, units = "cm", res = 300, pointsize = 15)
plot.new()
# # viewport for visualization of slope
# vp0 <- viewport(x = 0, y = 0, height = 1, width = .5, 
#                 just = c("left", "bottom"), name = "vp_slope")
# pushViewport(vp0)
# print(p_slp_gt_rmse_envin, newpage = FALSE)
# 
# # viewport for kendall's tau
# upViewport()
# vp1 <- viewport(x = 0.5, y = 0, height = 1, width = .5, 
#                 just = c("left", "bottom"), name = "vp_tau")
# pushViewport(vp1)
# print(p_mk_envin, newpage = FALSE)

print(p_comb, newpage = FALSE)

# additional key
downViewport(trellis.vpname(name = "figure"))

vp1 <- viewport(x = 0.2, y = 1.15,
                height = 0.07, width = .4,
                just = c("centre", "bottom"),
                name = "key_slope.vp")
pushViewport(vp1)
draw.colorkey(key = list(col = colorRampPalette(brewer.pal(11, "BrBG")), 
                         width = 1, height = .75, at = seq(-.25, .25, .05), 
                         space = "bottom"), draw = TRUE)
grid.text("Regression slope", y = 2)

upViewport()
vp2 <- viewport(x = 0.8, y = 1.15,
                height = 0.07, width = .4,
                just = c("centre", "bottom"),
                name = "key_tau.vp")
pushViewport(vp2)
draw.colorkey(key = list(col = brewer.pal(10, "BrBG"), 
                         width = 1, height = .75, at = seq(-.5, .5, .1), 
                         space = "bottom"), draw = TRUE)
grid.text(expression("Kendall's" ~ tau), y = 2)
# grid.text(expression("Kendall\'s" ~ tau), x = 0.5, y = 0.1, 
#           just = c("centre", "top"), gp = gpar(fontface = 1, fontsize = 12, cex = 1.2))

dev.off()
