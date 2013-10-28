################################################################################
### File:         kiGsodPlotTs.R
### Last edit:    Florian Detsch, florian.detsch@staff.uni-marburg.de
### Description:  R script to plot NOAA Global Summary Of Day (GSOD) time series
###               data from Arusha, Kilimanjaro Airport, Moshi, and Nairobi.
################################################################################


## Environmental stuff

# Packages
libs <- c("zoo", "doParallel", "Hmisc", "bfast")
lapply(libs, function(i) require(i, character.only = T))

# Working directory
setwd(path.wd <- switch(Sys.info()[["sysname"]], 
                        "Linux" = {"/media/permanent/ki_gsod_ta"}, 
                        "Windows" = {"E:/ki_gsod_ta"}))


## Data import

# Initial data
fls.orig <- paste0("data/", c("noaa_gsod_arusha_1973_2013_reformat.csv", 
                            "noaa_gsod_airport_1973_2013_reformat.csv", 
                            "noaa_gsod_moshi_1973_2013_reformat.csv", 
                            "noaa_gsod_nairobi_1973_2013_reformat.csv"))

ta.orig <- lapply(fls.orig, function(i) {
  tmp.ts <- read.zoo(i, format = "%Y-%m-%d %H:%M:%S", 
                     header = T, sep = ",", regular = T)
  frequency(tmp.ts) <- 365
  return(tmp.ts)
})

# Gap-filled data
fls.gf <- paste0("out/", c("noaa_gsod_arusha_1973_2013_reformat_gf2.csv", 
                            "noaa_gsod_airport_1973_2013_reformat_gf_li_ssa.csv", 
                            "noaa_gsod_moshi_1973_2013_reformat_gf2.csv", 
                            "noaa_gsod_nairobi_1973_2013_reformat_gf_li_ssa.csv"))

ta.gf <- lapply(fls.gf, function(i) {
  ta.gf.ts <- read.zoo(i, format = "%Y-%m-%d %H:%M:%S", 
                         header = T, sep = ",", regular = T)
  frequency(ta.gf.ts) <- 365
  return(ta.gf.ts)
})


# ## Breakpoint detection
# 
# # Loop through each time series
# tmp.bfast <- foreach(i = tmp, .packages = lib) %dopar% {
#   tmp.ts <- ts(na.exclude(as.numeric(i[, 8])), 
#                start = 1973, end = 2013, frequency = 365)
#   bfast(tmp.ts, season = "harmonic", max.iter = 1, breaks = 5)
# }


## Plotting stuff

# Considered GSOD stations
gsod_stations <- c("Arusha", "Kilimanjaro Airport", "Moshi", "Nairobi")

# png(paste("out/", "1973_2013_orig.png", sep = ""), width = 800, height = 400 * 2.5)
# par(mfrow = c(4, 1), cex.main = 1.5, cex.lab = 1.2)
# foreach(i = c("Arusha", "Kilimanjaro Airport", "Moshi", "Nairobi Airport"), j = 1:4) %do% {
#   
#   tmp.in.ts <- ts(as.numeric(tmp.in[[j]][, 8]), start = 1973, end = 2013, frequency = 365)
#   tmp.out.ts <- ts(as.numeric(tmp.out[[j]][, 8]), start = 1973, end = 2013, frequency = 365)
#   
#   plot(tmp.out.ts, ylim = c(10, 35), main = paste("-", i, "-", sep = " "),
#        xlab = "Time [d]", ylab = "Temperature [°C]", col = "grey75")
#   lines(tmp.in.ts, col = "grey25")
#   legend("top", c("Original data", "Gap-filled data"), col = c("grey25", "grey75"), 
#          lwd = 1, lty = 1, horiz = TRUE, bty = "n", cex = 1.3)
#   minor.tick(nx = 10, ny = 5)
#   
# }
# dev.off()

# Plot time series for each station separately
foreach(i = gsod_stations, j = 1:4) %do% {
  
  # Original data
  ta.orig.ts <- ts(as.numeric(tmp.in[[j]][, 8]), 
                   start = 1973, end = 2013, frequency = 365)
  
  # Gap-filled data
  ta.gf.ts <- ts(na.exclude(as.numeric(ta.gf[[j]][, 8])), 
               start = 1973, end = 2013, frequency = 365)
  ta.gf.stl <- stl(ta.gf.ts, s.window = "periodic", t.window = 4015)
  ta.gf.tslm <- tslm(ta.gf.ts ~ trend)
  
  png(paste("out/", i, "_1973_2013_gf.png", sep = ""), width = 30, height = 15, 
      units = "cm", pointsize = 14, res = 300)
  plot(ta.gf.ts, ylim = c(10, 35), main = paste(i, "1973-2013"),
       xlab = "Time [d]", ylab = "Temperature [°C]", col = "grey75")
  lines(ta.orig.ts, col = "grey25")
  lines(ta.gf.stl$time.series[, 2], lwd = 2)
  lines(fitted(ta.gf.tslm), col = "red", lty = 2)
  legend("top", c("Original data", "Gap-filled data", 
                  "11-year average", "Overall linear trend"), 
         lwd = c(1, 1, 2, 1), lty = c(1, 1, 1, 2), 
         col = c("grey75", "grey25", "black", "red"), 
         horiz = T, bty = "n", xjust = .5, text.width = 7.5)
  minor.tick(nx = 10, ny = 5)
  dev.off()
}

# Plot time series one below the other 
png(paste("out/", "1973_2013_gf.png", sep = ""), width = 30, height = 15 * 3, 
    units = "cm", pointsize = 14, res = 300)
par(mfrow = c(4, 1), cex.main = 1.5, cex.lab = 1.2)
foreach(i = gsod_stations, j = 1:4) %do% {
  # Original data
  ta.orig.ts <- ts(as.numeric(tmp.in[[j]][, 8]), 
                   start = 1973, end = 2013, frequency = 365)
  # Gap-filled data
  ta.gf.ts <- ts(na.exclude(as.numeric(ta.gf[[j]][, 8])), 
               start = 1973, end = 2013, frequency = 365)
  # 11-year moving average
  ta.gf.stl <- stl(ta.gf.ts, s.window = "periodic", t.window = 4015)
  # Overall linear trend
  ta.gf.tslm <- tslm(ta.gf.ts ~ trend)
  
  # Plotting
  plot(ta.gf.ts, ylim = c(10, 35), main = paste("-", i, "-", sep = " "),
       xlab = "Time [d]", ylab = "Temperature [°C]", col = "grey75")
  lines(ta.orig.ts, col = "grey25")
  lines(ta.gf.stl$time.series[, 2], lwd = 2)
  lines(fitted(ta.gf.tslm), col = "red", lty = 2)
  legend("top", c("Original data", "Gap-filled data", "11-year average", "Overall linear trend"), 
         lwd = c(1, 1, 2, 1), lty = c(1, 1, 1, 2), 
         col = c("grey75", "grey25", "black", "red"), 
         horiz = T, bty = "n", xjust = .5, text.width = 7.5, cex = 1.3)
  minor.tick(nx = 10, ny = 5)
}
# Deregister graphic device
dev.off()
