lib <- c("raster", "zoo", "ggplot2", "doParallel", "RColorBrewer")
sapply(lib, function(x) library(x, character.only = TRUE))

registerDoParallel(cl <- makeCluster(3))

setwd("/media/envin/XChange/kilimanjaro/ndvi/")

source("src/multiVectorHarmonics.R")

# Terra
fls_mod <- list.files("data/md14a1/low/", pattern = "^CRP_MOD", full.names = TRUE)
rst_mod <- stack(fls_mod)

val_mod <- foreach(i = 1:nlayers(rst_mod), .packages = c("raster", "rgdal"), 
                   .combine = "c") %dopar% {
  nq <- unique(rst_mod[[i]])
  return(7 %in% nq)
}

which(val_mod)

# Aqua
fls_myd <- list.files("data/md14a1/", pattern = "^CRP_MYD.*.tif$", full.names = TRUE)
rst_myd <- stack(fls_myd)

val_myd <- foreach(i = 1:nlayers(rst_myd), .packages = c("raster", "rgdal"), 
                   .combine = "c") %dopar% {
  nq <- unique(rst_myd[[i]])
  return(7 %in% nq)
}

which(val_myd)

# Visual comparison
rst_low_crp <- stack("data/md14a1/low/CRP_MOD14A1.A2001321.FireMask.tif")[[3]] # identical to plot(rst_mod[[600]])
rst_low_mrg <- raster("data/md14a1/low/MRG_CRP_MCD14A1.A2001323.FireMask.tif")
rst_low_rcl <- raster("data/md14a1/low/RCL_MRG_CRP_MCD14A1.A2001323.FireMask.tif")
rst_nom_rcl <- raster("data/md14a1/nominal/RCL_MRG_CRP_MCD14A1.A2001323.FireMask.tif")


### Amount of low confident, medium confident and high confident fires in 
### merged (MRG*) layers

fls_mrg <- list.files("data/md14a1/low", pattern = "^MRG.*.tif$", full.names = TRUE)
st <- grep("2001", fls_mrg)[1]
nd <- grep("2013", fls_mrg)[length(grep("2013", fls_mrg))]
fls_mrg <- fls_mrg[st:nd]
rst_mrg <- stack(fls_mrg)

tbl_cfd <- foreach(i = 1:nlayers(rst_mrg), .packages = c("raster", "rgdal"), 
                   .combine = "rbind") %dopar% {
  val <- getValues(rst_mrg[[i]])
  lo <- sum(val %in% c(7, 17, 27, 37, 47, 57, 67, 70:77))
  no <- sum(val %in% c(8, 18, 28, 38, 48, 58, 68, 78, 80:88))
  hi <- sum(val %in% c(9, 19, 29, 39, 49, 59, 69, 79, 89, 90:99))
  data.frame(lo = lo, no = no, hi = hi)
}

## Statistics

# Number of days with active fires
tbl_cfd$total <- rowSums(tbl_cfd)
id <- !sapply(1:nrow(tbl_cfd), function(i) all(tbl_cfd[i, 1:3] == 0))
sum(id)

# Total amount of identified fire pixels
sum(tbl_cfd$total)

# Total and percentage amount of low, nominal and high confidence fire pixels
colSums(tbl_cfd[, 1:3])
colSums(tbl_cfd[, 1:3]) / sum(colSums(tbl_cfd[, 1:3]))


## Visualization

# Time series plot of monthly amount of active fire pixels
fls_agg1m <- list.files("data/md14a1/low/aggregated", pattern = "^aggsum_md14a1", 
                        full.names = TRUE)
rst_agg1m <- stack(fls_agg1m)

dates_mrg <- sapply(strsplit(basename(fls_mrg), "\\."), "[[", 2)
dates_mrg <- substr(dates_mrg, 2, nchar(dates_mrg))
dates_mrg <- as.Date(dates_mrg, format = "%Y%j")
tbl_cfd$date <- dates_mrg

tbl_cfd_agg <- aggregate(tbl_cfd[, 1:4], by = list(as.yearmon(tbl_cfd$date)), 
                         FUN = sum)
tbl_cfd_agg[, 1] <- as.Date(tbl_cfd_agg[, 1])
names(tbl_cfd_agg)[1] <- "date"

ggplot(aes(x = date, y = total), data = tbl_cfd_agg) + 
  geom_histogram(stat = "identity", fill = "grey50") + 
  stat_smooth(method = "lm", lwd = 2, lty = 2, color = "black") + 
  labs(x = "\nTime (months)", y = "No. of active fire pixels\n") + 
  theme_bw()

# Overall observed active fire pixels per month between 2001 and 2013
val_sum <- sapply(1:nlayers(rst_agg1m), function(i) {
  sum(rst_agg1m[[i]][], na.rm = TRUE)
})

months <- sapply(strsplit(basename(fls_agg1m), "_"), "[[", 3)
months <- substr(months, 5, 6)

val_sum_agg <- aggregate(val_sum, by = list(months), FUN = sum)
names(val_sum_agg) <- c("month", "value")

ggplot(aes(x = month, y = value), data = val_sum_agg) + 
  geom_histogram(stat = "identity") + 
  labs(x = "\nMonth", y = "No. of active fires\n") + 
  theme_bw()

# Observed active fire pixels per month 2001-05 vs. 2009-13
yrmn <- sapply(strsplit(basename(fls_agg1m), "_"), "[[", 3)
yrmn <- substr(yrmn, 1, 6)

harm_0105_0913 <- multiVectorHarmonics(rst_agg1m, time_info = yrmn, 
                                       intervals = c(2001, 2009), width = 5)
ggplot(aes(x = month, y = value, group = interval, colour = interval, 
           fill = interval), data = harm_0105_0913) + 
#   geom_line() + 
  geom_histogram(stat = "identity", position = "dodge") + 
  labs(x = "\nMonth", y = "No. of active fires\n") +
  scale_colour_manual("", values = c("black", "grey65")) + 
  scale_fill_manual("", values = c("black", "grey65")) + 
  theme_bw()

# Same issue, but for 2001-04 vs. 2004-07 vs. 2007-10 vs. 2010-13
harm_0104_0407_0710_1013 <- multiVectorHarmonics(rst_agg1m, time_info = yrmn, 
                                                 intervals = seq(2001, 2010, 3), 
                                                 width = 4)

ggplot(aes(x = month, y = value, group = interval, colour = interval), 
       data = harm_0104_0407_0710_1013) + 
  geom_line(lwd = 2) + 
  labs(x = "\nMonth", y = "No. of active fires\n") +
  scale_colour_manual("", values = brewer.pal(4, "Reds")) + 
  theme_bw()
