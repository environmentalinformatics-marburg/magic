library(Orcs)
library(raster)
library(RColorBrewer)
library(Rsenal)
library(grid)

setwdOS()

## data import
ch_fls_scl <- list.files("kilimanjaro/ndvi/whittaker_myd13q1/", 
                         pattern = "^SCL_AGGMAX_WHT", full.names = TRUE)
ch_dt_scl <- substr(basename(ch_fls_scl), 16, 21)

ch_fls_dsn <- list.files("kilimanjaro/ndvi/whittaker_myd13q1/", 
                         pattern = "^DSN_SCL_AGGMAX_WHT", full.names = TRUE)
ch_dt_dsn <- substr(basename(ch_fls_dsn), 20, 25)

int_id <- which(ch_dt_scl %in% ch_dt_dsn)
ch_fls_scl <- ch_fls_scl[int_id]

rst_scl <- stack(ch_fls_scl)
rst_scl_ll <- projectRaster(rst_scl, crs = "+init=epsg:4326")
rst_scl_ll <- trim(rst_scl_ll)

rst_dsn <- stack(ch_fls_dsn)
rst_dsn_ll <- projectRaster(rst_dsn, crs = "+init=epsg:4326")
rst_dsn_ll <- trim(rst_dsn_ll)

## dem
rst_dem <- raster("kilimanjaro/coordinates/coords/DEM_ARC1960_30m_Hemp.tif")
rst_dem_ll <- projectRaster(rst_dem, crs = "+init=epsg:4326")

## monthly averages
rst_mv <- raster::stack(rep(lapply(1:12, function(i) {
  raster::calc(rst_scl[[seq(i, raster::nlayers(rst_scl), 12)]], fun = mean)
}), raster::nlayers(rst_scl) / 12))
rst_mv_ll <- projectRaster(rst_mv, crs = "+init=epsg:4326")
rst_mv_ll <- trim(rst_mv_ll)

## feb 2005
int_id_feb <- grep("201001", ch_fls_scl)

## visualization
col.regions <- colorRampPalette(brewer.pal(9, "Greens"))
rst_dem_ll <- crop(rst_dem_ll, rst_mv_ll)

p_raw <- spplot(rst_scl_ll[[int_id_feb]], scales = list(draw = TRUE), 
                col.regions = col.regions(100), at = seq(-.1, 1, .05), 
                xlab = "", ylab = "Latitude", 
                sp.layout = list(
                  list("sp.lines", rasterToContour(rst_dem_ll), col = "grey75"), 
                  list("sp.text", loc = c(37.05, -2.875), txt = "a)", col = "black", font = 2)
                ))

p_mv <- spplot(rst_mv_ll[[1]], scales = list(draw = TRUE), 
               col.regions = col.regions(100), at = seq(-.1, 1, .05),
               xlab = "", ylab = "Latitude", 
               sp.layout = list(
                 list("sp.lines", rasterToContour(rst_dem_ll), col = "grey75"), 
                 list("sp.text", loc = c(37.05, -2.875), txt = "b)", col = "black", font = 2)
               ))

p_raw_mv <- latticeCombineGrid(list(p_raw, p_mv), layout = c(2, 1))

col.div <- colorRampPalette(brewer.pal(11, "BrBG"))
p_anom <- spplot(rst_scl_ll[[int_id_feb]] - rst_mv_ll[[1]], 
                 scales = list(draw = TRUE), col.regions = col.div(100), 
                 xlab = "Longitude", ylab = "Latitude", at = seq(-.35, .35, .05), 
                 sp.layout = list(
                   list("sp.lines", rasterToContour(rst_dem_ll), col = "grey75"), 
                   list("sp.text", loc = c(37.025, -2.875), txt = "c)", col = "black", font = 2)
                 ))

png("publications/paper/detsch_et_al__ndvi_dynamics/figures/fig02__deseason.png", 
    width = 15, height = 18, units = "cm", pointsize = 15, res = 300)
grid.newpage()

vp_raw <- viewport(x = 0, y = .575, just = c("left", "bottom"), 
                   width = 1, height = .385)
pushViewport(vp_raw)

print(p_raw_mv, newpage = FALSE)

upViewport()
vp_dsn <- viewport(x = 0, y = 0, just = c("left", "bottom"), 
                   width = 1, height = .675)
pushViewport(vp_dsn)
print(p_anom, newpage = FALSE)
dev.off()
