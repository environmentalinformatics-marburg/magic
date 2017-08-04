### environment -----

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
  return(mat)
}

mat_w3by3 = movingWindow(3L, fcl = TRUE)
mat_w5by5 = movingWindow(5L)

## 
tmp = rgeos::gBuffer(lgg, width = 500, quadsegs = 100L)

lc8 <- list.files("data/LC08_L1TP_167055_20170308_20170317_01_T1", 
                  pattern = ".tif$", full.names = TRUE)

# lc8 <- stack(lapply(1:2, function(i) {
#   rst = if (i == 1) stack(lc8[i]) else raster(lc8[i])
#   rst = crop(rst, tmp, snap = "out")
#   writeRaster(rst, filename = lc8[i], overwrite = TRUE, datatype = dataType(rst))
# }))

lc8 = stack(lc8)
rgb = lc8[[1:3]]; tir = lc8[[4]]

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

## classification based on k-means clustering with 4 target groups
rgb_all <- stack(rgb, rgb_mv, rgb_sd, rgb_vi, tir)
mat_all <- as.matrix(rgb_all)

set.seed(12)
kmn_all <- kmeans(mat_all, centers = 4, iter.max = 100, nstart = 10)

# library(randomForest)
# raf_all <- randomForest(mat_all)
# varImpPlot(raf_all)

## value insertion
luc <- rgb[[1]]
luc[] <- kmn_all$cluster
luc <- focal(luc, mat_w3by3, modal, na.rm = TRUE, pad = TRUE, 
             filename = "out/luc-lgg.tif")

## visual comparison
dsm <- stack("data/dsm-lgg.tif")
plotRGB(dsm)
plot(luc, add = TRUE, alpha = .5)

## deregister parallel backend
stopCluster(cl)
