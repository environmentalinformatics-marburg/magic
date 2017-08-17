### environment -----

## working directory
repo = file.path(getwd(), "dfg_for_bale/p1")
setwd("/media/fdetsch/XChange/bale")

## packages and functions
# devtools::install_github("environmentalinformatics-marburg/chirps")
library(heavyRain)
library(raster)
library(Rsenal)
library(RColorBrewer)
library(grid)
library(RColorBrewer)
library(latticeExtra)
library(RStoolbox)

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

cl <- makePSOCKcluster(detectCores() * .75)
clusterExport(cl, "ref")

crp <- stack(parLapply(cl, unstack(rst), function(i) {
    raster::crop(i, ref, snap = "out")
}))

## calculate annual sums from full years only (1981 to 2016)
crp <- crp[[1:grep("2016.12", tfs)]]; tfs <- tfs[1:grep("2016.12", tfs)]
ids <- sapply(strsplit(tfs, "\\."), "[[", 3)
yrs <- stackApply(crp, ids, fun = sum)

## create long-term mean
ltm <- calc(yrs, fun = mean, na.rm = TRUE)


### monthly anomalies in late 2015 -----

## deseason
y36 = crp[[1:grep("2016.12", tfs)]]
dsn = remote::deseason(y36)

## overview chart
clr = colorRampPalette(brewer.pal(4, "PuOr"))

tiff("~/Downloads/move/rainfall-anomalies.tiff", width = 22, height = 16, 
     units = "cm", res = 300, compression = "lzw")
par(mfrow = c(2, 3))
for (i in 7:12) {
  lbl = paste0("2015.", formatC(i, width = 2, flag = "0"))
  plot(dsn[[grep(lbl, tfs)]], main = lbl, zlim = c(-70, 70), col = clr(100))
  lines(rasterToContour(dem_utm), col = "grey50")
}
dev.off()

## figure in reber et al. 2017
ltm_mts = stack(lapply(8:10, function(i) {
  rst = y36[[seq(i, nlayers(y36), 12)]]
  calc(rst, fun = mean, na.rm = TRUE)
}))

p_mts = lapply(1:nlayers(ltm_mts), function(i) {
  spplot(ltm_mts[[i]], colorkey = FALSE, col.regions = "transparent"
         , scales = list(draw = TRUE)) + 
    as.layer(visDEM(disaggregate(ltm_mts[[i]], 8, "bilinear"), seq(50, 150, 25)
                    , labcex = .6, method = "edge", col = "black"
                    , labels = as.character(seq(50, 150, 25))))
})

## anomalies
anm = dsn[[grep("2015.08|2015.09|2015.10", tfs)]]

lapply(seq(-15, -45, -15), function(i) {
  tmp = anm[[1]]
  
  dag = disaggregate(tmp, 50, "bilinear")
  ids = dag[] > i
  dag[ids] = NA; dag[which(!ids)] = i
  
  spy = rasterToPolygons(dag, dissolve = TRUE)
  maptools::unionSpatialPolygons(spy)
  lns = rasterToContour(dag, levels = i)
  ext = extent(tmp)
  ext = as(ext, "SpatialPolygons"); proj4string(ext) = projection(tmp)
  lns = rasterToContour(disaggregate(tmp, 8L, "bilinear"), levels = i)
  
  ids = tmp[] < i
  tmp[!ids] <- NA
  spy = rasterToPolygons(tmp)
  rasterToPolygons()
  return(tmp)
})


lines(rasterToContour(disaggregate(tmp, 8, "bilinear"), levels = seq(-75, 0, 25)))

## landsat 8 image
ref_utm = extent(projectExtent(ltm_mts, crs = "+init=epsg:32637"))
ref_utm = as(ref_utm, "SpatialPolygons")
proj4string(ref_utm) = "+init=epsg:32637"

ls8 = list.files("landsat", pattern = "^LC08.*T1.tif$"
                 , recursive = TRUE, full.names = TRUE)

crp = vector("list", length(ls8)); n = 1L
for (i in ls8) {
  cat("File", basename(i), "is in, start processing ...\n")
  
  rst = crop(stack(i), ref_utm, snap = "out")
  val = getValues(rst)
  nan = apply(val, 1, FUN = function(x) all(x == 0))
  rst[nan] = NA; rm(val)
  
  for (j in 1:10) {
    adj = adjacent(rst, which(nan), directions = 4, pairs = FALSE)
    adj = unique(adj)
    rst[adj] = NA
    nan = is.na(rst[])
  }
  
  crp[[n]] = rst; n = n + 1L
}

right = merge(crp[[1]], crp[[2]])
hsm = histMatch(crp[[3]], right)
rgb = merge(right, hsm); rm(list = c("right", "hsm"))
rgb = trim(projectRaster(rgb, crs = "+init=epsg:4326", method = "ngb")
           , filename = file.path(repo, "inst/extdata/lc8.tif")
           , overwrite = TRUE)

small = extent(c(39 + 36 / 60, 40, 6 + 42 / 60, 7 + 6 / 60))
small = as(small, "SpatialPolygons"); proj4string(small) = "+init=epsg:4326"

p_rgb = spplot(ltm_mts[[1]], colorkey = FALSE, col.regions = "transparent"
               , scales = list(draw = TRUE), sp.layout = list(
                 Rsenal::rgb2spLayout(rgb, c(0, 1), alpha = .75)
                 , Rsenal::rgb2spLayout(crop(rgb, small), c(0, 1))
                 , list("sp.polygons", small, col = "black", fill = "transparent", lwd = 2)
               ))

p = Orcs::latticeCombineGrid(list(p_rgb, p_mts[[1]], p_mts[[2]], p_mts[[3]]))

plot.new()
print(p, newpage = FALSE)

## deregister parallel backend
stopCluster(cl)
