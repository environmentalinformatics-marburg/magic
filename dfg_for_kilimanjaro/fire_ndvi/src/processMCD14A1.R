processMCD14A1 <- function(sensors = c("MOD", "MYD"), 
                           exe_crop = TRUE,
                           exe_merge = TRUE,
                           exe_reclass = TRUE,
                           indir = ".", 
                           template, 
                           outdir = ".",
                           hdfdir = ".",
                           confidence = c("nominal", "low", "high"),
                           ...) {
  
  library(raster)
  
  source("src/kifiRemoveDuplicates.R")
  source("src/kifiExtractDoy.R")
  source("src/kifiRclMat.R")
  
  ### Data import and cropping
  products <- paste0(sensors, "14A1")
  firemasks <- paste(sensors, "FireMask", sep = ".*")
  
  modis.fire.stacks <- lapply(firemasks, function(i) {
    
    # Avl files                             
    tmp.fls <- list.files(indir, pattern = i, recursive = TRUE, full.names = TRUE)
    
    if (exe_crop) {
      # Import and crop
      tmp.stack <- do.call("stack", lapply(tmp.fls, function(j) {
        rst <- stack(j)
        rst_crp <- crop(rst, template, 
                        filename = paste0(outdir, "/CRP_", basename(j)),  
                        format = "GTiff", bylayer = FALSE, overwrite = TRUE)
        return(rst_crp)
      }))
      
      return(tmp.stack)
    } else {
      
      tmp.fls <- paste0(outdir, "/CRP_", basename(tmp.fls))
      tmp.stack <- stack(tmp.fls)
      
      return(tmp.stack)
    }
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
  
  if (exe_merge) {
    modis.fire.overlay <- lapply(seq(nrow(modis.fire.avl)), function(i) {
      file_out <- paste0(outdir, "/MRG_CRP_MCD14A1.A", 
                         strftime(modis.fire.avl[i, 1], format = "%Y%j"), 
                         ".FireMask")
      if (modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
        overlay(modis.fire.rasters.rmdupl[[1]][[modis.fire.avl[i, 3]]], modis.fire.rasters.rmdupl[[2]][[modis.fire.avl[i, 5]]], fun = function(x,y) {x*10+y}, 
                filename = file_out, format = "GTiff", overwrite = TRUE)
      } else if (modis.fire.avl[i, 2] & !modis.fire.avl[i, 4]) {
        overlay(modis.fire.rasters.rmdupl[[1]][[modis.fire.avl[i, 3]]], fun = function(x) {x*10}, 
                filename = file_out, format = "GTiff", overwrite = TRUE)
      } else if (!modis.fire.avl[i, 2] & modis.fire.avl[i, 4]) {
        overlay(modis.fire.rasters.rmdupl[[2]][[modis.fire.avl[i, 5]]], fun = function(x) {x}, 
                filename = file_out, format = "GTiff", overwrite = TRUE)
      } else {
        NA
      }
    })
  } else {
    tmp_fls <- list.files(outdir, pattern = "^MRG_CRP_MCD14A1.A", full.names = TRUE)
    modis.fire.overlay <- lapply(tmp_fls, raster)
  }
  
  
  ### Reclassification
  
  if (exe_reclass) {
    # Reclassification matrix
    rcl.mat <- kifiRclMat(confidence = confidence)
    
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
    
  } else {
    
    tmp_fls <- list.files(outdir, pattern = "^RCL_", full.names = TRUE)
    modis_fire_reclass <- lapply(tmp_fls, raster)
  }
  
  return(modis_fire_reclass)
}
