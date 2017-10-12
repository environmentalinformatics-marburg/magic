### environment -----

## clear workspace
rm(list = ls(all = TRUE))

## load packages
lib <- c("reset", "parallel")
Orcs::loadPkgs(lib)

## set working directory
setwd("/media/fdetsch/modis_data/RapidEye")

## reference extent
source("/home/fdetsch/repo/exploratories/R/rapideye-extents.R")

## parallelization
cl <- makePSOCKcluster(detectCores() - 1)
jnk <- clusterEvalQ(cl, library(reset))

## required sds
prm <- c("Total_Ozone", "Water_Vapor")
clusterExport(cl, c("prm", "ref"))


### ozone and water vapor -----

## loop over products
for (product in c("MOD07_L2", "MYD07_L2")) {
  
  ## status message
  cat("Commencing with processing of", product, "...\n")
  
  ## list available files and remove duplicates
  fls <- list.files(file.path("../MODIS_ARC/MODIS", product), full.names = TRUE
                    , recursive = TRUE, pattern = paste(product, "006", ".hdf$", sep = ".*"))
  
  if (anyDuplicated(basename(fls)) != 0) {
    dpl <- which(duplicated(basename(fls)))
    jnk <- file.remove(fls[dpl])
    fls <- fls[-dpl]
  }
  
  ## sort by datetime and stop if any date is missing
  mtd <- Orcs::list2df(strsplit(basename(fls), "\\."), stringsAsFactors = FALSE)
  names(mtd) <- c("product", "date", "time", "collection", "processing", "filetype")
  
  mtd$datetime <- strptime(paste(mtd$date, mtd$time), format = "A%Y%j %H%M")
  fls <- fls[order(mtd$datetime)]; # mtd <- mtd[order(mtd$datetime), ]
  
  
  ### process coordinates -----
  
  # ## discard nighttime scenes (infrared-based, i.e. 5 km spatial resolution)
  # tms <- as.numeric(getSwathTime(fls)) 
  # fls <- fls[tms >= 600 & tms <= 1800]
  
  ## discard scenes not covering reference extent
  lst_ext <- vector("list", length(fls)); n <- 1
  for (i in fls) { 
    if (n %% 100 == 0) cat("Completed", n, "out of", length(fls), "files ...\n")
    lst_ext[[n]] <- try(reset::getSwathExtent(i), silent = TRUE); n <- n + 1
  }
  
  inside <- parSapply(cl, lst_ext, function(i) {
    if (!inherits(i, "try-error")) {
      rgeos::gIntersects(Orcs::ext2spy(i), ref[1, ]) |
        rgeos::gIntersects(Orcs::ext2spy(i), ref[2, ]) |
        rgeos::gIntersects(Orcs::ext2spy(i), ref[3, ])
    } else {
      FALSE
    }
  })
  
  if (any(!inside)) {
    jnk <- file.remove(fls[!inside])
    fls <- fls[inside]
  } 
  
  ## extract relevant sds
  dsn = file.path("modis", product)
  jnk = Orcs::ifMissing(dsn, fun0 = invisible, fun1 = dir.create, arg1 = "path")
  
  clusterExport(cl, c("product", "dsn"))
  parLapply(cl, fls, function(i) {
    sds <- getSwathSDS(i, prm = prm, dsn = dsn)[[1]]
    stack(sds)
  })
}


### aerosol optical depth -----

for (product in c("MOD08_D3", "MYD08_D3")) {
  fls <- list.files(file.path("../MODIS_ARC/MODIS", product), full.names = TRUE
                    , recursive = TRUE, pattern = paste(product, "006", ".hdf$", sep = ".*"))
  
  dsn = file.path("modis", product)
  jnk = Orcs::ifMissing(dsn, fun0 = invisible, fun1 = dir.create, arg1 = "path")
  
  getSwathSDS(fls, prm = "Aerosol_Optical_Depth_Land_Ocean", dsn = dsn)[[1]]
}

## deregister parallel backend
stopCluster(cl)
