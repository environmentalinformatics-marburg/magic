### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = setwd("/media/fdetsch/XChange/kilimanjaro/ndvi/"), 
       "Windows" = setwd("F:/kilimanjaro/ndvi"))

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal", "randomForest",
         "latticeExtra", "popbio", "ggplot2", "zoo")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

fun <- paste0("src/", c("kifiAggData.R", "probRst.R", "myMinorTick.R", 
                        "ndviCell.R", "evalTree.R", "splitRaster.R"))
sapply(fun, source)

# Parallelization
registerDoParallel(cl <- makeCluster(3))


### Data import

## MODIS fire

# Import daily reclassified fire files (2001-2013)
fire.fls <- list.files("data/md14a1/reclassified/", pattern = ".tif$", 
                       full.names = TRUE)

# Limit time window from Terra-MODIS launch to Dec 2013
st <- grep("2001", fire.fls)[1]
nd <- grep("2013", fire.fls)[length(grep("2013", fire.fls))]
fire.fls <- fire.fls[st:nd]

# Setup time series
fire.dates <- as.Date(substr(basename(fire.fls), 8, 14), format = "%Y%j")

fire.ts <- do.call("c", lapply(2001:2013, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 1)
}))

# Import aggregated fire data
fire.stck <- stack(fire.fls)

# Identify available fire data based on continuous 8-day interval
fire.ts <- merge(data.frame(fire.ts, 1:length(fire.ts)), 
                 data.frame(fire.dates, 1:length(fire.dates)), 
                 by = 1, all.x = TRUE)

# Merge time series with available fire data
fire.ts.fls <- merge(data.frame("date" = fire.ts[, 1], 
                                "yearmon" = as.yearmon(fire.ts[, 1])), 
                     data.frame("date" = as.Date(fire.dates, format = "%Y%j"), 
                                "file" = fire.fls, stringsAsFactors = FALSE), 
                     by = "date", all.x = TRUE)

# Aggregate daily rasters based on extracted 'yearmon'
fire.ts.fls.cc <- fire.ts.fls[complete.cases(fire.ts.fls), ]
fire.ts.rst.cc <- stack(fire.ts.fls.cc$file)
fire.ts.rst.cc.mnth <- 
  stackApply(fire.ts.rst.cc, indices = as.numeric(factor(fire.ts.fls.cc[, 2])), 
             fun = sum, filename = "out/fire_agg/fire_agg_mnth_01_13", 
             format = "GTiff", overwrite = TRUE)

# Extract sum of monthly fire events
fire.ts.df.cc.mnth <- 
  data.frame(yearmon = unique(fire.ts.fls.cc$yearmon), 
             nfires = sapply(1:nlayers(fire.ts.rst.cc.mnth), function(i) {
               sum(fire.ts.rst.cc.mnth[[i]][])
             }))

png("out/fire_agg/fire_agg_mnth_01_13.png", units = "cm", width = 30, height = 12, 
    res = 300, pointsize = 12)
ggplot(aes(x = as.Date(yearmon), y = nfires), 
       data = fire.ts.df.cc.mnth) +
  geom_histogram(stat = "identity", fill = "black") + 
  scale_x_date(breaks = "2 years", minor_breaks = "1 year", 
               labels = date_format("%Y")) + 
  labs(x = "Time [months]", y = "Number of fire pixels") + 
  theme_bw() + 
  theme(axis.title.x = element_text(size = rel(1.2)), 
        axis.text.x = element_text(size = rel(1)), 
        axis.title.y = element_text(size = rel(1.2)), 
        axis.text.y = element_text(size = rel(1)))
dev.off()
