### 'rhdf5' -----

library(raster)
library(rhdf5)

## coordinates
fls <- "/media/fdetsch/XChange/MODIS_ARC/PROBA-V/PROBAV_S5_TOC_X21Y06_20170601_100M_NDVI_V101.HDF5"
fid <- H5Fopen(fls)

crs <- H5Dopen(fid, "crs")
lat <- H5Dopen(fid, "lat"); lat <- H5Dread(lat)
lon <- H5Dopen(fid, "lon"); lon <- H5Dread(lon)
ext <- extent(c(range(lon), range(lat)))

## ndvi
glv <- H5Gopen(fid, "LEVEL3")
gvi <- H5Gopen(glv, "NDVI")
dvi <- H5Dopen(gvi, "NDVI")
vvi <- H5Dread(dvi)
H5close()


read_hdf5_alt <-function(h5file) {
  if (!"rhdf5" %in% installed.packages()) {
    source("https://bioconductor.org/biocLite.R")
    biocLite("rhdf5")
  }
  
  #extract the TOA reflectances for the four spectral bands
  d_red <- h5read(h5file, "LEVEL3/RADIOMETRY/RED/TOA") / 2000
  d_nir <- h5read(h5file, "LEVEL3/RADIOMETRY/NIR/TOA") / 2000
  d_blu <- h5read(h5file, "LEVEL3/RADIOMETRY/BLUE/TOA") / 2000
  d_swi <- h5read(h5file, "LEVEL3/RADIOMETRY/SWIR/TOA") / 2000
}


### 'h5r' -----

read_hdf5 <- function(h5file
                      , crs = "+init=epsg:4326"
                      , no_data = 255
                      , scale_factor = 0.004) {

  ### environment -----
  
  ## open connection to hdf5 file
  h5f <- h5r::H5File(h5file, "r")
  dvi <- h5r::getH5Dataset(h5f, "/LEVEL3/NDVI/NDVI")
  
  
  ### geometry -----
  
  ## resolution
  dpj <- h5r::getH5Dataset(h5f, "crs")
  apj <- h5r::getH5Attribute(dpj, "GeoTransform")
  vpj <- h5r::readH5Data(apj)
  
  tmp <- as.double(unlist(strsplit(vpj, " ")))
  res <- c(tmp[2], tmp[6])

  ## bounding box
  dms <- dim(dvi)
  
  dcr <- h5r::getH5Group(h5f, "/LEVEL3/GEOMETRY")
  crd <- sapply(c("TOP_LEFT_LONGITUDE", "TOP_LEFT_LATITUDE"), function(name) {
    acr <- h5r::getH5Attribute(dcr, name)
    h5r::readH5Data(acr)
  }) 
  
  xmn <- crd[1]; ymx <- crd[2]
  xmx <- xmn + dms[1] * res[1]; ymn <- ymx + dms[2] * res[2]
  
  
  ### data extraction -----

  val <- array(h5r::readH5Data(dvi), dms)
  val[val == no_data] <- NA; val <- val * scale_factor
  
  rst <- raster::raster(val, xmn, xmx, ymn, ymx, crs)
  return(rst)
}

fls1 <- "/media/fdetsch/XChange/MODIS_ARC/PROBA-V/PROBAV_S5_TOC_X21Y06_20170601_100M_NDVI_V101.HDF5"
rst1 <- read_hdf5(fls1)

fls2 <- "/media/fdetsch/XChange/MODIS_ARC/PROBA-V/M0167280/PV_S5_TOC_NDVI_20140311_100M_V101/PROBAV_S5_TOC_X21Y06_20140311_100M_NDVI_V101.hdf5"
rst2 <- read_hdf5(fls2)
