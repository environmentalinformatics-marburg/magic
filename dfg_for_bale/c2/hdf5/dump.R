### environment -----

## working directory
setwd("dfg_for_bale/c2/hdf5")

## packages and functions
library(raster)

source("read_vi.R")
source("read_qc.R")

## parallelization
library(doParallel)
cl = makeCluster(3L)
registerDoParallel(cl)

## reference extent
ext = readRDS("../../../../bafire/inst/extdata/uniformExtent.rds")
ext = spTransform(ext, CRS("+init=epsg:4326"))

## methods
setMethod('merge', signature(x = 'list', y = 'missing'), 
          function(x, y, tolerance = 0.05, filename = "", ...) {
            
            args <- x
            args$tolerance <- tolerance
            args$filename <- filename
            
            ## additional arguments
            dots <- list(...)
            args <- append(args, dots)
            
            ## perform merge
            do.call(raster::merge, args)
          })


# ### 'rhdf5' -----
# 
# library(rhdf5)
# 
# ## coordinates
# fls <- "/media/fdetsch/XChange/MODIS_ARC/PROBA-V/PROBAV_S5_TOC_X21Y06_20170601_100M_NDVI_V101.HDF5"
# fid <- H5Fopen(fls)
# 
# crs <- H5Dopen(fid, "crs")
# lat <- H5Dopen(fid, "lat"); lat <- H5Dread(lat)
# lon <- H5Dopen(fid, "lon"); lon <- H5Dread(lon)
# ext <- extent(c(range(lon), range(lat)))
# 
# ## ndvi
# glv <- H5Gopen(fid, "LEVEL3")
# gvi <- H5Gopen(glv, "NDVI")
# dvi <- H5Dopen(gvi, "NDVI")
# vvi <- H5Dread(dvi)
# H5close()
# 
# 
# read_hdf5_alt <-function(h5file) {
#   if (!"rhdf5" %in% installed.packages()) {
#     source("https://bioconductor.org/biocLite.R")
#     biocLite("rhdf5")
#   }
#   
#   #extract the TOA reflectances for the four spectral bands
#   d_red <- h5read(h5file, "LEVEL3/RADIOMETRY/RED/TOA") / 2000
#   d_nir <- h5read(h5file, "LEVEL3/RADIOMETRY/NIR/TOA") / 2000
#   d_blu <- h5read(h5file, "LEVEL3/RADIOMETRY/BLUE/TOA") / 2000
#   d_swi <- h5read(h5file, "LEVEL3/RADIOMETRY/SWIR/TOA") / 2000
# }


### 'h5r' -----

library(h5r)

## extract ndvi and status map (sm) layers from hdf5 files
drs_vi = dir("/media/fdetsch/XChange/MODIS_ARC/PROBA-V/M0167280"
             , pattern = "V101$", full.names = TRUE)
dts_vi = substr(basename(drs_vi), 16, 23)
fls_vi = unlist(lapply(drs_vi, function(i) {
  list.files(i, pattern = ".hdf5$", full.names = TRUE)
}))

drs_qc = dir("/media/fdetsch/XChange/MODIS_ARC/PROBA-V/M0167367"
             , pattern = "V101$", full.names = TRUE)
dts_qc = substr(basename(drs_qc), 11, 18)
drs_qc = drs_qc[dts_qc %in% dts_vi]
dts_qc = dts_qc[dts_qc %in% dts_vi]
fls_qc = unlist(lapply(drs_qc, function(i) {
  list.files(i, pattern = ".hdf5$", full.names = TRUE)
}))

lst = lapply(1:length(fls_vi), function(i) {
  cat(i, "of", length(fls_vi), "\n")
  vi = read_vi(fls_vi[i], filename = gsub(".hdf5$", ".tif", fls_vi[i]), 
               datatype = "FLT4S", overwrite = TRUE)
  qc = read_qc(fls_qc[i], filename = gsub("V101.hdf5$", "SM_V101.tif", fls_qc[i]), 
               datatype = "INT1U", overwrite = TRUE)
  stack(vi, qc)
})

## perform quality control
drs_qcl = "/media/fdetsch/XChange/bale/proba-v/qcl/"
nms_qcl = sapply(sapply(lst[seq(1, length(lst), 2)], "[[", 1), names)
nms_qcl = gsub("X21Y06", "X2xY06", nms_qcl)
fls_qcl = paste0(drs_qcl, nms_qcl)

qcl = foreach(i = seq(1, length(lst), 2), .packages = "raster") %dopar% {
  crp = lapply(lst[i:(i+1)], function(j) crop(j, ext, snap = "out"))
  mrg = do.call(merge, crp)
  
  overlay(mrg[[1]], mrg[[2]], fun = function(x, y) {
    bin <- R.utils::intToBin(y[])
    quality <- substr(bin, 6, 8)
    flags = sapply(4:1, function(z) substr(bin, z, z) == 1)
    
    ids = (quality == "000") | (quality == "010" & all(flags))
    x[!ids] <- NA
    
    return(x)
  }, filename = fls_qcl[i], format = "GTiff", datatype = "FLT4S")
}

## close parallel backend
stopCluster(cl)