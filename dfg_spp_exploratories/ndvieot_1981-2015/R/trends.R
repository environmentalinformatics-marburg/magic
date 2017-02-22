### environmental stuff -----

## functions
source("R/cellHarmonics.R")
source("R/ndviPhaseShift.R")

## parallelization
library(parallel)
cl <- makePSOCKcluster(3L)


### data processing: trends -----

## loop over research areas
trd <- lapply(c("alb", "hai", "sch"), function(area) {
  
  # status message
  cat("Starting with '", area, "'.\n", sep = "")
  
  # available files
  fls <- list.files(paste0("data/", area), pattern = ".tif$", full.names = TRUE)
  
  # deseasoning
  fls <- fls[grep("1982001", fls):length(fls)] # 1982-2015
  rst <- raster::stack(fls)
  
  raster::beginCluster(parallel::detectCores()); on.exit(raster::endCluster())
  dsn <- raster::clusterR(rst, fun = remote::deseason, 
                          args = list(cycle.window = 24L))
  
  # trend-free pre-whitened mann-kendall test
  trd <- raster::clusterR(dsn, fun = gimms::significantTau, 
                          args = list(p = 0.05, prewhitening = FALSE))

  # write to file
  raster::writeRaster(trd, filename = paste0("out/trd_mk01_", area), 
                      format = "GTiff", overwrite = TRUE)
})


### data processing: seasonality -----

## loop over research areas
trd <- parLapply(cl, c("alb", "hai", "sch"), function(area) {
  
  # available files
  fls <- list.files(paste0("data/", area), pattern = ".tif$", full.names = TRUE)
  
  # start and end period (11 yrs each)
  st <- "1982001"; id_st <- grep(st, fls) 
  rst_st <- raster::stack(fls[id_st:(id_st + (11*24-1))])
  
  nd <- "2005001"; id_nd <- grep(nd, fls)
  rst_nd <- raster::stack(fls[id_nd:(id_nd + (11*24-1))])
  
  # harmonic trend models
  har <-  cellHarmonics(st = rst_st, nd = rst_nd, 
                        st.start = c(1982, 1), st.end = c(1992, 12), 
                        nd.start = c(2005, 1), nd.end = c(2016, 12), 
                        frq = 24L, product = paste0("MCD13Q1.006_", area), 
                        path.out = "out", n.cores = 3L)
  
})

## deregister parallel backend
stopCluster(cl)