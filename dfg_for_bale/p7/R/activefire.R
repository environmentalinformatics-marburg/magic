### environmental stuff -----

## required packages
lib <- c("MODIS", "doParallel", "rgdal")
Orcs::loadPkgs(lib)

## modis options
os <- switch(Sys.info()[["sysname"]]
             , "Windows" = "F:"
             , "Linux" = file.path(getwd(), "../../data"))

MODISoptions(localArcPath = file.path(os, "MODIS_ARC")
             , outDirPath = file.path(os, "MODIS_ARC/PROCESSED/")
             , outProj = "+init=epsg:32637"
             , MODISserverOrder = c("LAADS", "LPDAAC"))

## working directory and functions
setwd("dfg_for_bale/p7")

source("R/fireDates.R")

## parallelization
cl <- makeCluster(.75 * detectCores())
registerDoParallel(cl)


### data download -----

## download and extract data
cll <- unique(unlist(getCollection("M*D14A1", forceCheck = TRUE)))
if (length(cll) > 1L) stop("More than one unique collection found.\n")

tfs <- runGdal("M*D14A1", extent = readRDS("../inst/extdata/uniformExtent.rds"), 
               collection = cll, SDSstring = "1110", job = "fire-1km-bale")

## remove empty list entries (ie. no file could be found for particular date)
for (i in seq_along(tfs)) {
  len = sapply(tfs[[i]], length)
  if (any(len < 3))
    tfs[[i]] = tfs[[i]][-which(len < 3)]
}


### preprocessing -----

## data folder
dir_dat <- file.path(os, "bale/modis")
if (!dir.exists(dir_dat)) dir.create(dir_dat)

## reclassification matrix
rcl <- matrix(c(0, 7, NA, 
                7, 10, 1, 
                10, 255, NA), ncol = 3, byrow = TRUE)

## loop over products
lst_prd <- foreach(product = names(tfs), .packages = "MODIS") %dopar% {
  
  ## product-specific target folder
  dir_prd <- paste(dir_dat, product, sep = "/")
  if (!dir.exists(dir_prd)) dir.create(dir_prd)
  
  
  ### reclassification -----
  
  ## target folder and files
  dir_rcl <- paste0(dir_prd, "/rcl")
  if (!dir.exists(dir_rcl)) dir.create(dir_rcl)
  
  fls <- unlist(sapply(tfs[[product]], "[[", 1))
  fls_rcl <- paste0(dir_rcl, "/", fls, ".tif")
  
  ## start and end date
  dts <- sapply(c(names(fls[1]), names(fls[length(fls)])), function(z) {
    transDate(z)$beginDOY
  })
  
  fls_rcl <- paste0(dir_rcl, "/", gsub(cll, "", product), 
                    paste(dts, collapse = "_"), ".FireMask.tif")
  
  ## reclassify layers
  Orcs::ifMissing(fls_rcl, raster::brick, raster::reclassify, "filename"
                  , x = stack(fls), rcl = rcl, include.lowest = TRUE
                  , right = FALSE)
}


### combined product -----

## target folder and files
dir_cmb <- paste0(dir_dat, "/MCD14A1.006")
if (!dir.exists(dir_cmb)) dir.create(dir_cmb)

## layer dates
lst_dts <- foreach(product = names(tfs), i = 1:2) %dopar% {
                     
  # list available .hdf files                   
  # dir_hdf <- paste0(getOption("MODIS_localArcPath"), "/MODIS/", product)
  dir_hdf <- file.path("../../../../../../../casestudies/bale/modis", product)
  fls_hdf <- list.files(dir_hdf, pattern = "h21v08.*.hdf$", full.names = TRUE, 
                        recursive = TRUE)
  
  # extract corresponding dates
  dts <- unlist(fireDates(fls_hdf))
  if (length(dts) != nlayers(lst_prd[[i]]))
    stop("Number of layers and dates must be the same.\n")
  
  # remove duplicated layers
  dpl <- which(duplicated(dts))
  lst_prd[[i]] <- lst_prd[[i]][[-dpl]]; dts <- dts[-dpl]

  list(lst_prd[[i]], dts)
}

## combine layers from the same day
dts_terra <- lst_dts[[1]][[2]]; dts_aqua <- lst_dts[[2]][[2]]
dts <- c(dts_terra, dts_aqua)
dts <- sort(unique(dts))

## target files
chr <- format(as.Date(dts), "%Y%j")
fls_cmb <- paste0(dir_cmb, "/MCD14A1.A", chr, ".FireMask.tif")

lst_cmb <- foreach(i = dts, j = seq(dts), .packages = "raster") %dopar% {
  
  if (file.exists(fls_cmb[j])) {
    raster(fls_cmb[j])
  } else {
    avl_terra <- i %in% dts_terra; avl_aqua <- i %in% dts_aqua
    
    if (avl_terra & !avl_aqua) {
      writeRaster(lst_dts[[1]][[1]][[grep(i, dts_terra)]], filename = fls_cmb[j], 
                  format = "GTiff", overwrite = TRUE)
    } else if (!avl_terra & avl_aqua) {
      writeRaster(lst_dts[[2]][[1]][[grep(i, dts_aqua)]], filename = fls_cmb[j], 
                  format = "GTiff", overwrite = TRUE)
    } else if (avl_terra & avl_aqua) {
      id_terra <- grep(i, dts_terra); id_aqua <- grep(i, dts_aqua)
      overlay(lst_dts[[1]][[1]][[id_terra]], lst_dts[[2]][[1]][[id_aqua]], 
              fun = function(x, y) {
                val_x <- x[]; val_y <- y[]
                val_x[!is.na(val_y)] <- val_y[!is.na(val_y)]
                return(val_x)
              }, filename = fls_cmb[j], format = "GTiff", overwrite = TRUE)
    } else {
      stop("Date '", i, "' not present in any of the products.\n")
    }
  }
}

rst_cmb <- stack(lst_cmb); rm(lst_cmb)


### annual fires -----

indices <- format(as.Date(dts), "%Y")
indices <- as.integer(indices)

rst_agg <- stackApply(rst_cmb, indices, fun = sum)

## write to disk
dir_agg <- paste0(dir_cmb, "/agg1yr")
if (!dir.exists(dir_agg)) dir.create(dir_agg)

fls_agg <- paste0(unique(substr(names(rst_cmb), 1, 13)), ".FireMask.tif")
fls_agg <- paste(dir_agg, fls_agg, sep = "/")

rst_agg <- foreach(i = 1:nlayers(rst_agg), .combine = "stack") %do%
  writeRaster(rst_agg[[i]], filename = fls_agg[i], format = "GTiff", 
              overwrite = TRUE)

## fire frequency
rst_frq <- rst_agg / as.integer(table(indices))

dir_frq <- paste0(dir_cmb, "/frq1yr")
if (!dir.exists(dir_frq)) dir.create(dir_frq)

fls_frq <- paste0(unique(substr(names(rst_cmb), 1, 13)), ".FireMask.tif")
fls_frq <- paste(dir_frq, fls_frq, sep = "/")

rst_frq <- foreach(i = 1:nlayers(rst_frq), .combine = "stack") %do%
  writeRaster(rst_frq[[i]], filename = fls_frq[i], format = "GTiff", 
              overwrite = TRUE)

## deregister parallel backend
stopCluster(cl)
