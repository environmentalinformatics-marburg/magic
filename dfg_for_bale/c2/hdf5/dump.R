### environment -----

## working directory
setwd("dfg_for_bale/c2/hdf5")

options(stringsAsFactors = FALSE)

## packages and functions
library(raster)

source("read_vi.R")
source("read_qc.R")

## parallelization
library(parallel)
cl = makePSOCKcluster(3L)

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
             , full.names = TRUE)
dts_vi = substr(basename(drs_vi), 16, 23)
vrs_vi = substr(basename(drs_vi), 30, 33)
fls_vi = unlist(lapply(drs_vi, function(i) {
  list.files(i, pattern = ".hdf5$", full.names = TRUE)
}))
nms_vi = gsub(".hdf5$", ".tif", fls_vi)
tls_vi = substr(basename(fls_vi), 15, 20)
dat_vi = data.frame(dts = rep(dts_vi, each = 2), tls = tls_vi, 
                    vrs = rep(vrs_vi, each = 2), ifl = fls_vi, ofl = nms_vi)

drs_qc = dir("/media/fdetsch/XChange/MODIS_ARC/PROBA-V/M0167367"
             , full.names = TRUE)
dts_qc = substr(basename(drs_qc), 11, 18)
vrs_qc = substr(basename(drs_qc), 25, 28)
fls_qc = unlist(lapply(drs_qc, function(i) {
  list.files(i, pattern = ".hdf5$", full.names = TRUE)
}))
nms_qc = gsub("V101.hdf5$", "SM_V101.tif", fls_qc)
nms_qc = gsub("V102.hdf5$", "SM_V102.tif", nms_qc)
tls_qc = substr(basename(fls_qc), 15, 20)
dat_qc = data.frame(dts = rep(dts_qc, each = 2), tls = tls_qc, 
                    vrs = rep(vrs_qc, each = 2), ifl = fls_qc, ofl = nms_qc)

dat_pv = merge(dat_vi, dat_qc, by = c("dts", "tls", "vrs"), all = TRUE)
rm(list = c("dat_vi", "dat_qc"))

dat_na = dat_pv[is.na(dat_pv$ifl.x) & !is.na(dat_pv$ifl.y), ]
tmp = gsub("V101.hdf5", "NDVI_V101.tif", dat_na$ifl.y)
dat_na$ofl.x = gsub("V102.hdf5", "NDVI_V102.tif", tmp)
ids = as.integer(row.names(dat_na))
dat_pv$ofl.x[ids] = dat_na$ofl.x
ids = sapply(dat_na$dts, function(i) i %in% dat_pv[complete.cases(dat_pv), "dts"])
ids = as.integer(row.names(dat_na[ids, ]))
dat_pv = dat_pv[-ids, ]

dpl = names(which(table(dat_pv$dts) > 2))
for (i in dpl) {
  dat_pv = subset(dat_pv, dts != i | vrs == "V101")
}

lst = lapply(1:nrow(dat_pv), function(i, verbose = FALSE) {
  if (verbose) cat(i, "of", nrow(dat_pv), "\n")
  
  ifl_vi = dat_pv[i, "ifl.x"]; ofl_vi = dat_pv[i, "ofl.x"]
  if (is.na(ifl_vi)) ifl_vi = dat_pv[i, "ifl.y"]
  ifl_qc = dat_pv[i, "ifl.y"]; ofl_qc = dat_pv[i, "ofl.y"]
  
  vi = ifMissing(ofl_vi, fun0 = raster, fun1 = read_vi, arg1 = "filename", 
                 h5file = ifl_vi, datatype = "FLT4S")
  qc = ifMissing(ofl_qc, fun0 = raster, fun1 = read_qc, arg1 = "filename", 
                 h5file = ifl_qc, datatype = "INT1U")
  stack(vi, qc)
})

## perform quality control
drs_qcl = "/media/fdetsch/XChange/bale/proba-v/qcl/"
nms_qcl = sapply(sapply(lst[seq(1, length(lst), 2)], "[[", 1), names)
nms_qcl = gsub("X21Y06", "X2xY06", nms_qcl)
fls_qcl = paste0(drs_qcl, nms_qcl, ".tif")

fun = function(x, ext, filename = "") {
  crp = lapply(x, function(j) raster::crop(j, ext, snap = "out"))
  mrg = do.call(raster::merge, crp)
  
  raster::overlay(mrg[[1]], mrg[[2]], fun = function(x, y) {
    bin <- R.utils::intToBin(y[])
    quality <- substr(bin, 6, 8)
    flags = sapply(4:1, function(z) substr(bin, z, z) == 1)
    
    ids = (quality == "000") | (quality == "010" & all(flags))
    x[!ids] <- NA
    
    return(x)
  }, filename = filename, datatype = "FLT4S")
}

jnk = clusterEvalQ(cl, library(Orcs))
clusterExport(cl, c("lst", "ext", "fls_qcl", "fun"))

qcl = parLapply(cl, seq(1, length(lst), 2), function(i) {
  ifMissing(fls_qcl[(i+1)/2], fun0 = raster, fun1 = fun, arg1 = "filename", 
            x = lst[i:(i+1)], ext = ext)
})
qcl = stack(qcl)

## create monthly composites
drs_mvc = gsub("qcl/$", "mvc/", drs_qcl)
jnk = ifMissing(drs_mvc, file.path, dir.create, arg1 = "path")

dts = as.Date(unique(dat_pv$dts), "%Y%m%d") + 2
mts = format(dts, "%Y%m")

nms_mvc = paste0("PROBAV_S5_TOC_X2xY06_"
                 , paste0(unique(mts), "01")
                 , "_100M_NDVI_V101.tif")
fls_mvc = paste0(drs_mvc, nms_mvc)

mvc = gimms::monthlyComposite(qcl, mts, cores = 3L)
mvc = lapply(1:nlayers(mvc), function(i) {
  ifMissing(fls_mvc[i], raster, arg1 = "filename", x = mvc[[i]], datatype = "FLT4S")
})
mvc = stack(mvc)

## create half-monthly composites
drs_fvc = gsub("qcl/$", "fvc/", drs_qcl)
jnk = ifMissing(drs_fvc, file.path, dir.create, arg1 = "path")

ivl = MODIS::aggInterval(dts, "fortnight")
fns = sapply(dts, function(i) which(ivl$begin <= i & ivl$end >= i))
nms_fvc = paste0("PROBAV_S5_TOC_X2xY06_"
                 , format(ivl$begin[unique(fns)], "%Y%m%d")
                 , "_100M_NDVI_V101.tif")
fls_fvc = paste0(drs_fvc, nms_fvc)

fvc = gimms::monthlyComposite(qcl, fns, cores = 3L)
fvc = lapply(1:nlayers(fvc), function(i) {
  ifMissing(fls_fvc[i], raster, arg1 = "filename", x = fvc[[i]], datatype = "FLT4S")
})
fvc = stack(fvc)

## close parallel backend
stopCluster(cl)
