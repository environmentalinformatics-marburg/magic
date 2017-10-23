### environment ----------------------------------------------------------------

## clear workspace
rm(list = ls(all = TRUE))

## set working directory
setwd("dfg_for_bale/p6")

## source functions
ext = readRDS("../inst/extdata/uniformExtent.rds")

## load packages
lib <- c("Rsenal", "MODIS", "doParallel")
Orcs::loadPkgs(lib)

## parallelization
cl <- makeCluster(detectCores() - 1)
registerDoParallel(cl)

## modis options
lap = "E:/MODIS_ARC"
MODISoptions(lap, file.path(lap, "PROCESSED"), outProj = "+init=epsg:32637")


### processing -----

## relevant bits and accepted values in qa layer
mat = matrix(c(7, 8
               , 5, 6
               , 3, 4
               , 1, 2), nc = 2, byrow = TRUE)

ref = list("00"
           , "00"
           , "00"
           , "00")


## loop over single product
prd <- lapply(c("MOD11A1", "MYD11A1"), function(product) {
  
  ## status message
  cat("Commencing with the processing of", product, "...\n")
  
  ## download data
  cll = getCollection(product, forceCheck = TRUE)
  tfs = runGdal(product = product, collection = cll, begin = "2016001"
                , extent = ext, job = "lst-1km-bale-daily"
                , SDSstring = "110011000000")
  
  dst = sapply(tfs[[1]], "[[", 1)
  dqc = sapply(tfs[[1]], "[[", 2)
  nst = sapply(tfs[[1]], "[[", 3)
  nqc = sapply(tfs[[1]], "[[", 4)

  ## target folders
  dir_out <- paste0("E:/bale/modis/", product, ".006")
  if (!dir.exists(dir_out)) dir.create(dir_out)

  ## perform quality control based on companion qc layers ('qc_day', 'qc_night')
  dir_qc <- paste0(dir_out, "/qc")
  if (!dir.exists(dir_qc)) dir.create(dir_qc)
  
  qcl = foreach(lst = list(dst, nst), lqc = list(dqc, nqc)) %do% {
    stack(
      foreach(k = lst, l = lqc, .packages = lib) %dopar% {
        nms = file.path(dir_qc, basename(k))
        if (file.exists(nms)) {
          raster(nms)
        } else {
          overlay(raster(k) * 0.02, raster(l), fun = function(x, y) {
            
            bin = R.utils::intToBin(y[])
            bin = formatC(as.integer(bin), width = 8L, flag = "0")
            
            flags = sapply(1:nrow(mat), function(z) {
              substr(bin, mat[z, 1], mat[z, 2]) == ref[[z]]
            })
            
            ids = apply(flags, 1, function(x) x[1] | x[2] | all(x[3:4]))
            if (any(!ids))
              x[!ids] <- NA
            
            return(x)
          }, filename = nms, format = "GTiff", overwrite = TRUE)
        }
      }
    )
  }
    
  return(qcl)
})

## close parallel backend
stopCluster(cl)