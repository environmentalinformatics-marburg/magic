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

# Parallelization
registerDoParallel(cl <- makeCluster(4))


## Data import

# # Initial data
# fls.in <- paste0("data/", c("noaa_gsod_arusha_1973_2013_reformat.csv", 
#                             "noaa_gsod_airport_1973_2013_reformat.csv", 
#                             "noaa_gsod_moshi_1973_2013_reformat.csv", 
#                             "noaa_gsod_nairobi_1973_2013_reformat.csv"))
# 
# tmp.in <- lapply(fls.in, function(i) {
#   tmp.ts <- read.zoo(i, format = "%Y-%m-%d %H:%M:%S", 
#                      header = T, sep = ",", regular = T)
#   frequency(tmp.ts) <- 365
#   return(tmp.ts)
# })

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
gsod_stations <- c("Arusha", "Kilimanjaro Airport", "Moshi", "Nairobi Airport")

# Plot time series for each station separately
foreach(i = gsod_stations, j = 1:4) %do% {
  tmp.ts <- ts(na.exclude(as.numeric(ta.gf[[j]][, 8])), 
               start = 1973, end = 2013, frequency = 365)
  tmp.stl <- stl(tmp.ts, s.window = "periodic", t.window = 4015)
  tmp.tslm <- tslm(tmp.ts ~ trend)
  
  png(paste("out/", i, "_1973_2013_gf.png", sep = ""), width = 800, height = 400)
  plot(tmp.ts, ylim = c(10, 35), main = paste("Daily temperatures (1973-2013)\n - ", i, " - ", sep = ""),
       xlab = "Time [d]", ylab = "Temperature [°C]", col = "grey")
  lines(tmp.stl$time.series[, 2], lwd = 2)
  lines(fitted(tmp.tslm), col = "red", lty = 2)
  legend("top", c("Daily values", "11-year average", "Overall linear trend"), 
         lwd = c(1, 2, 1), lty = c(1, 1, 2), col = c("grey", "black", "red"), 
         horiz = TRUE, bty = "n", xjust = .5, text.width = 7.5)
  minor.tick(nx = 10, ny = 5)
  dev.off()
}

# Plot time series one below the other 
png(paste("out/", "1973_2013_gf.png", sep = ""), width = 800, height = 400 * 2.5)
par(mfrow = c(4, 1), cex.main = 1.5, cex.lab = 1.2)
foreach(i = gsod_stations, j = 1:4) %do% {
  # Time series
  tmp.ts <- ts(na.exclude(as.numeric(ta.gf[[j]][, 8])), 
               start = 1973, end = 2013, frequency = 365)
  # 11-year moving average
  tmp.stl <- stl(tmp.ts, s.window = "periodic", t.window = 4015)
  # Overall linear trend
  tmp.tslm <- tslm(tmp.ts ~ trend)
  
  # Plotting
  plot(tmp.ts, ylim = c(10, 35), main = paste("-", i, "-", sep = " "),
       xlab = "Time [d]", ylab = "Temperature [°C]", col = "grey75")
  lines(tmp.stl$time.series[, 2], lwd = 2)
  lines(fitted(tmp.tslm), col = "red", lty = 2)
  legend("top", c("Gap-filled data", "11-year average", "Overall linear trend"), 
         lwd = c(1, 2, 1), lty = c(1, 1, 2), col = c("grey", "black", "red"), 
         horiz = TRUE, bty = "n", xjust = .5, text.width = 7.5, cex = 1.3)
  minor.tick(nx = 10, ny = 5)
}

# Deregister graphic device
dev.off()

# Deregister parallel backend
stopCluster(cl)

