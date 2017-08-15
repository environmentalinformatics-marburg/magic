### environment -----

## working directory
setwd("dfg_for_bale/c2/hdf5")

options(stringsAsFactors = FALSE)

## packages
# devtools::install_github("environmentalinformatics-marburg/remote", ref = "develop")
library(remote)
library(MODIS)


### downscaling -----

## proba-v
prv = list.files("/media/fdetsch/XChange/bale/proba-v/mvc", 
                 pattern = ".tif$", full.names = TRUE)
dts = substr(basename(prv), 22, 29)
dat = data.frame(date = dts, proba = prv)

## modis
mcd = list.files("/media/fdetsch/XChange/bale/modis/MCD13Q1.006/mmvc", 
                 pattern = ".tif$", full.names = TRUE)
dts = format(MODIS::extractDate(mcd, asDate = TRUE)$inputLayerDates, "%Y%m%d")
dat = merge(dat, data.frame(date = dts, modis = mcd), by = "date", all.x = TRUE)

prv = stack(dat$proba); mcd = stack(dat$modis)

otm = MODIS::orgTime(as.Date(dat$date, "%Y%m%d"))
prv_wht = whittaker.raster(prv, timeInfo = otm, lambda = 500L, 
                           outDirPath = "/media/fdetsch/XChange/bale/proba-v/mvc/wht/")
mcd_wht = whittaker.raster(mcd, timeInfo = otm, lambda = 500L, 
                           outDirPath = "/media/fdetsch/XChange/bale/modis/MCD13Q1.006/mmvc/wht/")

## fit eot model
mod = eot(mcd_wht, prv_wht, n = 3L)
