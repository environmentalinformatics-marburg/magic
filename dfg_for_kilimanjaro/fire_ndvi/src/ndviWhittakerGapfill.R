### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {dsn <- "/media/envin/XChange/kilimanjaro/ndvi/"}, 
       "Windows" = {dsn <- "D:/kilimanjaro/ndvi/"})
setwd(dsn)

# Required packages and functions
# install.packages("MODIS", repos="http://R-Forge.R-project.org")
lib <- c("raster", "rgdal", "MODIS", "doParallel", "Kendall", "RColorBrewer", 
         "reshape2", "ggplot2", "zoo", "GSODTools")
sapply(lib, function(...) require(..., character.only = TRUE))

source("src/aggregateNDVICells.R")

# Parallelization
registerDoParallel(cl <- makeCluster(4))


### Data import

## Extract .hdf container files for further processing
MODISoptions(localArcPath = paste0(dsn, "data/MODIS_ARC/"), 
             outDirPath = paste0(dsn, "data/MODIS_ARC/PROCESSED/"), 
             MODISserverOrder = c("LAADS","LPDAAC"))

for (i in c("MOD13Q1", "MYD13Q1"))
  runGdal(i, 
          tileH = 21, tileV = 9, SDSstring = "000000000010", 
          outProj = "EPSG:21037", job = "ndvi_clrk")


## Geographic extent

fls_gimms <- list.files("../gimms3g/gimms3g/data/rst/", pattern = "_crp_utm.tif$", 
                        full.names = TRUE)
rst_gimms <- raster(fls_gimms[[1]])
kili <- rasterToPolygons(rst_gimms)

# kili <- data.frame(x = c(37, 37.72), y = c(-3.4, -2.84), id = c("ll", "ur"))
# coordinates(kili) <- c("x", "y")
# projection(kili) <- CRS("+init=epsg:4326")
# kili <- spTransform(kili, CRS("+init=epsg:21037"))


## Plot coordinates

plt <- readOGR(dsn = "data/coords/", 
               layer = "PlotPoles_ARC1960_mod_20140807_final")
plt_apoles <- subset(plt, PoleName == "A middle pole")


## DEM

dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")


## NDVI data

stats <- foreach(h = c("MOD13Q1", "MYD13Q1"), .packages = lib) %dopar% {
  
  pttrn <- paste(h, c("NDVI.tif$", "pixel_reliability.tif$", 
                      "composite_day_of_the_year.tif$"), sep = ".*")
  
  ndvi.rst <- lapply(pttrn, function(i) {                                      
    # List available files
    fls <- list.files("data/MODIS_ARC/PROCESSED/ndvi_clrk", 
                           pattern = i, full.names = TRUE)  
    # Stack and crop files
    rst <- stack(fls)
    rst.crp <- crop(rst, extent(kili))
    rst.crp <- writeRaster(rst.crp, filename = "data/processed/CRP", format = "GTiff", 
                           bylayer = TRUE, suffix = names(rst), overwrite = TRUE)
    return(rst.crp)
  })
  
  ndvi.rst <- ndvi.rst[1:2]
  
#   ndvi.rst <- lapply(pttrn, function(i) {
#     fls <- list.files("data/processed/", full.names = TRUE, 
#                       pattern = paste("^CRP_", i, sep = ".*"))
#     stack(fls)
#   })
  
  # Rejection of low quality cells
  ndvi.rst.qa <- overlay(ndvi.rst[[1]], ndvi.rst[[2]], fun = function(x, y) {
    x[!y[] %in% c(0:2)] <- NA
    return(x)
  })
ndvi.rst.qa <- writeRaster(ndvi.rst.qa, filename = "data/processed/QA", format = "GTiff", 
                           bylayer = TRUE, suffix = names(ndvi.rst[[1]]), overwrite = TRUE)

#   ndvi.fls.qa <- list.files("data/processed/", full.names = TRUE, 
#                             pattern = paste("^QA_", pttrn[1], sep = ".*"))
#   ndvi.rst.qa <- stack(ndvi.fls.qa)

  # Application of outlier check
  ndvi.rst.qa.sd <- calc(ndvi.rst.qa, fun = function(x) {
    id <- tsOutliers(x, lower_quantile = .4, upper_quantile = .9, index = TRUE)
    x[id] <- NA
    return(x)
  })
  ndvi.rst.qa.sd <- 
    writeRaster(ndvi.rst.qa.sd, filename = "data/processed/SD", format = "GTiff", 
                bylayer = TRUE, suffix = names(ndvi.rst.qa), overwrite = TRUE)

#   ndvi.fls.qa.sd <- list.files("data/processed/", full.names = TRUE, 
#                                pattern = paste("^SD_", pttrn[1], sep = ".*"))
#   ndvi.rst.qa.sd <- stack(ndvi.fls.qa.sd)

  # Rejection of pixels surrounding cloudy cells
  ndvi.rst.qa.sd.fc <- do.call("stack", lapply(unstack(ndvi.rst.qa.sd), function(i) {
    cells <- which(is.na(i[]))
    id <- adjacent(i, cells = cells, directions = 8, pairs = FALSE)
    i[id] <- NA
    return(i)
  }))
  ndvi.rst.qa.sd.fc <- 
    writeRaster(ndvi.rst.qa.sd.fc, filename = "data/processed/BF", format = "GTiff", 
                bylayer = TRUE, suffix = names(ndvi.rst.qa.sd), overwrite = TRUE)
  
  ndvi.fls.qa.sd.fc <- list.files("data/processed/", full.names = TRUE, 
                                  pattern = paste("^BF_SD_QA_CRP", pttrn[1], sep = ".*"))
  ndvi.rst.qa.sd.fc <- stack(ndvi.fls.qa.sd.fc)
# 
# dates <- orgTime(ndvi.fls.init)$inputLayerDates
# dates_agg <- dates + 8
# yearmon_agg <- as.yearmon(dates_agg)
# indices_agg <- as.numeric(as.factor(yearmon_agg))
# 
# outdir <- paste0("data/processed")
# rst_qa_sd_fc_aggmax <- 
#   stackApply(ndvi.rst.qa.sd.fc, indices = indices_agg, fun = max, bylayer = TRUE,
#              filename = paste0(outdir, "/AGGMAX_BF_SD_QA_", h), format = "GTiff",  
#              suffix = strftime(unique(yearmon_agg), format = "%Y%m"), 
#              overwrite = TRUE)

  
  
  ### Gap filling
  
  ndvi.fls.init <- list.files("data/MODIS_ARC/PROCESSED/ndvi_clrk", 
                              pattern = paste(h, "NDVI.tif$", sep = ".*"), 
                              full.names = TRUE, recursive = TRUE)

# org_agg <- sapply(strsplit(names(rst_qa_sd_fc_aggmax), "_"), "[[", 6)
# org_agg <- paste0(org_agg, "01")
# org_agg <- orgTime(org_agg, nDays = "1 month", pillow = 0, 
#                    pos1 = 1, pos2 = 8, format = "%Y%m%d")

rst.wht <- whittaker.raster(vi = ndvi.rst.qa.sd.fc, removeOutlier = TRUE, threshold = 2000,
                            timeInfo = orgTime(ndvi.fls.init, pillow = 0), 
                            lambda = 6000, nIter = 3, groupYears = FALSE, 
                            outDirPath = paste0("data/processed/whittaker_", tolower(h)), 
                            overwrite = TRUE, format = "raster")
 
# Save files separately (takes some time, parallel processing suggested)
dates <- orgTime(ndvi.fls.init)$inputLayerDates
dates_jul <- strftime(dates, format = "%Y%j")

outdir <- paste0("data/processed/whittaker_", tolower(h))
rst.wht <- foreach(i = unstack(rst.wht[[1]]), j = dates_jul, .combine = "stack", 
                   .packages = lib) %dopar% {
  outfile <- paste0("WHT_", j)
  file_out <- paste(outdir, outfile, sep = "/")
  writeRaster(i, filename = file_out, format = "GTiff", overwrite = TRUE)
}

#   # Monthly aggregation
#   fls.wht <- list.files(paste0("data/processed/whittaker_", tolower(h)), 
#                         pattern = "^WHT.*.tif$", full.names = TRUE)
#   rst.wht <- stack(fls.wht)

dates_agg <- dates + 8
yearmon_agg <- as.yearmon(dates_agg)
indices_agg <- as.numeric(as.factor(yearmon_agg))

outdir <- paste0("data/processed/whittaker_", tolower(h))
# rst_wht_aggmax <- 
#   stackApply(rst.wht, indices = indices_agg, fun = max, bylayer = TRUE,
#              filename = paste0(outdir, "/AGGMAX_WHT"), format = "GTiff",  
#              suffix = strftime(unique(yearmon_agg), format = "%Y%m"), 
#              overwrite = TRUE)
# 
# rst_wht_aggmin <- 
#   stackApply(rst.wht, indices = indices_agg, fun = min, bylayer = TRUE,
#              filename = paste0(outdir, "/AGGMIN_WHT"), format = "GTiff",  
#              suffix = strftime(unique(yearmon_agg), format = "%Y%m"), 
#              overwrite = TRUE)

  fls_wht <- list.files(paste0("data/processed/whittaker_", tolower(h)), 
                        pattern = "^WHT", full.names = TRUE)
  rst_wht <- stack(fls_wht)
  
  fls_doy <- list.files("data/processed", full.names = TRUE,
                        pattern = paste0("^CRP_", toupper(h), ".*composite"))
  rst_doy <- stack(fls_doy)
  
  dates_doy <- as.numeric(substr(basename(fls_doy), 14, 20))
  months_doy <- unique(strftime(as.Date(as.character(dates_doy), format = "%Y%j"), "%Y%m"))
  
  file_out <- paste0(unique(dirname(fls_wht)), "/AGGMAX_WHT")
  rst_wht_aggmax <- aggregateNDVICells(rst = rst_wht, 
                                       rst_doy = rst_doy, 
                                       dates = dates_doy, 
                                       n_cores = 4, 
                                       save_output = TRUE, filename = file_out, 
                                       bylayer = TRUE, suffix = months_doy, 
                                       format = "GTiff", overwrite = TRUE)
  

# Application of scale factor and removal of inconsistent values
fls_wht_aggmax <- list.files(outdir, pattern = "^AGGMAX_WHT", full.names = TRUE)
rst_wht_aggmax <- stack(fls_wht_aggmax)
fls_scl <- paste0(outdir, "/SCL_", names(rst_wht_aggmax))

rst_scl <- foreach(i = unstack(rst_wht_aggmax), j = as.list(fls_scl), 
                   .packages = lib, .combine = "stack") %dopar% {                             
  rst <- i
  rst <- rst / 10000
  
  id <- which(rst[] < -1 | rst[] > 1)
  
  if (length(id) > 0) {
    rst[id] <- NA
  }
  
  rst <- writeRaster(rst, filename = j, format = "GTiff", overwrite = TRUE)
  
  return(rst)
}

# # 2011-2013
# fls_scl <- list.files(outdir, pattern = "^SCL", full.names = TRUE)
# 
# # st <- grep("201101", fls_scl)
# # nd <- grep("201312", fls_scl)
# # fls_scl <- fls_scl[st:nd]
# 
# rst_scl <- stack(fls_scl)
# 
# mat_plt_val <- extract(rst_scl, plt_apoles)
# df_plt_val <- data.frame(PlotID = plt_apoles@data[, 1], mat_plt_val)
# names(df_plt_val)[2:ncol(df_plt_val)] <- 
#   sapply(strsplit(names(df_plt_val)[2:ncol(df_plt_val)], "_"), "[[", 4)
# write.csv(df_plt_val, "out/csv/ndvi_aggmin_200207_201409.csv", row.names = FALSE)
# 
# months <- substr(sapply(strsplit(fls_scl, "_"), "[[", 5), 5, 6)
# indices <- as.numeric(as.factor(months))
# 
# rst_scl_mmonth <- stackApply(rst_scl, indices = indices, fun = mean)
# 
# plt_scl_mmonth <- data.frame(PlotId = plt_apoles$PlotID, 
#                              extract(rst_scl_mmonth, plt_apoles))
# 
# id <- grep("mai2", plt_scl_mmonth$PlotId)
# plot(unlist(plt_scl_mmonth[id, 2:ncol(plt_scl_mmonth)]), type = "l", 
#      xlab = "Month", ylab = "NDVI")
# 
#   st <- ifelse(h == "MOD13Q1", "2001", "2003")
#   st <- "2003"
#   nd <- "2013"
# 
#   fls.wht <- fls.wht[grep(st, fls.wht):grep(nd, fls.wht)]
#   rst.wht <- stack(fls.wht)
#   
#   rst.mk <- overlay(rst.wht, fun = function(x) MannKendall(as.numeric(x))$tau, 
#                     filename = paste("out/MK", toupper(h), unique(substr(names(rst.wht), 1, 21)), st, nd, sep = "_"), 
#                     format = "GTiff", overwrite = TRUE)
#   rst.mk.p <- overlay(rst.wht, fun = function(x) MannKendall(as.numeric(x))$sl, 
#                       filename = paste("out/MK_p", toupper(h), unique(substr(names(rst.wht), 1, 21)), st, nd, sep = "_"), 
#                       format = "GTiff", overwrite = TRUE)
# 
#   fls.mk <- list.files("out", pattern = paste0("MK_", toupper(h), ".*.tif$"), 
#                        full.names = TRUE)
#   rst.mk <- raster(fls.mk)
#   
#   png(paste0(substr(fls.mk, 1, nchar(fls.mk)-4), ".png"), units = "mm", 
#       width = 300, res = 300, pointsize = 20)
#   print(spplot(rst.mk, scales = list(draw = TRUE), xlab = "x", ylab = "y", 
#          col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
#          sp.layout = list("sp.lines", rasterToContour(dem)), 
#          par.settings = list(fontsize = list(text = 15)), at = seq(-.9, .9, .1)))
#   dev.off()
#   
#   stats <- lapply(c(.01, .001), function(i) {
#     rst.mk <- overlay(rst.wht, fun = function(x) {
#       mk <- MannKendall(as.numeric(x))
#       if (mk$sl >= i) return(NA) else return(mk$tau)
#     }, filename = paste("out/MK", i, toupper(h), 
#                         unique(substr(names(rst.wht), 1, 21)), sep = "_"), 
#     format = "GTiff", overwrite = TRUE)
#     
#     fls.mk <- list.files("out", pattern = paste(i, toupper(h), ".tif$", sep = ".*"), 
#                          full.names = TRUE)
#     rst.mk <- raster(fls.mk)
#     
#     png(paste0(substr(fls.mk, 1, nchar(fls.mk)-4), ".png"), units = "mm", 
#         width = 300, res = 300, pointsize = 20)
#     print(spplot(rst.mk, scales = list(draw = TRUE), xlab = "x", ylab = "y", 
#                  col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
#                  sp.layout = list("sp.lines", rasterToContour(dem)), 
#                  par.settings = list(fontsize = list(text = 15)), 
#                  at = seq(-.9, .9, .1)))
#     dev.off()
#     
#     val <- round(sum(!is.na(rst.mk[]))/ncell(rst.mk), digits = 3)
#     
#     val.pos <- round(sum(rst.mk[] > 0, na.rm = TRUE) / sum(!is.na(rst.mk[])), 3)
#     val.neg <- round(sum(rst.mk[] < 0, na.rm = TRUE) / sum(!is.na(rst.mk[])), 3)
#     
#     return(data.frame(sensor = h, p = as.character(i), nona = val, 
#                       nona_pos = val.pos, nona_neg = val.neg))
#   })
#   
#   return(do.call("rbind", stats))
}

# Store percentage information about significant NDVI pixels
write.csv(do.call("rbind", stats), "out/mk_na_stats.csv", row.names = FALSE)

# Remove white margins from output images
system("cd out/; for file in *.png; do convert -trim $file $file; done")

# Deregister parallel backend
stopCluster(cl)


## Visualization of Whittaker gap-filling performance

# Import quality-controlled raster data of both Terra and Aqua
rst.orig <- lapply(c("MOD13Q1", "MYD13Q1"), function(h) {
  
  fls <- list.files("data/processed/", full.names = TRUE, 
                    pattern = paste("^CRP_", h, "NDVI.tif$", sep = ".*"))
  
  #   st <- ifelse(h == "MOD13Q1", "2001", "2003")
  st <- "2003"
  nd <- "2013"
  
  fls <- fls[grep(st, fls)[1]:grep(nd, fls)[length(grep(nd, fls))]]
  rst <- stack(fls)
  
  return(rst)
})

# Import quality-controlled raster data of both Terra and Aqua
rst.qa <- lapply(c("MOD13Q1", "MYD13Q1"), function(h) {
  
  fls <- list.files("data/processed/", full.names = TRUE, 
                    pattern = paste("^BF_", h, sep = ".*"))

#   st <- ifelse(h == "MOD13Q1", "2001", "2003")
  st <- "2003"
  nd <- "2013"
  
  fls <- fls[grep(st, fls)[1]:grep(nd, fls)[length(grep(nd, fls))]]
  rst <- stack(fls)
  
  return(rst)
})

# Import Whittaker-filled raster data and corresponding dates
rst.wht <- lapply(c("MOD13Q1", "MYD13Q1"), function(h) {
  fls <- list.files(paste0("data/processed/whittaker_", tolower(h)), 
                    pattern = "NDVI_Year.*_year.*.tif$", full.names = TRUE)
  
#   st <- ifelse(h == "MOD13Q1", "2001", "2003")
  st <- "2003"
  nd <- "2013"
  
  fls <- fls[grep(st, fls)[1]:grep(nd, fls)[length(grep(nd, fls))]]
  rst <- stack(fls)

  return(rst)
})

dat.wht <- lapply(c("MOD13Q1", "MYD13Q1"), function(h) {
  fls.crp <- list.files("data/processed/",
                        pattern = paste("^CRP", h, "NDVI.tif$", sep = ".*"))
  
#   st <- ifelse(h == "MOD13Q1", "2001", "2003")
  st <- "2003"
  nd <- "2013"
  
  fls.crp <- fls.crp[grep(st, fls.crp)[1]:
                       grep(nd, fls.crp)[length(grep(nd, fls.crp))]]
  
  return(substr(fls.crp, 14, 20))
})

# Extract cell numbers for each KiLi plot, and extract corresponding time
# series from Terra and Aqua RasterStack objects
cell.numbers <- data.frame(PlotID = plt.wgs.apoles@data$PlotID, 
                           Cell = cellFromXY(rst.wht[[1]], plt.wgs.apoles))

# Original, quality-checked and gap-filled data as matrices
mat.orig.terra <- as.matrix(rst.orig[[1]])
mat.qa.terra <- as.matrix(rst.qa[[1]])
mat.wht.terra <- as.matrix(rst.wht[[1]])

mat.orig.aqua <- as.matrix(rst.orig[[2]])
mat.qa.aqua <- as.matrix(rst.qa[[2]])
mat.wht.aqua <- as.matrix(rst.wht[[2]])

index <- grep("cof2", cell.numbers[, 1])

ts.orig.terra <- mat.orig.terra[cell.numbers[index, 2], ] / 10000
ts.gappy.terra <- mat.qa.terra[cell.numbers[index, 2], ] / 10000
ts.filled.terra <- mat.wht.terra[cell.numbers[index, 2], ] / 10000

ts.orig.aqua <- mat.orig.aqua[cell.numbers[index, 2], ] / 10000
ts.gappy.aqua <- mat.qa.aqua[cell.numbers[index, 2], ] / 10000
ts.filled.aqua <- mat.wht.aqua[cell.numbers[index, 2], ] / 10000

# Terra data
dat.terra <- data.frame(date = as.Date(dat.wht[[1]], format = "%Y%j"),
                        "Original" = ts.orig.terra,
                        "Filtered" = ts.gappy.terra, 
                        "Imputed" = ts.filled.terra)

dat.terra <- melt(dat.terra, id.vars = 1)
dat.terra$sensor <- "Terra"

# Aqua data
dat.aqua <- data.frame(date = as.Date(dat.wht[[2]], format = "%Y%j"),
                       "Original" = ts.orig.aqua,
                       "Filtered" = ts.gappy.aqua, 
                       "Imputed" = ts.filled.aqua)

dat.aqua <- melt(dat.aqua, id.vars = 1)
dat.aqua$sensor <- "Aqua"

# Plot Terra and Aqua data separately, 
# quality-controlled data = grey, gap-filled data = black
# ggplot(aes(x = date, y = value, group = variable, colour = variable), 
#        data = dat.terra) + 
#   geom_line(size = .6) + 
#   facet_wrap(~ sensor) +
#   scale_color_manual("", values = c("Original" = "grey75", "Imputed" = "black")) +
#   labs(x = "Time [16-day intervals]", y = "NDVI") +
#   theme_bw()

png("out/whittaker_gapfill_performance_cof2.png", width = 25, height = 15, 
    units = "cm", res = 300, pointsize = 16)
ggplot(aes(x = date, y = value, group = variable, colour = variable), 
       data = dat.aqua) + 
  geom_line(size = 1) + 
  scale_color_manual("", values = c("Original" = "grey75", 
                                    "Filtered" = "darkolivegreen2", 
                                    "Imputed" = "darkred")) +
  labs(x = "Time [16-day intervals]", y = "NDVI") +
  theme_bw()
dev.off()

# Plot Terra and Aqua data in combination
dat <- rbind(dat.terra, dat.aqua)
dat$sensor <- factor(dat$sensor, levels = c("Terra", "Aqua"))

# ggplot(aes(x = date, y = value, group = variable, colour = variable), 
#        data = dat) + 
#   geom_line(size = .6) + 
# #   stat_smooth(method = "lm", se = FALSE, size = 2) + 
#   facet_wrap(~ sensor, ncol = 1) + 
#   scale_color_manual("", values = c("Original" = "grey75", "Imputed" = "black")) +
#   labs(x = "Time [16-day intervals]", y = "NDVI") +
#   theme_bw()

# Compare Terra and Aqua (e.g., COF3)
cof3.terra <- data.frame(date = as.Date(dat.wht[[1]], format = "%Y%j"), 
                         ndvi = mat.wht.terra[cell.numbers[index, 2], ] / 10000, 
                         sensor = "Terra")
cof3.aqua <- data.frame(date = as.Date(dat.wht[[2]], format = "%Y%j"), 
                        ndvi = mat.wht.aqua[cell.numbers[index, 2], ] / 10000, 
                        sensor = "Aqua")
cof3 <- rbind(cof3.terra, cof3.aqua)
cof3$plot <- cell.numbers[index, 1]

ggplot(aes(x = date, y = ndvi, group = sensor, colour = sensor), data = cof3) + 
  geom_line(size = .6) + 
  stat_smooth(method = "lm", se = FALSE, size = 2) + 
  facet_wrap(~ plot) + 
  scale_color_manual("", values = c("Terra" = "brown", "Aqua" = "blue")) +
  labs(x = "Time [16-day intervals]", y = "NDVI") +
  theme_bw()

