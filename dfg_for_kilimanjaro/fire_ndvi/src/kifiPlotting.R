### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/pa_NDown/ki_modis_ndvi/"}, 
       "Windows" = {path.wd <- "D:/modiscdata_mod/data_rst/"})
setwd(path.wd)

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal", "Kendall", "matrixStats", "ggplot2", 
         "kza", "RColorBrewer", "zoo")
sapply(lib, function(x) stopifnot(require(x, character.only = T)))

# Parallelization
registerDoParallel(cl <- makeCluster(4))


### Data import

## MODIS NDVI 

# List files and order by date
ndvi.fls <- list.files("kifi",  
                       recursive = F, full.names = T)

ndvi.dates <- substr(basename(ndvi.fls), 16, 22)
ndvi.years <- unique(substr(basename(ndvi.fls), 16, 19))

ndvi.fls <- ndvi.fls[order(ndvi.dates)]

# Setup time series
ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 1)
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
    raster(ndvi.ts.fls[i, 2])
  }
}

head(ndvi.ts.fls)

# Remove whitespace

ndvi.shp <- rasterToPolygons(ndvi.rst[[4178]])

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
plot.lonlat <- plot.lonlat[!substr(plot.lonlat$PlotID, 1, 3) %in% c("jul", "sun"),]
coordinates(plot.lonlat) <- ~ POINT_X + POINT_Y
projection(plot.lonlat) <- "+init=epsg:4326"
plot.utm37s <- spTransform(plot.lonlat, CRS("+init=epsg:32737"))


## Mann-Kendall trend

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
ndvi.aug02 <- which(as.yearmon(ndvi.ts.fls[, 1]) == "Aug 2002")[1]
ndvi.jul13 <- rev(which(as.yearmon(ndvi.ts.fls[, 1]) == "Jul 2013"))[1]

# Mann-Kendall tau on 13-month running mean from Aug 2002 to Jul 2013
ndvi.rst <- foreach(i = ndvi.rst, .packages = lib) %dopar% {
  if (class(i) == "logical") {
    return(NA)
  } else {
    i[which(i[] < 1)] <- 0
    return(i)
  }
}

ndvi.rst.cc <- ndvi.rst[!sapply(ndvi.rst, is.logical)]

ndvi.stck <- stack(ndvi.rst.cc)

ndvi.mk <- overlay(ndvi.stck, 
                   fun = function(x) {
                     tmp.kz <- kza(as.numeric(x), m = 13 * 30 /16, k = 3, 
                                   impute_tails = T)$kz
                     MannKendall(tmp.kz)$tau
                   }, filename = "kifi_mk", 
                   format = "GTiff", overwrite = T)


# Mann-Kendall tau of significant pixels only
ndvi.mk.sig <- foreach(z = c(.05, .01, .001), y = c("05", "01", "001"), 
                       .packages = lib) %dopar% {
  overlay(ndvi.stck, 
          fun = function(x) {
            tmp.kz <- kza(as.numeric(x), m = 13 * 30 /16, k = 3,
                          impute_tails = T)$kz
            mk <- MannKendall(tmp.kz)
            if (mk$sl >= z) return(NA) else return(mk$tau)
          }, filename = paste0("kifi_mk_sig", y), 
          format = "GTiff", overwrite = T)
}

# Plotting
dem <- raster("kili_dem_utm.tif")

png("mk_sig001_mod06_jan02_jul13.png", units = "mm", width = 300, 
    res = 300, pointsize = 20)
spplot(ndvi.mk.sig[[3]], scales = list(draw = T), xlab = "x", ylab = "y", 
       col.regions = colorRampPalette(brewer.pal(11, "BrBG")), 
       sp.layout = list("sp.lines", rasterToContour(dem)), 
       par.settings = list(fontsize = list(text = 15)))
dev.off()


## NDVI 13 months moving average (KZA)

# Rasters to matrices
ndvi.mat <- foreach(i = ndvi.rst, .packages = lib) %dopar% as.matrix(i)

# Available landuse classes
luc <- unique(plot.utm37s$Categories)
luc <- luc[!luc %in% c("scientific garden", "Nkweseko garden")]

# Loop through single landuse classes
ndvi.lu_md <- foreach(i = luc, .packages = lib, .combine = function(...) {
  as.data.frame(rbind(...))}) %dopar% {
    # Subset plot data according to current landuse
    tmp.df <- subset(plot.utm37s, Categories == i)
    
    # Extract NDVI time series per plot and calculate median NDVI per time step
    # In case of one plot per landuse class (e.g. Nkweseko)...
    if (nrow(tmp.df) > 1) {
      data.frame(date = ndvi.ts.fls[177:4195, 1], 
                 type = i, 
                 value = rowMedians(foreach(j = cellFromXY(ndvi.rst[[193]], tmp.df), 
                                            .combine = "cbind") %do% sapply(ndvi.mat[177:4195], function(l) t(l)[j]), 
                                    na.rm = T), stringsAsFactors = F)
      # In case of multiple plots per landuse class...
    } else {
      data.frame(date = ndvi.ts.fls[177:4195, 1], 
                 type = i, 
                 value = sapply(ndvi.mat[177:4195], function(l) 
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

# # Plotting
# ggplot(ndvi.lu_md, aes(x = date, y = value)) + 
#   geom_line(color = "grey80") + 
#   geom_line(aes(date, kz), color = "blue") +
#   facet_wrap(~ type, nrow = 4, ncol = 3)


## Boxplot 16-day time series

# Loop through single landuse classes
ndvi.lu_bp <- foreach(i = luc, .packages = lib, .combine = "rbind") %dopar% {
  # Subset plot data according to current landuse
  tmp.df <- subset(plot.utm37s, Categories == i)
  
  # Extract NDVI time series per plot of current landuse class
  foreach(j = seq(nrow(tmp.df)), .combine = "rbind") %do% {
    data.frame(date = ndvi.ts.fls[177:4195, 1], 
               plot = tmp.df$PlotID[j], 
               type = i,
               value = sapply(ndvi.mat[177:4195], function(k) {
                 t(k)[cellFromXY(ndvi.rst[[193]], tmp.df[j, ])]
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

# # Presentation stuff
# ndvi.lu_md$kz <- ndvi.lu_md$kz / 10000
# ndvi.lu_bp$value <- ndvi.lu_bp$value / 10000

# ndvi.lu_md$type <- capitalize(ndvi.lu_md$type)
# levels(ndvi.lu_bp$type) <- "Savanna"

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


ggplot() + 
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
  ylab("Cloud Cover") + 
  theme_bw() + 
  theme(axis.title.y = element_text(size = rel(1.15), angle = 90), 
        axis.title.x = element_text(size = rel(1.15), angle = 0), 
        strip.text.x = element_text(size = rel(0.95), angle = 0)) 
        ggsave(filename = "ndvi_boxp_ts3.png", units = "mm", 
               height = 300, dpi = 600)
        
        
        

ggplot() +
  geom_boxplot(data = ndvi.lu_bp, aes(x = date, y = value, group = date,
                                      fill = season), range = 0,
               colour = "transparent", outlier.shape = "*") +
  facet_wrap(~ type, nrow = 6, ncol = 2) +
  scale_x_date(breaks = "2 years", minor_breaks = "1 year",
               labels = date_format(format = "%Y")) +
  scale_fill_manual(name = "Season", values = colors, guide = F) +
  geom_line(aes(x = date, y = kza(value, m = 13 * 30 / 16, k = 3, impute_tails = T)$kz,
                group = plot), data = ndvi.lu_bp, color = "grey70", alpha = .5) +
  geom_line(aes(x = date, y = kz), data = ndvi.lu_md, color = "red") +
  xlab("Time (16-day intervals)") +
  ylab("NDVI") +
  theme_bw() +
  theme(axis.title.y = element_text(size = rel(1.15), angle = 90),
        axis.title.x = element_text(size = rel(1.15), angle = 0),
        strip.text.x = element_text(size = rel(.95), angle = 0),
        ggsave(filename = "cldcv_boxp_ts2.png", units = "mm",
               height = 300, dpi = 600))


ggplot() + 
  geom_boxplot(data = ndvi.lu_bp, aes(x = date, y = value, group = date, 
                                      fill = season), range = 0, 
               colour = "transparent", outlier.shape = "*") + 
  scale_fill_manual(name = "Season", values = colors) + 
  geom_line(aes(x = date, y = kza(value, m = 13 * 30 / 16, k = 3, impute_tails = T)$kz, 
                group = plot, alpha = 50), 
            data = ndvi.lu_bp, color = "grey70") +
  facet_wrap(~ type, nrow = 6, ncol = 2) + 
  #   scale_x_continuous(breaks = seq(2002, 2014, 1), 
  #                      labels = c("2002", "", "2004", "", "2006", "", "2008", "", 
  #                                 "2010", "", "2012", "", "")) + 
  geom_line(aes(x = date, y = kz), data = ndvi.lu_md, color = "red") + 
  xlab("Time [d]") + 
  ylab("Optical thickness") + 
  theme_bw()
ggsave(filename = "cldcv_boxp_all_qa_outlier2.png", units = "mm", 
       width = 240 * 2, height = 120 * 6)
dev.off()

# ## Boxplot seasonal time series
# 
# ndvi.lu_bp$month <- strftime(ndvi.lu_bp[, 1], format = "%b")
# 
# ndvi.lu_bp$season <- NA
# 
# # JF, MAM, JJAS, OND
# ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Jan", "Feb")] <- "JF"
# ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Mar", "Apr", "May")] <- "MAM"
# ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Jun", "Jul", "Aug", "Sep")] <- "JJAS"
# ndvi.lu_bp$season[ndvi.lu_bp$month %in% c("Oct", "Nov", "Dec")] <- "OND"
# 
# ndvi.lu_bp$season <- paste(ndvi.lu_bp$plot, ndvi.lu_bp$season, 
#                            ifelse(ndvi.lu_bp$month %in% c("Jan", "Feb"), 
#                                   as.numeric(substr(ndvi.lu_bp$date, 1, 4)) - 1, 
#                                   substr(ndvi.lu_bp$date, 1, 4)), sep = "_")
# 
# tmp.df.bp <- subset(ndvi.lu_bp, substr(plot, 1, 3) == "sav")
# 
# tmp.agg <- aggregate(tmp.df.bp$value, by = list(tmp.df.bp$season), FUN = max)
# tmp.agg$date <- sapply(strsplit(tmp.agg[, 1], "_"), "[[", 3)
# 
# tmp.agg$season <- sapply(strsplit(tmp.agg[, 1], "_"), "[[", 2)
# tmp.agg$season[tmp.agg$season == "JF"] <- "01"
# tmp.agg$season[tmp.agg$season == "MAM"] <- "04"
# tmp.agg$season[tmp.agg$season == "JJAS"] <- "07"
# tmp.agg$season[tmp.agg$season == "OND"] <- "11"
# 
# tmp.agg$date <- as.Date(paste(tmp.agg$date, tmp.agg$season, "01", sep = "-"))
# tmp.agg <- tmp.agg[order(tmp.agg$date), ]
# 
# # Plotting
# ggplot() + 
#   geom_boxplot(data = tmp.agg, 
#                aes(x = date, y = x, group = date)) + 
#   geom_line(aes(x = tmp.df$date, y = tmp.df$kz), color = "red")


## Cloud cover change detection 2003-2012

ndvi.cc.fls <- list.files("data/cloud_cover", full.names = T)
ndvi.cc.rst <- stack(ndvi.cc.fls[substr(basename(ndvi.cc.fls), 1, 4) %in% 
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

ggplot() + 
  geom_histogram(data = ndvi.cc, stat = "identity", aes(x = date, y = value))


# Deregister parallel  backend
stopCluster(cl)