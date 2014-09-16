# NDVI function
source("src/stateCheck.R")
source("src/ndvi.R")

# Band 1
fls.b1 <- list.files("MODIS_ARC/PROCESSED/", pattern = "MYD09GQ.*b01", 
                     recursive = TRUE, full.names = TRUE)
date.b1 <- as.Date(substr(basename(fls.b1), 10, 16), format = "%Y%j")
df.b1 <- data.frame(date.b1, fls.b1, stringsAsFactors = FALSE)

# Band 2
fls.b2 <- list.files("MODIS_ARC/PROCESSED/", pattern = "MYD09GQ.*b02", 
                     recursive = TRUE, full.names = TRUE)
date.b2 <- as.Date(substr(basename(fls.b2), 10, 16), format = "%Y%j")
df.b2 <- data.frame(date.b2, fls.b2, stringsAsFactors = FALSE)

# State 
fls.qa <- list.files("MODIS_ARC/PROCESSED/", pattern = "MYD09GA.*state_1km", 
                     recursive = TRUE, full.names = TRUE)
date.qa <- as.Date(substr(basename(fls.qa), 10, 16), format = "%Y%j")
df.qa <- data.frame(date.qa, fls.qa, stringsAsFactors = FALSE)

# Time frame
date <- seq(as.Date("2003-01-01"), as.Date("2013-12-31"), 1)

df.b1.b2.qa <- Reduce(function(...) merge(..., all = TRUE, by = 1), 
                      list(data.frame(date = date), df.b1, df.b2, df.qa))

rst.ndvi <- foreach(i = 1541:nrow(df.b1.b2.qa), .packages = lib) %dopar% {
  fls <- unlist(df.b1.b2.qa[i, 2:4])

  # Return NULL if band_1, band_2, or state_1km is missing
  if (any(is.na(df.b1.b2.qa[i, ])))
    return(NULL)
  
  rst <- lapply(fls, function(j) {
    tmp.rst <- raster(j)
    tmp.rst <- crop(tmp.rst, template.rst.utm, 
                    filename = paste0("myd09gq/processed/CRP_", basename(j)),  
                    overwrite = TRUE)
    if (length(grep("state_1km", j)) > 0) { 
      tmp.rst <- 
        disaggregate(tmp.rst, fact = 4, 
                     filename = paste0("myd09gq/processed/DAG_", names(tmp.rst)), 
                     format = "GTiff", overwrite = TRUE)
    }
    return(tmp.rst)
  })
  
  ## Quality control:
  ## Reject all cloud contaminated cells in MYD09GQ bands 1 and 2 based on 
  ## corresponding cloud information in MYD09GA
  rst.cc <- lapply(c(1, 2), function(j) {
#     overlay(rst[[j]], rst[[3]], 
#             fun = function(x, y) {
#               index <- sapply(y[], function(i) {
#                 if (!is.na(i)) {
#                   # 16-bit string
#                   bit <- number2binary(i, 16)
#                   # Cloud state
#                   state <- paste(bit[c(15, 16)], 
#                                  collapse = "") %in% c("00", "11", "10")
#                   # # Shadow
#                   # shadow <- bit[14] == 0
#                   # Cirrus
#                   cirrus <- paste(bit[c(7, 8)], 
#                                   collapse = "") %in% c("00", "01")
#                   # Intern cloud algorithm
#                   intcl <- bit[6] == 0
#                   # Snow mask
#                   snow <- bit[4] == 0
#                   # Adjacent clouds
#                   adjcl <- bit[3] == 0
#                   
#                   return(all(state, snow, cirrus, intcl, adjcl))
#                 } else {
#                   return(FALSE)
#                 }
#               })
#               x[!index] <- NA
#               return(x)
#             }, filename = paste0("myd09gq/processed/CC_", names(rst[[j]])), 
#             overwrite = TRUE, format = "GTiff")
    
    stateCheck(band = rst[[j]], state = rst[[3]], 
               check_id = c(1, 0, 1, 1, 1, 1), 
               filename = paste0("myd09gq/processed/CC_", names(rst[[j]])), 
               overwrite = TRUE, format = "GTiff")
  })
  
  ## NDVI calculation
#   rst.ndvi <- (rst.cc[[2]]-rst.cc[[1]]) / (rst.cc[[2]]+rst.cc[[1]])
#   rst.ndvi <- round(rst.ndvi, digits = 3)
#   if (any(rst.ndvi[] > 1, na.rm = TRUE))
#     rst.ndvi[rst.ndvi[] > 1] <- 1
#   
#   rst.ndvi <- writeRaster(rst.ndvi, format = "GTiff", overwrite = TRUE, 
#                           filename = paste0("myd09gq/processed/NDVI_", 
#                                             substr(basename(fls), 1, 16)[1]))
  
  rst.ndvi <- ndvi(red = rst.cc[[1]], nir = rst.cc[[2]], 
                   filename = paste0("myd09gq/processed/NDVI_", 
                                     substr(basename(fls), 1, 16)[1]), 
                   format = "GTiff", overwrite = TRUE)
  
  return(rst.ndvi)
}

# Reimport daily NDVI data
fls.ndvi <- list.files("myd09gq/processed/", pattern = "^NDVI_MYD09GQ", 
                       full.names = TRUE)
rst.ndvi <- stack(fls.ndvi)

# Extract indices for monthly aggregation
df.b1.b2.qa.cc <- df.b1.b2.qa[complete.cases(df.b1.b2.qa), ]
months <- as.yearmon(df.b1.b2.qa.cc[, 1])
indices <- as.numeric(as.factor(months))
df.b1.b2.qa.cc$id <- indices

# Output names of monthly NDVI data
outnames.prefix <- unique(sapply(strsplit(names(rst.ndvi), ".A"), "[[", 1))
outnames.suffix <- strftime(unique(months), format = "%Y%m")
outnames <- paste(outnames.prefix, outnames.suffix, sep = "_")

# Monthly aggregation
# rst.ndvi.mnthly <- 
#   stackApply(rst.ndvi, indices = indices, fun = max, 
#              filename = paste0("myd09gq/processed/", outnames.prefix), 
#              format = "GTiff", overwrite = TRUE, bylayer = TRUE, 
#              suffix = outnames.suffix)
# 
# rst.ndvi.mnthly <- stackApply(rst.ndvi, indices = indices, fun = max)
# rst.ndvi.mnthly <- 
#   writeRaster(rst.ndvi.mnthly, format = "GTiff", overwrite = TRUE, 
#               filename = paste0("myd09gq/processed/max/", outnames.prefix, "_"), 
#               suffix = outnames.suffix, bylayer = TRUE)

indices <- formatC(as.numeric(as.factor(months)), width = 3, flag = 0)
df.b1.b2.qa.cc$id <- indices

rst.ndvi.mnthly <- 
  foreach(i = unique(indices), .packages = lib, .combine = "stack") %dopar% {
    id <- grep(i, df.b1.b2.qa.cc$id)
    tmp <- rst.ndvi[[id]]
    overlay(tmp, fun = function(...) median(..., na.rm = TRUE), unstack = TRUE)
  }

rst.ndvi.mnthly <- 
  writeRaster(rst.ndvi.mnthly, format = "GTiff", overwrite = TRUE, 
              filename = paste0("myd09gq/processed/median/", outnames.prefix), 
              suffix = outnames.suffix, bylayer = TRUE)

fls.ndvi.mnthly <- list.files("myd09gq/processed/median", pattern = ".tif$", 
                              full.names = TRUE)
rst.ndvi.mnthly <- stack(fls.ndvi.mnthly)

months <- unlist(strsplit(sapply(strsplit(basename(fls.ndvi.mnthly), "Q_"), 
                                 "[[", 2), ".tif"))
julday <- strftime(as.yearmon(months, "%Y%m"), "%Y%j")

rst.ndvi.mnthly <- 
  writeRaster(rst.ndvi.mnthly, format = "GTiff", overwrite = TRUE, 
              filename = paste0("myd09gq/processed/median/", outnames.prefix), 
              suffix = julday, bylayer = TRUE)

fls.ndvi.mnthly <- list.files("myd09gq/processed/median", 
                              pattern = "NDVI_MYD09GQ.*.tif$", 
                              full.names = TRUE)
rst.ndvi.mnthly <- stack(fls.ndvi.mnthly)

library(MODIS)

time_info <- orgTime(basename(fls.ndvi.mnthly), pos1 = 14, pos2 = 20)

?whittaker.raster
whittaker.raster(rst.ndvi.mnthly, timeInfo = time_info, lambda = "6000", 
                 outDirPath = "myd09gq/processed/median/", overwrite = TRUE)

fls.wht <- list.files("myd09gq/processed/median", pattern = "FixedLambda.*.tif$", 
                      full.names = TRUE)
rst.wht <- stack(fls.wht)
