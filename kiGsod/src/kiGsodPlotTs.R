###################################################################
### kiGsodPlotTs.R                                              ###
### Author: Florian Detsch, florian.detsch@staff.uni-marburg.de ###
### Last edited: 2013-07-07                                     ###
###################################################################

## Environmental stuff

# Packages
libs <- c("zoo", "doParallel", "Hmisc", "bfast")

# install.packages(libs)
lapply(libs, function(...) require(..., character.only = TRUE, quietly = TRUE))

# Working directory
setwd("E:/ki_gsod_ta/")


## Data import

# Initial data
fls.in <- paste("data", c("noaa_gsod_arusha_1973_2013_reformat.csv", "noaa_gsod_airport_1973_2013_reformat.csv", 
                          "noaa_gsod_moshi_1973_2013_reformat.csv", "noaa_gsod_nairobi_1973_2013_reformat.csv"), sep = "/")

tmp.in <- lapply(fls.in, function(i) {
  tmp.ts <- read.zoo(i, format = "%Y-%m-%d %H:%M:%S", header = TRUE, sep = ",", regular = TRUE)
  frequency(tmp.ts) <- 365
  
  return(tmp.ts)
})

# Gap-filled data
fls.out <- paste("out", c("noaa_gsod_arusha_1973_2013_reformat_gf2.csv", "noaa_gsod_airport_1973_2013_reformat_gf_li_ssa.csv", 
                          "noaa_gsod_moshi_1973_2013_reformat_gf2.csv", "noaa_gsod_nairobi_1973_2013_reformat_gf_li_ssa.csv"), sep = "/")

tmp.out <- lapply(fls.out, function(i) {
  tmp.out.ts <- read.zoo(i, format = "%Y-%m-%d %H:%M:%S", header = TRUE, sep = ",", regular = TRUE)
  frequency(tmp.out.ts) <- 365
  
  return(tmp.out.ts)
})


## Detect breaks in time series trend / seasonality

# Parallelization
clstr <- makePSOCKcluster(4)
clusterEvalQ(clstr, library(bfast))

# Loop through each time series
clusterExport(clstr, "tmp.out")
tmp.out.bfast <- parLapply(clstr, tmp.out, function(i) {
  tmp.out.ts <- ts(na.exclude(as.numeric(i[, 8])), start = 1973, end = 2013, frequency = 365)
  tmp.out.bfast <- bfast(tmp.out.ts, season = "harmonic", max.iter = 1, breaks = 5)
  
  return(tmp.out.bfast)
})

# Deregister parallel backend
stopCluster(clstr)


## Plotting stuff

# Plot initial time series of all four GSOD stations
png(paste("out/", "1973_2013_orig.png", sep = ""), width = 800, height = 400 * 2.5)
par(mfrow = c(4, 1), cex.main = 1.5, cex.lab = 1.2)
foreach(i = c("Arusha", "Kilimanjaro Airport", "Moshi", "Nairobi Airport"), j = 1:4) %do% {
  tmp.in.ts <- ts(as.numeric(tmp.in[[j]][, 8]), start = 1973, end = 2013, frequency = 365)
  tmp.out.ts <- ts(as.numeric(tmp.out[[j]][, 8]), start = 1973, end = 2013, frequency = 365)
  
  plot(tmp.out.ts, ylim = c(10, 35), main = paste("-", i, "-", sep = " "),
       xlab = "Time [d]", ylab = "Temperature [°C]", col = "grey75")
  lines(tmp.in.ts, col = "grey25")
  legend("top", c("Original data", "Gap-filled data"), col = c("grey25", "grey75"), 
         lwd = 1, lty = 1, horiz = TRUE, bty = "n", cex = 1.3)
  minor.tick(nx = 10, ny = 5)
}
dev.off()

# # Plot gap-filled time series for each station separately
# foreach(i = c("Arusha", "Kilimanjaro Airport", "Moshi", "Nairobi Airport"), j = 1:4) %do% {
#   
#   tmp.out.ts <- ts(na.exclude(as.numeric(tmp.out[[j]][, 8])), start = 1973, end = 2013, frequency = 365)
#   tmp.out.stl <- stl(tmp.out.ts, s.window = "periodic", t.window = 4015)
#   tmp.out.tslm <- tslm(tmp.out.ts ~ trend)
#   
#   png(paste("out/", i, "_1973_2013_gf.png", sep = ""), width = 800, height = 400)
#   plot(tmp.out.ts, ylim = c(10, 35), main = paste("Daily temperatures (1973-2013)\n - ", i, " - ", sep = ""),
#        xlab = "Time [d]", ylab = "Temperature [?C]", col = "grey")
#   lines(tmp.out.stl$time.series[, 2], lwd = 2)
#   lines(fitted(tmp.out.tslm), col = "red", lty = 2)
#   legend("top", c("Daily values", "11-year average", "Overall linear trend"), lwd = c(1, 2, 1), lty = c(1, 1, 2), col = c("grey", "black", "red"), 
#          horiz = TRUE, bty = "n", xjust = .5, text.width = 7.5)
#   minor.tick(nx = 10, ny = 5)
#   dev.off()
# }

# Plot gap-filled time series of all GSOD stations 
png(paste("out/", "1973_2013_gf.png", sep = ""), width = 800, height = 400 * 2.5)
par(mfrow = c(4, 1), cex.main = 1.5, cex.lab = 1.2)
foreach(i = c("Arusha", "Kilimanjaro Airport", "Moshi", "Nairobi Airport"), j = 1:4) %do% {
  tmp.out.ts <- ts(na.exclude(as.numeric(tmp.out[[j]][, 8])), start = 1973, end = 2013, frequency = 365)
  tmp.out.stl <- stl(tmp.out.ts, s.window = "periodic", t.window = 4015)
  tmp.out.tslm <- tslm(tmp.out.ts ~ trend)
  
  plot(tmp.out.ts, ylim = c(10, 35), main = paste("-", i, "-", sep = " "),
       xlab = "Time [d]", ylab = "Temperature [°C]", col = "grey75")
  lines(tmp.out.stl$time.series[, 2], lwd = 2)
  lines(fitted(tmp.out.tslm), col = "red", lty = 2)
  legend("top", c("Gap-filled data", "11-year average", "Overall linear trend"), lwd = c(1, 2, 1), lty = c(1, 1, 2), col = c("grey", "black", "red"), 
         horiz = TRUE, bty = "n", xjust = .5, text.width = 7.5, cex = 1.3)
  minor.tick(nx = 10, ny = 5)
}
dev.off()
