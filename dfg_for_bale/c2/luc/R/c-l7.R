## import landsat-8 scene
lsatpaths <- dir(odr, pattern = "^LE07", full.names = TRUE)

for (lsatpath in lsatpaths) {
  cat("Scene", basename(lsatpath), "is in, start processing ...\n")
  
  ## if corrected files exist, jump to next landsat scene
  crr = dir(lsatpath, pattern = "corrected", full.names = TRUE)
  if (length(crr) == 1) {
    crr_fls = list.files(crr, pattern = ".tif$")
    if (length(crr_fls) == 7) {
      next 
    } else if (length(crr_fls) > 7) {
      stop("Something is wrong.\n")
    }
  } else if (length(crr) > 1) {
    stop("Something is wrong.\n")
  }
  
  lsatfiles <-list.files(lsatpath, pattern = glob2rx("LE07*TIF"), full.names = TRUE)
  sat <- satellite(lsatfiles)
  
  ## clip images with spatial extent of broader bale mountains region
  sat <- crop(sat, bmnpshp, snap = "out")
  
  ## remove black margins based on information in quality layer  
  bds = getSatBCDE(sat)
  m30 = which(!bds %in% c("B008n", "B0QAn"))
  r30 = stack(getSatDataLayers(sat, bds[m30]))
  r15 = getSatDataLayer(sat, "B008n")
  
  m15 = which(bds == "B008n")
  rqa = getSatDataLayer(sat, "B0QAn")
  r30 = mask(r30, rqa, maskvalue = 1)
  sat@layers[m30] = unstack(r30)
  
  rqa = resample(rqa, r15, method = "ngb")
  r15 = mask(r15, rqa, maskvalue = 1)
  sat@layers[[m15]] = r15
  
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
  nms30 = gsub("dem.tif$", "dem_30m.tif", attr(BaleDEM@file, "name"))
  hsd30 = resample(hsd, rst[[1]], filename = nms30, overwrite = TRUE)
  
  nms15 = gsub("dem.tif$", "dem_15m.tif", attr(BaleDEM@file, "name"))
  hsd15 = resample(hsd, rst[[7]], filename = nms15, overwrite = TRUE)
  
  ## target files
  trg = lsatfiles[c(1:5, 8:9)]
  trg = file.path(dirname(trg), "corrected", basename(trg))
  trg = gsub(".TIF$", ".tif", trg)
  
  dsn = unique(dirname(trg))
  jnk = ifMissing(dsn, file.path, dir.create, "path")
  
  ## perform topographic correction
  for (i in 1:length(rst)) {
    if (!file.exists(trg[i])) {
      jnk = calcTopoCorr(rst[[i]], if (i == 7) hsd15 else hsd30, filename = trg[i])
    }
  }; try(rm(jnk), silent = TRUE)
  
  jnk = file.remove(list.files(tmpDir(), full.names = TRUE))
}
