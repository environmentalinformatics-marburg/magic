library(Orcs)
library(raster)
library(RColorBrewer)
library(Rsenal)
library(grid)

setwdOS()

## data import

ch_dir_eot <- "publications/paper/detsch_et_al__ndvi_dynamics/figures/data/"
ch_fls_eot <- paste0(ch_dir_eot, "gimms_ndvi3g_dwnscl_8211.tif")
rst_eot <- stack(ch_fls_eot)
rst_eot_ll <- projectRaster(rst_eot, crs = "+init=epsg:4326")
rst_eot_ll <- trim(rst_eot_ll)

# ch_dt_scl <- substr(basename(ch_fls_scl), 16, 21)
# 
# ch_fls_dsn <- list.files("kilimanjaro/ndvi/whittaker_myd13q1/", 
#                          pattern = "^DSN_SCL_AGGMAX_WHT", full.names = TRUE)
# ch_dt_dsn <- substr(basename(ch_fls_dsn), 20, 25)
# 
# int_id <- which(ch_dt_scl %in% ch_dt_dsn)
# ch_fls_scl <- ch_fls_scl[int_id]
# 
# rst_scl <- stack(ch_fls_scl)
# rst_scl_ll <- projectRaster(rst_scl, crs = "+init=epsg:4326")
# rst_scl_ll <- trim(rst_scl_ll)
# 
# rst_dsn <- stack(ch_fls_dsn)
# rst_dsn_ll <- projectRaster(rst_dsn, crs = "+init=epsg:4326")
# rst_dsn_ll <- trim(rst_dsn_ll)

## dem
rst_dem <- raster("kilimanjaro/coordinates/coords/DEM_ARC1960_30m_Hemp.tif")
rst_dem_ll <- projectRaster(rst_dem, crs = "+init=epsg:4326")

## monthly averages
rst_mv <- raster::stack(rep(lapply(1:12, function(i) {
  raster::calc(rst_eot[[seq(i, raster::nlayers(rst_eot), 12)]], fun = mean)
}), raster::nlayers(rst_eot) / 12))
rst_mv_ll <- projectRaster(rst_mv, crs = "+init=epsg:4326")
rst_mv_ll <- trim(rst_mv_ll)

## feb 2005
dt_sq <- seq(as.Date("1982-01-01"), as.Date("2011-12-31"), "month")
ch_dt_sq <- strftime(dt_sq, format = "%Y%m")
int_id_feb <- grep("199801", ch_dt_sq)

## visualization
col.regions <- colorRampPalette(brewer.pal(9, "Greens"))
rst_dem_ll <- crop(rst_dem_ll, rst_mv_ll)

rst_eot_ll[[int_id_feb]][rst_eot_ll[[int_id_feb]][] > 1] <- 1
p_raw <- spplot(rst_eot_ll[[int_id_feb]], scales = list(draw = TRUE), 
                col.regions = col.regions(100), at = seq(-.1, 1, .05), 
                xlab = "", ylab = "Latitude", 
                sp.layout = list(
                  list("sp.lines", rasterToContour(rst_dem_ll), col = "grey75"), 
                  list("sp.text", loc = c(37.05, -2.875), txt = "a)", 
                       col = "black", font = 2, cex = 1.2)
                ))

p_mv <- spplot(rst_mv_ll[[1]], scales = list(draw = TRUE), 
               col.regions = col.regions(100), at = seq(-.1, 1, .05),
               xlab = "", ylab = "Latitude", 
               sp.layout = list(
                 list("sp.lines", rasterToContour(rst_dem_ll), col = "grey75"), 
                 list("sp.text", loc = c(37.05, -2.875), txt = "b)", 
                      col = "black", font = 2, cex = 1.2)
               ))

p_raw_mv <- latticeCombineGrid(list(p_raw, p_mv), layout = c(2, 1))

col.div <- colorRampPalette(brewer.pal(11, "BrBG"))
p_anom <- spplot(rst_eot_ll[[int_id_feb]] - rst_mv_ll[[1]], 
                 scales = list(draw = TRUE), col.regions = col.div(100), 
                 xlab = "Longitude", ylab = "Latitude", at = seq(-.4, .4, .05), 
                 sp.layout = list(
                   list("sp.lines", rasterToContour(rst_dem_ll), col = "grey75"), 
                   list("sp.text", loc = c(37.025, -2.875), txt = "c)", 
                        col = "black", font = 2, cex = 1.2)
                 ))

png("publications/paper/detsch_et_al__ndvi_dynamics/figures/data/vis/fig02__deseason.png", 
    width = 18, height = 18, units = "cm", pointsize = 15, res = 300)
grid.newpage()

# raw and mean february values
vp_raw <- viewport(x = 0, y = .58, just = c("left", "bottom"), 
                   width = 1, height = .4)
pushViewport(vp_raw)
print(p_raw_mv, newpage = FALSE)

# deseasoned february values
upViewport()
vp_dsn <- viewport(x = 0, y = .01, just = c("left", "bottom"), 
                   width = 1, height = .645)
pushViewport(vp_dsn)
print(p_anom, newpage = FALSE)

# legend caption (1)
upViewport()
vp_legcap1 <- viewport(x = .9, y = .54, just = c("left", "bottom"), 
                       width = .1, height = .5)
pushViewport(vp_legcap1)
grid.text(expression("NDVI"[EOT]), rot = -90)

# legend caption (2)
upViewport()
vp_legcap2 <- viewport(x = .9, y = .04, just = c("left", "bottom"), 
                       width = .1, height = .64)
pushViewport(vp_legcap2)
grid.text(expression(Delta ~ "NDVI"), rot = -90)

dev.off()
