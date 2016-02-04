### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = setwd("/media/fdetsch/XChange/kilimanjaro/ndvi/"), 
       "Windows" = setwd("D:/kilimanjaro/ndvi"))

# Required packages and functions
lib <- c("raster", "rgdal", "ggplot2", "scales")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

source("src/kifiAggData.R")


### Data import

st_year <- "2001"
nd_year <- "2013"

## MODIS fire

# Import daily reclassified fire files (2001-2013)
fire.fls <- list.files("data/md14a1/reclassified/", pattern = ".tif$", 
                       full.names = TRUE)

# Limit time window from Terra-MODIS launch to Dec 2013
st <- grep(st_year, fire.fls)[1]
nd <- grep(nd_year, fire.fls)[length(grep(nd_year, fire.fls))]
fire.fls <- fire.fls[st:nd]

# Import reclassified fire data
fire_rst <- stack(fire.fls)

# Aggregate 8-day intervals
dates <- as.Date(substr(basename(fire.fls), 8, 14), format = "%Y%j")

st_date <- as.Date(paste0(st_year, "-01-01"))
nd_date <- as.Date(paste0(nd_year, "-12-31"))
seq_dates <- seq(st_date, nd_date, "day")

df_seq_dates <- merge(data.frame(seq_dates), data.frame(dates, fire.fls), 
                      all.x = TRUE, by = 1)

fire_rst_agg8day <- kifiAggData(data = df_seq_dates, 
                                years = st_year:nd_year, 
                                dsn = "data/md14a1/aggregated/", 
                                out.str = "aggsum_8day_md14a1", 
                                format = "GTiff", overwrite = TRUE)

# Aggregate months
dates <- as.Date(substr(basename(fire.fls), 8, 14), format = "%Y%j")
months <- strftime(dates, format = "%Y%m")
indices <- as.numeric(as.factor(months))

fire_rst_agg <- stackApply(fire_rst, indices = indices, fun = sum, 
                           filename = "data/md14a1/aggregated/aggsum", 
                           bylayer = TRUE, suffix = paste0("md14a1_", unique(months)), 
                           format = "GTiff", overwrite = TRUE)

# Extract sum of monthly fire events
fire_df_agg <- data.frame(date = as.Date(paste0(unique(months), "01"), format = "%Y%m%d"),
                          nfires = sapply(unstack(fire_rst_agg), function(i) {
                            sum(i[], na.rm = TRUE)
                          }))

png("vis/fire/fire_aggsum_mnth_01_13.png", units = "cm", width = 30, 
    height = 12, res = 300, pointsize = 12)
ggplot(aes(x = date, y = nfires), data = fire_df_agg) +
  geom_histogram(stat = "identity", fill = "black") + 
  scale_x_date(breaks = "2 years", minor_breaks = "1 year", 
               labels = date_format("%Y")) + 
  labs(x = "Time (months)", y = "Number of fire pixels") + 
  theme_bw() + 
  theme(axis.title.x = element_text(size = rel(1.2)), 
        axis.text.x = element_text(size = rel(1)), 
        axis.title.y = element_text(size = rel(1.2)), 
        axis.text.y = element_text(size = rel(1)))
dev.off()
