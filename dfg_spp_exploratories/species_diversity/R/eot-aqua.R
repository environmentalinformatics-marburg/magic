### eot -----

## set working directory
setwd("/media/fdetsch/data/exploratories")

library(ESD)
library(TSclust)
library(raster)
library(foreach)
library(remote)

out <- vector("list", 2L); n <- 1
for (exploratory in c("hai", "sch")) {
  
  ## avhrr gimms (predictor)
  gms <- list.files(paste0("data/rasters/", exploratory, "/NDVI3g.v1"), 
                    pattern = "yL5000.ndvi.tif$", full.names = TRUE)
  prd <- gms[grep("2003001", gms):grep("2015349", gms)]
  prd <- stack(prd); gms <- stack(gms)

  ## aqua modis (response)
  mvc <- list.files(paste0("data/rasters/", exploratory, "/MYD13Q1.006/mvc"), 
                    pattern = "^MYD13Q1.*NDVI.tif$", full.names = TRUE)
  
  drs <- gsub("mvc$", "wht", unique(dirname(mvc)))
  # if (!dir.exists(drs)) dir.create(drs)
  # wht <- stack(whittaker.raster(mvc, outDirPath = drs))
  
  fls <- list.files(drs, pattern = "^MCD.*.tif$", full.names = TRUE)
  rsp <- fls[grep("2003001", fls):grep("2015349", fls)]
  rsp <- stack(rsp)

  # ## evaluate eot-based downscaling
  # mtr <- evaluate(pred = prd, resp = rsp, cores = detectCores() - 1, 
  #                 n = 2L,     # calculate 2 EOT modes
  #                 times = 2L, # repeat procedure 2 times
  #                 size = 7L)   # with 7 years of training data
  #   
  # plotRegressionStats(mtr, xlim_rsq = c(0.75, 1.05), xlim_err = c(-0.012, 0.052))
  
  ## perform eot-based downscaling
  drs <- paste0(drs, "/eot")
  if (!dir.exists(drs)) dir.create(drs)
  fls <- paste(drs, names(gms), sep = "/")

  out[[n]] <- downscale(pred = prd, resp = rsp, neot = 10L, newdata = gms, 
                        nprd = 10L, filename = fls)
  n <- n + 1
}

