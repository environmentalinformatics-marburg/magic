## modis trends
drs <- c("MOD13Q1", "MYD13Q1")

lst <- lapply(drs, function(sensor) {
  fls <- list.files(paste0("data/rasters/alb/", sensor, ".006/mvc"), 
                    pattern = paste0(sensor, ".*.tif$"), full.names = TRUE)
  # fls <- fls[grep("2003001", fls):grep("2015349", fls)]
  rst <- stack(fls)
  
  drs <- gsub("mvc$", "wht", unique(dirname(fls)))
  if (!dir.exists(drs)) dir.create(drs)
  tms <- orgTime(fls)
  wht <- whittaker.raster(rst, timeInfo = tms, lambda = 5000, outDirPath = drs)
  wht <- stack(wht)
  
  ids <- grep("2003001", fls):grep("2015349", fls)
  wht <- wht[[ids]]
  dsn <- deseason(wht, cycle.window = 24L, use.cpp = TRUE)
  dns <- denoise(dsn, expl.var = .95)
  trd <- significantTau(dns, p = .001, prewhitening = FALSE)
  return(trd)
})
