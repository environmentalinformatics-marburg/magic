## working directory
setwd("dfg_for_bale/p5")

## packages
lib = c("parallel", "Rsenal", "cluster", "rasterVis", "RColorBrewer")
Orcs::loadPkgs(lib)

## parallelization
cl <- makePSOCKcluster(3L)
jnk <- clusterEvalQ(cl, library(raster))

## 3-by-3 focal matrix (incl. center)
movingWindow <- function(width = 5L, height = width, fcl = FALSE) {
  mat <- matrix(1, nrow = height, ncol = width)
  if (!fcl) mat[ceiling(height/2), ceiling(width/2)] <- 0
  mat
}

mat_w3by3 = movingWindow(3L, fcl = TRUE)
mat_w5by5 = movingWindow(9L)

## 
tmp = rgeos::gBuffer(lgg, width = 500, quadsegs = 100L)
rgb = kiliAerial(template = tmp, projection = proj4string(lgg), 
                 type = "satellite", scale = 2, rgb = TRUE)

rgb = crop(rgb, tmp)

## focal mean and sd (nlayers() faster than unstack() despite more code)
clusterExport(cl, c("rgb", "mat_w5by5"))

rgb_fc = parLapply(cl, 1:nlayers(rgb), function(i) {
  rst = rgb[[i]]
  list(focal(rst, w = mat_w5by5, fun = mean, na.rm = TRUE, pad = TRUE),
       focal(rst, w = mat_w5by5, fun = sd, na.rm = TRUE, pad = TRUE))
})

rgb_mv <- stack(sapply(rgb_fc, "[[", 1)); names(rgb_mv) = paste0(c("red", "green", "blue"), "_mv")
rgb_sd <- stack(sapply(rgb_fc, "[[", 2)); names(rgb_sd) = paste0(c("red", "green", "blue"), "_sd")

## visible vegetation index
rgb_vi = vvi(rgb); names(rgb_vi) = "vvi"

## shadow mask
rgb_sw <- rgbShadowMask(rgb)
rgb_sw <- focal(rgb_sw, w = mat_w3by3, 
                fun = modal, na.rm = TRUE, pad = TRUE)

## auxilliary dem
dem = raster("../../../../data/bale/dem/dem_srtm_01_utm.tif")
dem = crop(dem, rgb, snap = "out")
dem_vr = focal(dem, w = matrix(c(1, 1, 1, 1, 1, 
                                 1, 1, 1, 1, 1, 
                                 1, 1, 1, 1, 1, 
                                 1, 1, 1, 1, 1, 
                                 1, 1, 1, 1, 1), nc = 5), fun = sd, na.rm = TRUE, pad = TRUE)
dem_vr = focal(dem, w = matrix(c(1, 1, 1, 
                                 1, 1, 1, 
                                 1, 1, 1), nc = 3), fun = sd, na.rm = TRUE, pad = TRUE)
dem_vr = resample(dem_vr, rgb); names(dem_vr) = "dem_variance"

## classification based on k-means clustering with 4 target groups
tir <- resample(tir, rgb)
rgb_all <- stack(rgb, rgb_mv, rgb_sd, rgb_vi, tir)
mat_all <- as.matrix(rgb_all)
kmn_all <- kmeans(mat_all, centers = 4, iter.max = 100, nstart = 10)

raf_all <- randomForest(mat_all)
varImpPlot(raf_all)

## value insertion
luc <- rgb[[1]]
luc[] <- kmn_all$cluster
