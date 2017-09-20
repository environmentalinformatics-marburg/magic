### environment -----

## working directory
setwd("dfg_for_bale/c2/hdf5")

## packages
.libPaths(c("/media/sd19006/data/users/fdetsch/R-Server/R", .libPaths()))

library(remote)
library(MODIS)

## options
options(stringsAsFactors = FALSE)

lap = "/media/sd19006/data/users/fdetsch/R-Server/data/MODIS_ARC"
MODISoptions(lap, file.path(lap, "PROCESSED"))


### downscaling -----

## proba-v
prv = list.files("../../../../../data/bale/proba-v/mvc", 
                 pattern = ".tif$", full.names = TRUE)
dts = substr(basename(prv), 22, 29)
dat = data.frame(date = dts, proba = prv)

## modis
mcd = list.files("../../../../../data/bale/modis/MCD13Q1.006/mmvc", 
                 pattern = ".tif$", full.names = TRUE)
dts = format(extractDate(mcd, asDate = TRUE)$inputLayerDates, "%Y%m%d")
dat = merge(dat, data.frame(date = dts, modis = mcd), by = "date", all.x = TRUE)

prv = stack(dat$proba); mcd = stack(dat$modis)

otm = MODIS::orgTime(as.Date(dat$date, "%Y%m%d"))
prv_wht = whittaker.raster(prv, timeInfo = otm, lambda = 500L, overwrite = TRUE,
                           outDirPath = "../../../../../data/bale/proba-v/mvc/wht/")
mcd_wht = whittaker.raster(mcd, timeInfo = otm, lambda = 500L, overwrite = TRUE,
                           outDirPath = "../../../../../data/bale/modis/MCD13Q1.006/mmvc/wht/")

## fit eot model
ext = extent(c(581162, 589180, 792370, 798555))
tmp1 = crop(mcd_wht, ext)

ext_ll = extent(projectExtent(tmp1, crs = "+init=epsg:4326"))
tmp2 = crop(prv_wht, ext_ll, snap = "in")
tmp2 = trim(projectRaster(tmp2, crs = "+init=epsg:32637"))

mod = eot(tmp1, tmp2, n = 10L)
