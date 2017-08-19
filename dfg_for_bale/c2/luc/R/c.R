## working directory
setwd("/media/fikre/modis_data/Landsat")

## required packages
library(satellite)
library(RStoolbox)

## reference extent
bmnpshp <- shapefile("bale-mountains/bale-mountains.shp")

## digital elevation model (dem)
DEMfile <-list.files("DEM", pattern = "ASTGTM2.*tif", full.names = TRUE)[3]
BaleDEM <-raster(DEMfile)

## import landsat-8 scene
lsatpaths <- dir(pattern = "^LC08|^LO08", full.names = TRUE)
 
for (lsatpath in lsatpaths) {
  cat("Scene", basename(lsatpath), "is in, start processing ...\n")
  
  lsatfiles <-list.files(lsatpath, pattern = glob2rx("LC08*TIF|LO08*TIF"), full.names = TRUE)
  sat <- satellite(lsatfiles)
  
  ## clip images with spatial extent of broader bale mountains region
  sat <- crop(sat, bmnpshp, snap = "out")
  
  ## perform atmospheric correction
  # ?calcAtmosCorr
  sat <- calcAtmosCorr(sat, model = "DOS2", esun_method = "RadRef")
  
  # ## create cloud mask
  # ?cloudMask
  # rst = getSatDataLayers(sat, c("B002n", "B011n"))
  # rst = stack(rst)
  # 
  # cldmsk <- cloudMask(rst, blue = "B002n", tir = "B011n")
  # ndtci = getValues(cldmsk[[2]])
  # summary(ndtci)
  # quantile(ndtci, probs = seq(0, 1, 0.1), na.rm = TRUE)
  # 
  # plot(cldmsk)
  
  ## import dem and add it to 'Satellite' object (including hillshade)
  sat <- addSatDataLayer(sat, data = BaleDEM, info = NULL, bcde = "DEM", in_bcde = names(BaleDEM))
  sat <- demTools(sat)
  
  ## extract raster bands relevant for topographic correction
  bds = getSatBCDE(sat)
  atm = bds[grep("AtmosCorr", bds)]
  rst = getSatDataLayers(sat, atm)
  hsd = getSatDataLayer(sat, "hillShade")
  
  ## import 30-m and 15-m hillshades
  nms30 = gsub("dem.tif$", "dem-30m.tif", DEMfile)
  hsd30 = resample(hsd, rst[[1]], filename = nms30, overwrite = TRUE)
  # hsd30 = raster("DEM/ASTGTM2_N0xE0xx_dem-30m.tif")
  
  nms15 = gsub("dem.tif$", "dem-15m.tif", DEMfile)
  hsd15 = resample(hsd, rst[[8]], filename = nms15, overwrite = TRUE)
  # hsd15 = raster("DEM/ASTGTM2_N0xE0xx_dem-15m.tif")
  
  rm(list = c("sat", "hsd"))
  
  ## target files
  trg = sortFilesLandsat(lsatfiles)[1:9]
  trg = paste(dirname(trg), "corrected", basename(trg), sep = "/")
  trg = gsub(".TIF$", ".tif", trg)
  
  if (!dir.exists(unique(dirname(trg)))) 
    dir.create(unique(dirname(trg)))
  
  ## perform topographic correction
  for (i in 1:length(rst)) {
    if (!file.exists(trg[i])) {
      jnk = calcTopoCorr(rst[[i]], if (i == 8) hsd15 else hsd30, filename = trg[i])
      rm(jnk)
    }
  }
}
