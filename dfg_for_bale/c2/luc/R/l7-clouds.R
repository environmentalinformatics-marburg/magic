library(Rcpp)
sourceCpp("dfg_for_bale/c2/luc/R/int2bin.cpp")

library(raster)
drs = dir("../../data/bale/landsat", pattern = "^LE07", full.names = TRUE)

library(parallel)
cl = makePSOCKcluster(8L)
jnk = clusterEvalQ(cl, library(raster))

lst = parLapply(cl, drs[1:2], function(i) {
  fls = list.files(file.path(i, "corrected"), pattern = "^LE07.*.tif$"
                   , full.names = TRUE)
  rst = stack(fls[1:3])
  msk = calc(rst, fun = function(x) if (all(is.na(x))) NA else 1)
  
  list(rst, msk)
})

library(RStoolbox)
hsm = histMatch(lst[[1]][[1]], lst[[2]][[1]], lst[[1]][[2]], lst[[2]][[2]])

mrg = merge(lst[[2]][[1]], hsm)
plotRGB(mrg, r = 3, b = 1, stretch = "hist")


fls = list.files(i, pattern = "^LE07.*.tif$", full.names = TRUE, ignore.case = TRUE)
sat = satellite(fls)

qcl = function(x, cc = "high", cs = "high") {
  
  ## substring start and stop positions
  mat = matrix(c(
    16, 16   # designated fill
    , 15, 15 # dropped pixel (tm, etm+), terrain occlusion (oli)
    # , 13, 14 # radiometric saturation
    , 12, 12 # cloud
    , 10, 11 # cloud confidence
    , 8, 9   # cloud shadow confidence
    , 6, 7   # snow/ice confidence
    , 4, 5   # cirrus confidence (oli)
  ), nc = 2L, byrow = TRUE)
  
  ## default values
  dft = list(
            "0"     # designated fill: no
            , "0"   # dropped pixel (tm, etm+), terrain occlusion (oli): no
            # , c("00", "01", "10", "11")  # radiometric saturation: no bands contain saturation
            , "0"   # cloud: no
            , c("00", "01")  # cloud confidence: high
            , c("00", "01")  # cloud shadow confidence: high
            , c("00", "01")  # snow/ice confidence: high
            , c("00", "01")  # cirrus confidence: high
  ) 
  
  
  qcl = getSatDataLayer(x, "B0QAn")
  rst = getSatDataLayers(x, getSatBCDESolar(x))
  raster::overlay(rst[[1]], crop(qcl, rst[[1]]), fun = function(x, y) {
    
    bin = vec2bin(y[])
    
    flags = sapply(1:nrow(mat), function(z) {
      substr(bin, mat[z, 1], mat[z, 2]) %in% dft[[z]]
    })
    
    ids = apply(flags, 1, all)
    x[!ids] <- NA
    return(x)
  }
  
}