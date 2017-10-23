### environment -----

## working directory
repo = getwd()
Orcs::setwdOS("/media/fdetsch/XChange", "E:", "bale")

## packages and functions
# devtools::install_github("environmentalinformatics-marburg/heavyRain")
lib = c("heavyRain", "Rsenal", "RColorBrewer", "grid")
Orcs::loadPkgs(lib)

source(file.path(repo, "R/visDEM.R"))
source(file.path(repo, "R/panel.smoothconts.R"))


### process -----

odr = "chirps/africa_monthly"
# fls <- getCHIRPS("africa", "tifs", "monthly", cores = 3L, dsn = odr)
# tfs <- extractChirps(fls, dsn = file.path(odr, "tfs"), cores = 3L)

## reimport extracted images
tfs <- list.files(file.path(odr, "tfs"), full.names = TRUE, 
                  pattern = "^chirps.*.tif$")
rst <- stack(tfs)

## clip images in parallel
ref <- spTransform(readRDS(file.path(repo, "inst/extdata/uniformExtent.rds")), 
                   CRS = CRS(projection(rst)))

cl <- makePSOCKcluster(detectCores() * 0.75)
clusterExport(cl, "ref")

crp <- stack(parLapply(cl, unstack(rst), function(i) {
    raster::crop(i, ref, snap = "out")
}))

st = gsub("\\.", "", substr(basename(tfs[1]), 13, 19))
nd = gsub("\\.", "", substr(basename(tfs[length(tfs)]), 13, 19))
fn = paste0("chirps/crp/chirps-2.0_", st, "-", nd, "_monthly.tif")
prj <- trim(projectRaster(crp, crs = "+init=epsg:32637"), 
            filename = fn,overwrite = TRUE)

## calculate annual sums from full years only (1981 to 2016)
crp <- crp[[1:grep("2016.12", tfs)]]; tfs <- tfs[1:grep("2016.12", tfs)]
ids <- sapply(strsplit(tfs, "\\."), "[[", 3)
yrs <- stackApply(crp, ids, fun = sum)

## create long-term mean
ltm <- calc(yrs, fun = mean, na.rm = TRUE)


### visualize -----

## download rgb
rgb <- kiliAerial(template = ltm, minNumTiles = 20L)
rgb <- writeRaster(rgb, "../../data/bale/aerials/kiliAerial_bing_mnt20.tif")

p_rgb <- spplot(ltm, sp.layout = Rsenal::rgb2spLayout(rgb, c(.02, .96)), 
                scales = list(draw = TRUE, cex = .7), 
                col.regions = "transparent", colorkey = FALSE)

## create contour lines
dem <- raster("/media/fdetsch/XChange/bale/dem/dem_srtm_01.tif")
dem <- crop(dem, ltm, snap = "out")
dem <- aggregate(dem, 4L)

p_dem <- visDEM(dem, seq(1500, 4000, 500), labcex = .6, method = "edge", 
                labels = c("", "2000", "", "3000", "", "4000"))

## long-term mean
clr <- colorRampPalette(brewer.pal(9, "YlGnBu"))
p_ltm <- spplot(ltm, at = seq(790, 1210, 5), col.regions = clr(100), 
                scales = list(draw = TRUE)) + 
  as.layer(p_dem)

p <- latticeCombineGrid(list(p_rgb, p_ltm), layout = c(2, 1))

## write to disk
tiff("vis/chirps_ltm_1981-2016.tiff", width = 24, height = 12, units = "cm", 
     res = 300, compression = "lzw")
plot.new()
vp0 <- viewport(x = 0, y = 0, width = .95, height = .95, 
                just = c("left", "bottom"))
pushViewport(vp0)
print(p, newpage = FALSE)

downViewport(trellis.vpname("figure"))
grid.text(paste("CHIRPS mean annual precipitation (mm; 1981 to 2016)", 
                 "in the Bale Mountains region"), x = .5, y = 1.15, 
          gp = gpar(cex = .9, fontface = "bold"))

vp1 <- viewport(x = 1.05, y = .5, width = .05, height = 1, 
                just = c("left", "center"))
pushViewport(vp1)
draw.colorkey(key = list(labels = list(cex = .8), col = clr(100), 
                         width = .6, height = .5, at = seq(790, 1210, 5), 
                         space = "right"), draw = TRUE)
dev.off()

## deregister parallel backend
stopCluster(cl)
