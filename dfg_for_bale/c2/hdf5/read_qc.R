read_qc <- function(h5file
                    , crs = "+init=epsg:4326"
                    , no_data = 2L
                    , offset = 0L
                    , scale_factor = 1L
                    , filename = ""
                    , ...) {
  
  ### environment -----
  
  ## open connection to hdf5 file
  h5f <- h5r::H5File(h5file, "r"); on.exit(closeAllConnections())
  dvi <- h5r::getH5Dataset(h5f, "/LEVEL3/QUALITY/SM")
  
  
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

  rst <- raster::raster(val, xmn, xmx, ymn, ymx, crs)
  rst <- raster::calc(rst, fun = function(x) {
    x[x == no_data] <- NA
    (x - offset) / scale_factor
  }, filename = filename, ...)
  
  return(rst)
}
