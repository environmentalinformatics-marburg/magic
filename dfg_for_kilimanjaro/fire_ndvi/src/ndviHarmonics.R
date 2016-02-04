# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/envin/XChange/kilimanjaro/ndvi"}, 
       "Windows" = {path.wd <- "D:/kilimanjaro/ndvi"})
setwd(path.wd)

# Packages and functions
lib <- c("doParallel", "raster", "rgdal", "TSA")
sapply(lib, function(...) require(..., character.only = TRUE))

fun <- "cellHarmonics.R"
sapply(fun, function(x) source(paste("src", x, sep = "/")))

# Parallelization
registerDoParallel(cl <- makeCluster(2))

# Research plots
plots <- readOGR(dsn = "data/coords/", layer = "PlotPoles_ARC1960_mod_20140807_final")


## Data import

st <- "200301"
nd <- "201312"

# List available files, dates and years
fls_ndvi <- list.files("data/processed/whittaker_myd13q1", 
                       pattern = "^SCL_AGGMAX", full.names = TRUE)
fls_ndvi <- fls_ndvi[grep(st, fls_ndvi):grep(nd, fls_ndvi)]

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

ndvi.mat <- foreach(i = fls_ndvi, .packages = lib) %dopar% as.matrix(i)

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

# Remove possible no-data margins
rst.st <- rst_ndvi[[1:48]]
rst.nd <- rst_ndvi[[(nlayers(rst_ndvi)-48+1):nlayers(rst_ndvi)]]

# template <- rasterToPolygons(rst.st[[1]])
# rst.st <- crop(stack(ndvi.rst.agg[ndvi.start]), template)
# rst.nd <- crop(stack(ndvi.rst.agg[ndvi.end]), template)

rst.har <-  cellHarmonics(st = rst.st, 
                          nd = rst.nd, 
                          st.start = c(2003, 1), st.end = c(2006, 12), 
                          nd.start = c(2010, 1), nd.end = c(2013, 12), 
                          product = "MYD13Q1", 
                          path.out = "data/processed/harmonic", n.cores = 3)

diff_max_x <- overlay(rst.har[[1]][[1]], rst.har[[2]][[1]], fun = function(x, y) {
  val_diff <- x - y
  
  val_xp12 <- x + 12 # add 12 months to 'st' when y >> x 
  val_diff_xp12 <- y - val_xp12
  val_yp12 <- y + 12 # add 12 months to 'nd' when x >> y
  val_diff_yp12 <- val_yp12 - x
  
  id_p6 <- which(val_diff > 6)
  id_m6 <- which(val_diff < (-6))
  id <- which(abs(val_diff) <= 6)
  
  val_diff[id_p6] <- val_diff_yp12[val_diff > 6]
  val_diff[id_m6] <- val_diff_xp12[val_diff < (-6)]
  val_diff[id] <- (y - x)[id]
  
  return(val_diff)
})

# cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
# p_diff_max_x <- 
#   spplot(diff_max_x, col.regions = cols_div(100), scales = list(draw = TRUE), 
#          xlab = "x", ylab = "y", at = seq(-6.5, 6.5, 1),
#          sp.layout = list("sp.lines", rasterToContour(dem), col = "grey65"))
# png("out/harmonic/harmonic_modis_diff_max_x_0306_1013.png", width = 20, 
#     height = 17.5, units = "cm", pointsize = 15, res = 300)
# print(p_diff_max_x)
# dev.off()


diff_min_x <- overlay(rst.har[[1]][[3]], rst.har[[2]][[3]], fun = function(x, y) {
  val_diff <- x - y
  
  val_xp12 <- x + 12 # add 12 months to 'st' when y >> x 
  val_diff_xp12 <- y - val_xp12
  val_yp12 <- y + 12 # add 12 months to 'nd' when x >> y
  val_diff_yp12 <- val_yp12 - x
  
  id_p6 <- which(val_diff > 6)
  id_m6 <- which(val_diff < (-6))
  id <- which(abs(val_diff) <= 6)
  
  val_diff[id_p6] <- val_diff_yp12[val_diff > 6]
  val_diff[id_m6] <- val_diff_xp12[val_diff < (-6)]
  val_diff[id] <- (y - x)[id]
  
  return(val_diff)
})


diff_max_y <- overlay(rst.har[[1]][[2]], rst.har[[2]][[2]], fun = function(x, y) {
  return(y - x)
})

diff_min_y <- overlay(rst.har[[1]][[4]], rst.har[[2]][[4]], fun = function(x, y) {
  return(y - x)
})

# Deregister parallel backend
stopCluster(cl)
