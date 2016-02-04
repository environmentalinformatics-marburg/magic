# # Working directory
# switch(Sys.info()[["sysname"]], 
#        "Linux" = {path.wd <- "/media/envin/XChange/kilimanjaro/ndvi"}, 
#        "Windows" = {path.wd <- "D:/kilimanjaro/ndvi"})
# setwd(path.wd)

# Packages and functions
lib <- c("raster", "rgdal", "TSA", "RColorBrewer")
sapply(lib, function(...) require(..., character.only = TRUE))

source("../../ndvi/src/cellHarmonics.R")
source("../../ndvi/src/ndviPhaseShift.R")

# # Research plots
# plots <- readOGR(dsn = "data/coords/", 
#                  layer = "PlotPoles_ARC1960_mod_20140807_final")


## Data import

# DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

# st <- "198201"
# nd <- "201112"

# 1-km GIMMS NDVI data (1982-2011)
fls_ndvi <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_ndvi <- stack(fls_ndvi)

# ndvi.dates <- substr(basename(ndvi.fls), 5, 11)
# ndvi.years <- unique(substr(basename(ndvi.fls), 5, 8))
# 
# # Setup time series
# ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
# #   seq(as.Date(paste(i, "01", ifelse(h == "MOD13Q1", "01", "09"), sep = "-")), 
# #       as.Date(paste(i, "12", "31", sep = "-")), 16)
#   seq(as.Date(paste(i, "01", "09", sep = "-")), 
#       as.Date(paste(i, "12", "31", sep = "-")), 16)
# }))
# 
# # Merge time series with available NDVI files
# ndvi.ts.fls <- merge(data.frame(date = ndvi.ts), 
#                      data.frame(date = as.Date(ndvi.dates, format = "%Y%j"), 
#                                 file = ndvi.fls, stringsAsFactors = F), 
#                      by = "date", all.x = T)
# 
# # Import raster files and convert to matrices
# ndvi.rst <- foreach(i = seq(nrow(ndvi.ts.fls)), .packages = lib) %dopar% {
#   if (is.na(ndvi.ts.fls[i, 2])) {
#     NA
#   } else {
#     raster(ndvi.ts.fls[i, 2])
#   }
# }

#   ###
#   ## KZA evaluation
#   # List available files, dates and years
#   ndvi.fls <- list.files("data/quality_control", pattern = h, full.names = T)
#   
#   ndvi.dates <- substr(basename(ndvi.fls), 13, 19)
#   ndvi.years <- unique(substr(basename(ndvi.fls), 13, 16))
#   
#   # Setup time series
#   ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
#     seq(as.Date(paste(i, "01", ifelse(h == "MOD13Q1", "01", "09"), sep = "-")), 
#         as.Date(paste(i, "12", "31", sep = "-")), 16)
#   }))
#   
#   # Merge time series with available NDVI files
#   ndvi.ts.fls <- merge(data.frame(date = ndvi.ts), 
#                        data.frame(date = as.Date(ndvi.dates, format = "%Y%j"), 
#                                   file = ndvi.fls, stringsAsFactors = F), 
#                        by = "date", all.x = T)
#   
#   # Import raster files and convert to matrices
#   ndvi.rst.qa <- foreach(i = seq(nrow(ndvi.ts.fls)), .packages = lib) %dopar% {
#     if (is.na(ndvi.ts.fls[i, 2])) {
#       NA
#     } else {
#       raster(ndvi.ts.fls[i, 2])
#     }
#   }
#   
#   tmp.qa <- as.numeric(unlist(sapply(ndvi.rst.qa, function(i) {
#     if (is.logical(i)) NA else i[cellFromXY(ndvi.rst[[20]], plots[67, ])]
#   })))
#   tmp.gf <- as.numeric(unlist(sapply(ndvi.rst, function(i) {
#     if (is.logical(i)) NA else i[cellFromXY(ndvi.rst[[20]], plots[67, ])]
#   })))
#   
#   ###

# ndvi.mat <- foreach(i = fls_ndvi, .packages = lib) %dopar% as.matrix(i)
# 
# # Aggregate rasters on a monthly basis
# ndvi.months <- substr(ndvi.ts.fls[, 1], 1, 7)
# 
# ndvi.rst.agg <- foreach(i = unique(ndvi.months), .packages = lib) %dopar% {
#   
#   # Rasters of current month
#   index <- which(ndvi.months %in% i)
#   # Dates with no available NDVI files
#   navl <- sapply(ndvi.rst[index], is.logical)
#   
#   # Overlay non-missing data
#   if (all(navl)) {
#     return(NA)
#   } else {
#     if (sum(!navl) == 2) {
#       Reduce(function(x, y) overlay(x, y, fun = function(...) {
#         mean(..., na.rm = T)
#       }), ndvi.rst[index[!navl]])
#     } else {
#       ndvi.rst[[index[!navl]]]
#     }
#   }
# }

#   # Mean NDVI per month
#   ndvi.rst.monthly_mean <- foreach(i = 1:12, .packages = lib, .combine = "stack") %dopar% {
#     tmp <- ndvi.rst.agg[seq(i, length(ndvi.rst.agg), 12)]
#     overlay(stack(tmp[!sapply(tmp, is.logical)]), 
#             fun = function(...) round(mean(..., na.rm = T) / 10000, digits = 2))
#   }
#   names(ndvi.rst.monthly_mean) <- month.abb
#   
#   ndvi.mat.monthly_mean <- as.matrix(ndvi.rst.monthly_mean)
#   
#   index <- cellFromXY(ndvi.rst.monthly_mean, plots)
#   write.csv(data.frame(PlotID = plots$PlotID, ndvi.mat.monthly_mean[index, ]), 
#             "out/plots_mean_ndvi_filled.csv", quote = F, row.names = F)

# # Value extraction
# ndvi.start <- substr(unique(substr(ndvi.ts.fls[, 1], 1, 7)), 1, 4) %in% 
#   ndvi.years[2:4]
# ndvi.end <- substr(unique(substr(ndvi.ts.fls[, 1], 1, 7)), 1, 4) %in% 
#   ndvi.years[9:11]

# Temporal subsetting
st_year <- 1982
nd_year <- 2011
n_years <- 15
n_months <- n_years * 12

rst.st <- rst_ndvi[[1:n_months]]
rst.nd <- rst_ndvi[[(nlayers(rst_ndvi)-n_months+1):nlayers(rst_ndvi)]]

rst.har <-  cellHarmonics(st = rst.st, 
                          nd = rst.nd, 
                          st.start = c(st_year, 1), st.end = c(st_year+n_years-1, 12), 
                          nd.start = c(nd_year-n_years+1, 1), nd.end = c(nd_year, 12), 
                          product = "GIMMS", 
                          path.out = "data/rst/harmonic_8296_9711", n.cores = 3)

# Start variance (maximum - minimum)
st_diff_max_min <- rst.har[[1]][[2]]-rst.har[[1]][[4]]

# End variance (maximum - minimum)
nd_diff_max_min <- rst.har[[2]][[2]]-rst.har[[2]][[4]]

# Shift in maximum NDVI
diff_max_y <- overlay(rst.har[[1]][[2]], rst.har[[2]][[2]], fun = function(x, y) {
  return(y - x)
})

# Shift in minimum NDVI
diff_min_y <- overlay(rst.har[[1]][[4]], rst.har[[2]][[4]], fun = function(x, y) {
  return(y - x)
})

# Shift in months regarding NDVI maximum
diff_max_x <- overlay(rst.har[[1]][[1]], rst.har[[2]][[1]], 
                      st_diff_max_min, nd_diff_max_min,
                      fun = function(x, y, z_max, z_min) 
                        ndviPhaseShift(x, y, z_max, z_min, 
                                       rejectLowVariance = TRUE, 
                                       varThreshold = .04))

cols_div <- colorRampPalette(brewer.pal(5, "BrBG"))
p_diff_max_x <- 
  spplot(diff_max_x, col.regions = cols_div(100), scales = list(draw = TRUE), 
         xlab = "x", ylab = "y", at = seq(-2.5, 2.5, 1),
         sp.layout = list("sp.lines", rasterToContour(dem), col = "grey65"))
# png("out/harmonic/harmonic_modis_diff_max_x_0306_1013.png", width = 20, 
#     height = 17.5, units = "cm", pointsize = 15, res = 300)
# print(p_diff_max_x)
# dev.off()

# Shift in months regarding NDVI minimum
diff_min_x <- overlay(rst.har[[1]][[3]], rst.har[[2]][[3]], 
                      st_diff_max_min, nd_diff_max_min, 
                      fun = function(x, y, z_max, z_min) 
                        ndviPhaseShift(x, y, z_max, z_min, 
                                       rejectLowVariance = TRUE, 
                                       varThreshold = .04))

p_diff_min_x <- 
  spplot(diff_min_x, col.regions = cols_div(100), scales = list(draw = TRUE), 
         xlab = "x", ylab = "y", at = seq(-2.5, 2.5, 1),
         sp.layout = list("sp.lines", rasterToContour(dem), col = "grey65"))


foreach(i = list(diff_max_x, diff_min_x, diff_max_y, diff_min_y), 
        j = list("diff_max_x", "diff_min_x", "diff_max_y", "diff_min_y")) %do% 
  writeRaster(i, paste0("data/rst/harmonic_8296_9711/", j), format = "GTiff", overwrite = TRUE)

### Visualization

# hcl colorspace
df_hcl <- data.frame(cell = 1:ncell(diff_max_x), 
                     h = 90 + diff_max_x[] * 10, 
                     c = 50, # increasing chroma with higher values
                     l = 50 + diff_max_y[] * 100) # decreasing luminance with higher values

for (i in c(3, 4)) {
  if (any(df_hcl[, i] < 0))
    df_hcl[which(df_hcl[, i] < 0), i] <- 0
}

df_hcl_cc <- df_hcl[complete.cases(df_hcl), ]

template <- rasterToPolygons(diff_max_x)
plot(template, col = hcl(h = df_hcl_cc[, 2], c = df_hcl_cc[, 3], l = df_hcl_cc[, 4]), 
     border = "transparent")

