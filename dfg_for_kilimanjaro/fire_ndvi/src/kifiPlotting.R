### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/pa_NDown/ki_modis_ndvi/"}, 
       "Windows" = {path.wd <- "G:/ki_modis_ndvi"})
setwd(path.wd)

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal", "Kendall", "matrixStats", "ggplot2", 
         "kza", "RColorBrewer", "zoo", "scales", "latticeExtra", "grid")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

# Parallelization
registerDoParallel(cl <- makeCluster(3))


### Data import

## MODIS NDVI 

# List files and order by date
# ndvi.fls <- list.files("data/gap_filled/", pattern = "MYD13Q1", 
ndvi.fls <- list.files("data/processed/whittaker_mod13q1", 
                       pattern = "^WHT.*.tif$", full.names = TRUE)

ndvi.dates <- substr(basename(ndvi.fls), 5, 11)
ndvi.years <- unique(substr(basename(ndvi.fls), 5, 11))

## Notwendig?
## ndvi.fls <- ndvi.fls[order(ndvi.dates)]

# Setup time series
ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 16)
}))

# Merge time series with available NDVI files
ndvi.ts.fls <- merge(data.frame(date = ndvi.ts), 
                     data.frame(date = as.Date(ndvi.dates, format = "%Y%j"), 
                                file = ndvi.fls, stringsAsFactors = F), 
                     by = "date", all.x = T)

# Import raster files
ndvi.rst <- foreach(i = seq(nrow(ndvi.ts.fls)), .packages = lib) %dopar% {
  if (is.na(ndvi.ts.fls[i, 2])) {
    NA
  } else {
    round(raster(ndvi.ts.fls[i, 2]) / 10000, 2)
  }
}

# Remove whitespace
ndvi.shp <- rasterToPolygons(ndvi.rst[[20]])

ndvi.rst <- foreach(i = ndvi.rst, .packages = lib) %dopar% {
  if (class(i) == "logical") NA else crop(i, extent(ndvi.shp))
}

# Rasters to matrices
ndvi.mat <- foreach(i = ndvi.rst, .packages = lib) %dopar% as.matrix(i)


### Plotting stuff

## Research plot coordinates

plot.lonlat <- read.csv("kili_plots_64.csv", 
                        stringsAsFactors = F)[, c(1, 2, 6, 13, 14)]
plot.lonlat <- plot.lonlat[complete.cases(plot.lonlat), ]
plot.lonlat <- subset(plot.lonlat, Valid == "Y")
plot.lonlat <- plot.lonlat[!substr(plot.lonlat$PlotID, 1, 3) %in% c("jul", "sun"), ]
coordinates(plot.lonlat) <- ~ POINT_X + POINT_Y
projection(plot.lonlat) <- "+init=epsg:4326"
plot.utm37s <- spTransform(plot.lonlat, CRS("+init=epsg:32737"))


## Mann-Kendall trend

# DEM 
dem <- raster("data/KiLi_DEM/kili_dem_utm.tif")

# Identify first and last valid raster
first.valid.index <- which(!sapply(ndvi.rst, is.logical))[1]
first.valid <- ndvi.rst[[first.valid.index]]

last.valid.index <- rev(which(!sapply(ndvi.rst, is.logical)))[1]

# # Mann-Kendall tau
# ndvi.stck <- stack(ndvi.rst[first.valid.index:last.valid.index])
#   
# ndvi.mk <- overlay(ndvi.stck, 
#                    fun = function(x) MannKendall(x)$tau, 
#                    filename = "out/plots/mk_myd13q1", format = "GTiff", 
#                    overwrite = T)
# 
# # Mann-Kendall tau of significant pixels only
# ndvi.mk.sig <- overlay(ndvi.stck, fun = function(x) {
#   mk <- MannKendall(x)
#   if (mk$sl >= .05) return(NA) else return(mk$tau)
# }, filename = "out/plots/mk_sig_myd13q1", format = "GTiff", overwrite = T)

# Index of first and last scene
ndvi.aug02 <- which(as.yearmon(ndvi.ts.fls[, 1]) == "Aug 2000")[1]
ndvi.jul13 <- rev(which(as.yearmon(ndvi.ts.fls[, 1]) == "Jul 2013"))[1]

# Mann-Kendall tau on 13-month running mean from Aug 2002 to Jul 2013
ndvi.stck <- stack(ndvi.rst[ndvi.aug02:ndvi.jul13])

# ndvi.mk <- overlay(ndvi.stck, 
#                    fun = function(x) {
#                      tmp.kz <- kza(as.numeric(x), m = 13 * 30 / 16, k = 3, 
#                                    impute_tails = T)$kz
#                      MannKendall(tmp.kz)$tau
#                    }, filename = "out/plots/mk_mod13q1_aug02_jul13", 
#                    format = "GTiff", overwrite = T)
# 
# # Mann-Kendall tau of significant pixels only
# ndvi.mk.sig <- overlay(ndvi.stck, 
#                        fun = function(x) {
#                          tmp.kz <- kza(as.numeric(x), m = 13 * 30 / 16, k = 3,
#                                        impute_tails = T)$kz
#                          mk <- MannKendall(tmp.kz)
#                          if (mk$sl >= .001) return(NA) else return(mk$tau)
#                        }, filename = "out/plots/mk_sig001_mod13q1_aug02_jul13", 
#                        format = "GTiff", overwrite = T)

# # Plotting
ndvi.mk <- raster("out/plots/mk_myd13q1_aug02_jul13.tif")
ndvi.mk.sig <- raster("out/plots/mk_sig001_myd13q1_aug02_jul13.tif")

# png("out/plots/mk_myd13q1_aug02_jul13.png", units = "mm", width = 300, 
#     res = 300, pointsize = 20)
# spplot(ndvi.mk, scales = list(draw = T), xlab = "x", ylab = "y", 
#        col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
#        sp.layout = list("sp.lines", rasterToContour(dem)), 
#        par.settings = list(fontsize = list(text = 15)))
# dev.off()
# 
# png("out/plots/mk_sig001_mod13q1_aug00_jul13.png", units = "mm", width = 300, 
#     res = 300, pointsize = 20)
# spplot(ndvi.mk.sig, scales = list(draw = T), xlab = "x", ylab = "y", 
#        col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
#        sp.layout = list("sp.lines", rasterToContour(dem)), 
#        par.settings = list(fontsize = list(text = 15))) # + 
# #   layer(sp.points(plot.utm37s[grep("foc", plot.utm37s$PlotID), 1], 
# #                   pch = 21, col = "black", cex = 2, fill = "red"))
# dev.off()


## NDVI 13 months moving average (KZA)

# Available landuse classes
luc <- unique(plot.utm37s$Categories)
# luc <- luc[!luc %in% c("scientific garden", "Nkweseko garden")]

# Loop through single landuse classes
ndvi.lu_md <- foreach(i = luc, .packages = lib, .combine = function(...) {
  as.data.frame(rbind(...))}) %dopar% {
    # Subset plot data according to current landuse
    tmp.df <- subset(plot.utm37s, Categories == i)
    
    # Extract NDVI time series per plot and calculate median NDVI per time step
    # In case of one plot per landuse class (e.g. Nkweseko)...
    if (nrow(tmp.df) > 1) {
      data.frame(date = ndvi.ts.fls[12:268, 1], 
                 type = i, 
                 value = rowMedians(foreach(j = cellFromXY(ndvi.rst[[20]], tmp.df), 
                                            .combine = "cbind") %do% sapply(ndvi.mat[12:268], function(l) t(l)[j])
                 ), stringsAsFactors = F)
      # In case of multiple plots per landuse class...
    } else {
      data.frame(date = ndvi.ts.fls[12:268, 1], 
                 type = i, 
                 value = sapply(ndvi.mat[12:268], function(l) 
                   t(l)[cellFromXY(ndvi.rst[[1]], tmp.df)]
                 ), stringsAsFactors = F)
    }
  }

# Calculate Kolmogorov-Zurbenko filter for each landuse class
ndvi.lu_md <- foreach(i = luc, .combine = "rbind") %do% {
  tmp.df <- subset(ndvi.lu_md, type == i)
  tmp.df$kz <- kza(tmp.df$value, m = ceiling(13 * 30 / 16), k = 2)$kz
  
  return(tmp.df)
}


## Boxplot 16-day time series

# Loop through single landuse classes
ndvi.lu_bp <- foreach(i = luc, .packages = lib, .combine = "rbind") %dopar% {
  # Subset plot data according to current landuse
  tmp.df <- subset(plot.utm37s, Categories == i)
  
  # Extract NDVI time series per plot of current landuse class
  foreach(j = seq(nrow(tmp.df)), .combine = "rbind") %do% {
    data.frame(date = ndvi.ts.fls[12:268, 1], 
               plot = tmp.df$PlotID[j], 
               type = i,
               value = sapply(ndvi.mat[12:268], function(k) {
                 t(k)[cellFromXY(ndvi.rst[[20]], tmp.df[j, ])]
               }), stringsAsFactors = T)
  } 
}

# Seasonal information
ndvi.lu_bp$month <- strftime(ndvi.lu_bp[, 1], format = "%b")

ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Jan", "Feb")] <- "JF"
ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Mar", "Apr", "May")] <- "MAM"
ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Jun", "Jul", "Aug", "Sep")] <- "JJAS"
ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Oct", "Nov", "Dec")] <- "OND"

# Plotting
ndvi.lu_bp$season <- as.factor(ndvi.lu_bp$season)
levels(ndvi.lu_bp$season)
ndvi.lu_bp$season <- factor(ndvi.lu_bp$season, levels = c("JF", "MAM", "JJAS", "OND"))

ndvi.lu_md$type <- factor(ndvi.lu_md$type)
levels(ndvi.lu_md$type) <- c("Coffee plantation", "Forest Ericaceous", 
                             "Forest lower montane", "Forest Ocotea", 
                             "Forest Ocotea disturbed", "Forest Podocarpus", 
                             "Forest Podocarpus disturbed", "Grassland", 
                             "Helichrysum", "Homegarden", "Maize", "Savanna")
levels(ndvi.lu_bp$type) <- c("Savanna", "Maize", "Forest lower montane", 
                             "Homegarden", "Grassland", "Coffee plantation", 
                             "Forest Ocotea", "Forest Ocotea disturbed", 
                             "Forest Podocarpus", "Forest Podocarpus disturbed", 
                             "Forest Ericaceous", "Helichrysum")
colors <- brewer.pal(9, "PuOr")[c(1, 9, 3, 7)]

insert_minor <- function(major_labs, n_minor) {
  labs <- c(sapply(major_labs, function(x) c(x, rep("", n_minor))))
  labs[1:(length(labs) - n_minor)]
}

# Import data from MODIS cloud product
load("/media/480F-EA7D/modis_cloud/modis_cloud_agg.RData")

cld.lu <- unique(cloud.lu_bp$type)

cld.lu.yr <- foreach(h = cld.lu, .combine = "rbind") %do% {
  tmp.lu <- cloud.lu_bp[grep(h, cloud.lu_bp$type), ]
  tmp.lu.cc <- tmp.lu[complete.cases(tmp.lu), ]
  
  tmp.lu.yrs <- unique(substr(tmp.lu.cc$date, 1, 4))
  
  data.frame(date = tmp.lu.yrs, type = h, 
             value = foreach(i = tmp.lu.yrs, .combine = "c") %do% {
    tmp.lu.cc.yr <- tmp.lu.cc[grep(i, substr(tmp.lu.cc$date, 1, 4)), ]
    return(round(sum(tmp.lu.cc.yr$value) / (length(tmp.lu.cc.yr$value) * 16), 2))
  })
}

# Plot annual cloud cover percentage along with NDVI boxplot time series per
# land-use class and corresponding 13-month moving average mean NDVI
ggplot() + 
  geom_histogram(aes(x = as.Date(paste0(cld.lu.yr$date, "001"), format = "%Y%j"), 
                     y = value), data = cld.lu.yr, stat = "identity", fill = "grey60") +
  geom_boxplot(data = ndvi.lu_bp, aes(x = date, y = value, group = date, 
                                      fill = season), range = 0, 
               colour = "transparent", outlier.shape = "*") + 
  facet_wrap(~ type, nrow = 6, ncol = 2) + 
  scale_x_date(breaks = "2 years", minor_breaks = "1 year", 
               labels = date_format("%Y")) + 
  scale_fill_manual(name = "Season", values = colors, guide = F) + 
  geom_line(aes(x = date, y = kza(value, m = 13 * 30 / 16, k = 3, impute_tails = T)$kz, 
                group = plot), data = ndvi.lu_bp, color = "grey70", alpha = .5) +
  geom_line(aes(x = date, y = kz), data = ndvi.lu_md, color = "red") + 
  xlab("Time (16-day intervals)") + 
  ylab("NDVI / Annual cloud cover [%]") + 
  theme_bw() + 
  theme(axis.title.y = element_text(size = rel(1.15), angle = 90), 
        axis.title.x = element_text(size = rel(1.15), angle = 0), 
        strip.text.x = element_text(size = rel(.95), angle = 0)) 
ggsave(filename = "out/plots/cc_ndvi_boxp_ts.png", units = "mm", 
       height = 300, dpi = 600)
dev.off()


## Cloud cover change detection 2003-2012

ndvi.cc.fls <- list.files("data/cloud_cover", full.names = T, pattern = "absolute")
ndvi.cc.rst <- stack(ndvi.cc.fls[substr(basename(ndvi.cc.fls), 10, 13) %in% 
                                   as.character(2003:2012)])

ndvi.cc.mat <- as.matrix(ndvi.cc.rst)

# Loop through single landuse classes
ndvi.cc <- foreach(i = luc, .packages = lib, .combine = "rbind") %dopar% {
  # Subset plot data according to current landuse
  tmp.df <- subset(plot.utm37s, Categories == i)
  
  # Extract NDVI time series per plot of current landuse class
  foreach(j = seq(nrow(tmp.df)), .combine = "rbind") %do% {
    data.frame(date = 2003:2012, 
               plot = tmp.df$PlotID[j], 
               type = i,
               value = ndvi.cc.mat[cellFromXY(ndvi.cc.rst, tmp.df[j, ]), ], 
               stringsAsFactors = T)
  } 
}

# Chi-squared and labels
chi.squ <- function(x) {
  tmp.chi <- round(chisq.test(x)$p.value, 2)
  return(paste("p", as.character(tmp.chi), sep = " = "))
}

lab <- foreach(i = unique(ndvi.cc$plot), .combine = "c") %do% {
  tmp <- subset(ndvi.cc, plot == i)$value
  return(chi.squ(tmp))
}

ndvi.cc$p.value <- NA
for (i in seq(unique(ndvi.cc$plot))) {
  ndvi.cc$p.value[grep(unique(ndvi.cc$plot)[i], ndvi.cc$plot)] <- lab[i]
}


## GGplot style (without NDVI time series)
ggplot(aes(x = as.factor(date), y = value), data = ndvi.cc) + 
  geom_histogram(stat = "identity") +
  facet_wrap(~ plot, nrow = 12, ncol = 5) + 
  geom_text(aes(x = "2011", y = 22, label = p.value), color = "grey40") + 
  theme_bw() + 
  xlab("Time [y]") + 
  ylab("Total amount of cloudy pixels")
ggsave(filename = "out/plots/ndvi_boxp_ts.png", units = "mm", 
       width = 240 * 2, height = 120 * 4)
dev.off()


## Lattice style (including NDVI time series)

# Cloud cover plot
plot.cc <- xyplot(value ~ date | plot, data = ndvi.cc, panel = function(x, y) {
  panel.barchart(x, y, horizontal = F, box.ratio = 2, col = "grey70")
  
}, xlab = "", ylab = "Total amount of cloudy pixels", layout = c(5, 12))

# NDVI plot
ndvi.lu_bp$date_num <- as.POSIXlt(ndvi.lu_bp$date, format = "%Y-%m%-d")
ndvi.lu_bp$date_num <- 1900 + ndvi.lu_bp$date_num$year + ndvi.lu_bp$date_num$yday / 366

plot.ndvi <- xyplot(value ~ date_num | plot, data = ndvi.lu_bp, panel = function(x, y) {
  panel.xyplot(x, y, type = "l", col = "grey30")
  panel.lines(x, kza(y, m = 13 * 30 / 16, impute_tails = T)$kz, 
              col = brewer.pal(5, "YlOrBr")[5])
}, xlab = "", ylab = "NDVI", layout = c(5, 12))

# Combine cloud cover and NDVI plots
t <- trellis.par.get()
t$layout.heights$strip <- 0.7
t$strip.background$col <- brewer.pal(5, "BuGn")[2]

png(filename = "out/plots/cc_ndvi_lattice.png", width = 500, units = "mm", 
    res = 300, pointsize = 16)
update(doubleYScale(plot.ndvi, plot.cc, add.ylab2 = T, 
             style1 = 0, style2 = 0, under = T), asp = 0.25, 
      par.settings = t)
# Add p-value information 
for (i in seq(12)) {
  for (j in seq(5)) {
    grid::seekViewport(trellis.vpname("panel", j, i))
    grid::grid.text(label = lab[i * j], x = .92, y = .1, gp = gpar(fontsize = 10))
  }
}
dev.off()

# Deregister parallel  backend
stopCluster(cl)