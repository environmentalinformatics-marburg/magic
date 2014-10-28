processMCD14A1 <- function(sensors = c("MOD", "MYD"), 
                           indir = ".", 
                           template, 
                           outdir = ".",
                           hdfdir = ".",
                           ...) {
  
  library(raster)
  
  source("src/kifiRemoveDuplicates.R")
  source("src/kifiExtractDoy.R")
  
  ### Data import and cropping
  products <- paste0(sensors, "14A1")
  firemasks <- paste(sensors, "FireMask", sep = ".*")
  
  modis.fire.stacks <- lapply(firemasks, function(i) {
    # Avl files                             
    tmp.fls <- list.files(indir, pattern = i, recursive = TRUE, full.names = TRUE)
    # Import and crop
    tmp.stack <- do.call("stack", lapply(tmp.fls, function(j) {
      rst <- stack(j)
      rst_crp <- crop(rst, template, 
                      filename = paste0(outdir, "/CRP_", basename(j)),  
                      format = "GTiff", bylayer = FALSE, overwrite = TRUE)
      return(rst_crp)
    }))
    
    return(tmp.stack)
  })
  
  # Remove duplicated RasterLayers
  modis.fire.rasters.rmdupl <- 
    kifiRemoveDuplicates(hdf.path = hdfdir, 
                         hdf.pattern = paste(products, ".hdf$", sep = ".*"),
                         data = modis.fire.stacks)
  
  # Import information about availability of MOD/MYD14A1
  modis.fire.avl <- kifiExtractDoy(hdf.path = hdfdir, 
                                   hdf.pattern = paste(products, ".hdf$", sep = ".*"))
  
  
  ### Merge MODIS Terra and Aqua
  
  modis.fire.overlay <- lapply(seq(nrow(modis.fire.avl)), function(i) {
    file_out <- paste0(outdir, "/MRG_CRP_MCD14A1.A", 
                       strftime(modis.fire.avl[i, 1], format = "%Y%j"), 
                       ".FireMask")
    if (modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.stacks[[1]][[modis.fire.avl[i, 3]]], modis.fire.stacks[[2]][[modis.fire.avl[i, 5]]], fun = function(x,y) {x*10+y}, 
              filename = file_out, format = "GTiff", overwrite = TRUE)
    } else if (modis.fire.avl[i, 2] & !modis.fire.avl[i, 4]) {
      overlay(modis.fire.stacks[[1]][[modis.fire.avl[i, 3]]], fun = function(x) {x*10}, 
              filename = file_out, format = "GTiff", overwrite = TRUE)
    } else if (!modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
      overlay(modis.fire.stacks[[2]][[modis.fire.avl[i, 5]]], fun = function(x) {x}, 
              filename = file_out, format = "GTiff", overwrite = TRUE)
    } else {
      NA
    }
  })
  
  
  ### Reclassification
  
  # Reclassification matrix
  rcl.mat <- matrix(c(0, 7, 0,   # --> 0
                      10, 17, 0, 
                      20, 27, 0, 
                      30, 37, 0,
                      40, 47, 0, 
                      50, 57, 0, 
                      60, 67, 0, 
                      70, 77, 0, 
                      8, 9, 1,   # --> 1
                      18, 19, 1, 
                      28, 29, 1, 
                      38, 39, 1,
                      48, 49, 1, 
                      58, 59, 1, 
                      68, 69, 1, 
                      78, 99, 1), ncol = 3, byrow = TRUE)
  
  # Reclassify
  modis_fire_reclass <- lapply(modis.fire.overlay, function(i) {
    if (!is.logical(i)) {
      file_out <- paste0(outdir, "/RCL_", names(i))
      reclassify(i, rcl.mat, right = NA, 
                 filename = file_out, format = "GTiff", overwrite = TRUE)
    } else {
      NA
    }
  })
  
}
