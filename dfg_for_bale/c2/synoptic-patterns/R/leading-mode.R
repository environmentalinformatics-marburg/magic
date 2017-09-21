### environment -----

## required packages
library(remote)
library(parallel)

## working directory
setwd("dfg_for_bale/c2/synoptic-patterns")

## folder paths
dir_dat = "../../../../../data/bale"

## parallelization
n = detectCores()
cl = makePSOCKcluster(0.75 * n)
jnk = clusterEvalQ(cl, library(raster))

## spatial domains
bmn = extent(c(39.3, 40.15, 6.3, 7.25))
jro = extent(c(36.99, 37.75, -3.42, -2.8))
clusterExport(cl, c("bmn", "jro"))


### processing -----

## sea surface temperature
sst = brick(file.path(dir_dat, "sst/sst.mnmean.nc"))

lsm = raster(file.path(dir_dat, "sst/lsmask.nc"))
sst = mask(sst, lsm, maskvalue = 0)

 # 146 deg, 55 min
wio = extent(c(20, 115, -35, 30.5))
sst = crop(sst, wio, snap = "out")

## rainfall
# cps = list.files(file.path(dir_dat, "chirps-2.0/tfs"), pattern = ".tif$"
#                  , full.names = TRUE)
# cps = cps[grep("1981.12", cps):length(cps)]
# clusterExport(cl, "cps")
# 
# cps_crp = parLapply(cl, cps, function(i) {
#   rst = raster(i)
#   list(crop(rst, bmn), crop(rst, jro, snap = "out"))
# })
# 
# cps_bmn = stack(sapply(cps_crp, "[[", 1))
nms_bmn = file.path(dir_dat, "chirps-2.0/chirps-2.0_bale_monthly.tif")
# cps_bmn = writeRaster(cps_bmn, nms_bmn)
cps_bmn = brick(nms_bmn)

# cps_jro = stack(sapply(cps_crp, "[[", 2))
nms_jro = file.path(dir_dat, "chirps-2.0/chirps-2.0_kili_monthly.tif")
# cps_jro = writeRaster(cps_jro, nms_jro)
cps_jro = brick(nms_jro)

## eot model
for (i in 1:2) {
  lst = lagalize(if (i == 1) cps_bmn else cps_jro, sst, 1)
  mod = eot(lst[[2]], lst[[1]], n = 3L)
  
  ## leading mode
  png(paste0("out/", ifelse(i == 1, "bale", "kili"), "_mode01.png")
      , width = 24, height = 16, units = "cm", res = 300)
  plot(mod, show.bp = TRUE) 
  # plot(mod, y = 2, show.bp = TRUE)
  # plot(mod, y = 3, show.bp = TRUE)
  dev.off()
  
  # mds = do.call("rbind", lapply(1:3, function(i) {
  #   data.frame(mod@modes[[i]]@coords_bp, loc = mod@modes[[i]]@name)
  # }))
  # 
  # coordinates(mds) = ~ x + y
  # proj4string(mds) = "+init=epsg:4326"
  # 
  # mapview::mapview(mds) + sst[[1]]
}

## close parallel backend
stopCluster(cl)
