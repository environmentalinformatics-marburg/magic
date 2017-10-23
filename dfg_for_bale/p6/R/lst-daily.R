### environment ----------------------------------------------------------------

## clear workspace
rm(list = ls(all = TRUE))

## set working directory
setwd("dfg_for_bale/p6")

## source functions
ref = readRDS("../inst/extdata/uniformExtent.rds")

## load packages
lib <- c("Rsenal", "MODIS", "doParallel")
Orcs::loadPkgs(lib)

## parallelization
cl <- makeCluster(detectCores() - 1)
registerDoParallel(cl)

## modis options
MODISoptions(localArcPath = "MODIS_ARC", outDirPath = "MODIS_ARC/PROCESSED",
             outProj = "+init=epsg:21037")


### data download --------------------------------------------------------------

## loop over single product
lst <- lapply(c("MOD11A1", "MYD11A1"), function(product) {
  
  ## status message
  cat("Commencing with the processing of", product, "...\n")
  
  # ## download data
  # runGdal(product = product, collection = "005",
  #         begin = "2013001", end = "2015365", tileH = 21, tileV = 9,
  #         SDSstring = c(1, 1, rep(0, 10)), job = paste0(product, ".005"))
  

  ### crop layers ----------------------------------------------------------------
  
  ## retrieve study extent
  ext_crp <- uniformExtent(verbose = FALSE)
  
  ## target folders
  dir_out <- paste0("data/", product, ".005")
  if (!dir.exists(dir_out)) dir.create(dir_out)

  dir_crp <- paste0(dir_out, "/crp")
  if (!dir.exists(dir_crp)) dir.create(dir_crp)
  
  ## perform crop
  pattern <- c("Day_1km", "QC_Day")
  
  # rst_crp <- foreach(i = pattern, .packages = "MODIS") %dopar% {
  # 
  #   # list and import available files
  #   fls <- list.files(paste0(getOption("MODIS_outDirPath"), "/", product, ".005"),
  #                     pattern = paste0(i, ".tif$"), full.names = TRUE)
  #   rst <- raster::stack(fls)
  # 
  #   # crop
  #   fls_crp <- paste(dir_crp, basename(fls), sep = "/")
  #   rst_crp <- raster::crop(rst, ext_crp, snap = "out")
  # 
  #   # if dealing with (day or night) lst bands, convert to 16-bit unsigned
  #   # integer and apply scale factor of 0.02
  #   if (i %in% c("Day_1km", "Night_1km")) {
  #     raster::dataType(rst_crp) <- "INT2U"
  #     rst_crp <- rst_crp * 0.02
  # 
  #   # else convert to 8-bit unsigned integer
  #   } else {
  #     raster::dataType(rst_crp) <- "INT1U"
  # 
  #     # if dealing with (day or night) view time, apply scale factor of 0.1
  #     if (i %in% c("Day_view_time", "Night_view_time")) {
  #       rst_crp <- rst_crp * 0.1
  # 
  #     # if dealing with (day or night) view angle, apply offset of -65
  #     } else if (i %in% c("Day_view_angl", "Night_view_angl")) {
  #       rst_crp <- rst_crp - 65
  #     }
  #   }
  # 
  #   # save and return cropped layers
  #   lst_crp <- lapply(1:nlayers(rst_crp), function(j)
  #     raster::writeRaster(rst_crp[[j]], filename = fls_crp[j],
  #                         format = "GTiff", overwrite = TRUE)
  #   )
  # 
  #   raster::stack(lst_crp)
  # }
  
  ## reimport cropped files
  rst_crp <- foreach(i = pattern, .packages = "raster") %dopar% {
    
    # list and import available files
    fls_crp <- list.files(dir_crp, pattern = paste0(i, ".tif$"), full.names = TRUE)
    stack(fls_crp)
  }
  
  
  ### quality control ----------------------------------------------------------
  ### discard cloudy pixels based on companion quality information ('QC_Day', 
  ### 'QC_Night')
  
  dir_qc <- paste0(dir_out, "/qc")
  if (!dir.exists(dir_qc)) dir.create(dir_qc)
  
  ## perform quality check for day and night separately
  ## loop over layers
  lst_out <- foreach(k = 1:nlayers(rst_crp[[1]]), .packages = lib) %dopar% {
    
    fls_qc <- paste0(dir_qc, "/", names(rst_crp[[1]][[k]]), ".tif")
    if (file.exists(fls_qc)) {
      raster(fls_qc)
    } else {
      overlay(rst_crp[[1]][[k]], rst_crp[[2]][[k]], fun = function(x, y) {
        id <- sapply(y[], function(l) {
          bin <- number2binary(l, 8, TRUE)
          mandatory_qa <- substr(bin, 7, 8)
          data_quality <- substr(bin, 5, 6)
          
          # pixel produced, good quality
          if (mandatory_qa == "00" | data_quality == "00") {
            return(TRUE)
            
            # pixel produced, unreliable or unquantifiable quality
          } else if (mandatory_qa == "01" | data_quality == "01") {
            emis_error <- substr(bin, 3, 4) == "00"
            lst_error <- substr(bin, 1, 2) == "00"
            
            return(all(emis_error, lst_error))
            
            # pixel not produced due to cloud effects or other reasons
          } else {
            return(FALSE)
          }
        })
        
        x[!id] <- NA
        return(x)
      }, filename = fls_qc, overwrite = TRUE, format = "GTiff")
    }
  }

  ## reimport quality-controlled files
  fls_qc <- list.files(dir_qc, pattern = pattern[1], full.names = TRUE)
  rst_qc <- stack(fls_qc)

  return(rst_qc)
})
