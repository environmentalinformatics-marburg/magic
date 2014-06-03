### Environmental stuff

# Clear workspace
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Windows" = setwd("E:/programming/r/various/ki_visualization/bwplot/"), 
       "Linux" = setwd("/media/permanent/programming/r/various/ki_visualization/bwplot"))

# Required packages
lib <- c("doParallel", "latticeExtra", "grid")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

# Required functions
source("aggregate.ki.data.R")
source("as.ki.data.R")

# Parallelization
registerDoParallel(cl = makeCluster(3))


### Processing

# Import information about installed logger per plot
logger.type <- read.csv("data/plot_logger.csv", stringsAsFactors = FALSE)

# # Get latest version of processing level 310 for all available plots
# rsync -zarv --include="*/"  --include='*wxt*0310.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_ki_pastprocessing/processing/plots/ki/ .
# rsync -zarv --include="*/"  --include='*wxt*0310.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_data_kilimanjaro/processing/plots/ki/ .
# 
# rsync -zarv --include="*/"  --include='*rad*0290.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_ki_pastprocessing/processing/plots/ki/ .
# rsync -zarv --include="*/"  --include='*rad*0290.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_data_kilimanjaro/processing/plots/ki/ .
# 
# rsync -zarv --include="*/"  --include='*rug*0310.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_ki_pastprocessing/processing/plots/ki/ .
# rsync -zarv --include="*/"  --include='*rug*0310.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_data_kilimanjaro/processing/plots/ki/ .

# Parameters under investigation
prm.plot <- c("Ta_200", "rH_200")

# Loop through available plots
data.yr <- foreach(i = 1:nrow(logger.type), .combine = "rbind", 
                   .export = c("as.ki.data", "aggregate.ki.data")) %dopar% {
  
  plt <- logger.type[i, 1]
  type <- substr(plt, 1, 3)
  
  if (is.na(logger.type[i, 2]))
    return(data.frame(PlotId = plt, 
                      Ta_200 = NA, 
                      rH_200 = NA, 
                      Type = type))
  
  files.rug <- list.files("data/", recursive = TRUE, full.names = TRUE, 
                          pattern = paste(plt, logger.type[i, 2], 
                                          ifelse(logger.type[i, 2] %in% c("rug", "wxt"), 
                                                 "0310.dat$", "0290.dat$"), 
                                          sep = ".*"))
  
  if (length(files.rug) == 0)
    return(data.frame(PlotId = plt, 
                      Ta_200 = NA, 
                      rH_200 = NA, 
                      Type = type))
  
  
  files <- files.rug
  
  files.agg.mnth <- lapply(files, function(j) {
    tmp.ki.data <- aggregate.ki.data(j, "month")
    data.frame(PlotId = plt, 
               round(tmp.ki.data[, prm.plot], 1), 
               Type = type)
  })
  
  if (length(files.agg.mnth) == 1) {
    files.agg.mnth.mean <- data.frame(files.agg.mnth)
  } else {
    files.agg.mnth.mean <- data.frame(PlotId = plt, 
                                      Ta_200 = rowMeans(sapply(files.agg.mnth, "[[", 2), na.rm = TRUE), 
                                      rH_200 = rowMeans(sapply(files.agg.mnth, "[[", 3), na.rm = TRUE),
                                      Type = type)
  }
  
  files.agg.yr.mean <- 
    data.frame(PlotId = plt, 
               Ta_200 = round(mean(files.agg.mnth.mean$Ta_200, na.rm = TRUE), 1), 
               rH_200 = round(mean(files.agg.mnth.mean$rH_200, na.rm = TRUE), 1), 
               Type = type)
  
  return(files.agg.yr.mean)
  
}

write.csv(data.yr, "out/plot_annual_means.csv", row.names = FALSE, 
          quote = FALSE)

# Identify Ta and rH ranges of each single land-use class
data.yr.range <- foreach(i = unique(data.yr$Type), .combine = "rbind") %do% {
  data.yr.sub <- data.yr[grep(i, data.yr$Type), ]
  range.ta <- range(data.yr.sub$Ta_200, na.rm = TRUE)
  range.rh <- range(data.yr.sub$rH_200, na.rm = TRUE)
  
  return(data.frame(Type = i, 
                    Ta_200_min = range.ta[1], 
                    Ta_200_max = range.ta[2], 
                    rH_200_min = range.rh[1], 
                    rH_200_max = range.rh[2]))
}

# Replace infinite entries with NA
for (i in 2:5)
  data.yr.range[is.infinite(data.yr.range[, i]), i] <- NA

write.csv(data.yr.range, "out/luc_annual_means_range.csv", row.names = FALSE, 
          quote = FALSE)



### Plotting

# Valid land-cover types
index <- data.yr$Type %in% c("emg", "mcg", "mch", "mwh", "nkw", "sun")
data.yr <- data.yr[!index, ]
# Reorder factor levels -> plotting order from lowest to highest land-use class
data.yr$Type <- factor(data.yr$Type, 
                       levels = c("sav", "mai", "cof", "gra", "hom", "flm", 
                                  "foc", "fod", "fpo", "fpd", "fer", "hel"))

# Colors
col.blue <- brewer.pal(n = 8, "Paired")[1:2]
col.green <- brewer.pal(n = 8, "Paired")[3:4]
col.red <- brewer.pal(n = 9, "Reds")[c(6,8)]
col.orange <- brewer.pal(n = 8, "Paired")[7:8]
col.brown <- brewer.pal(n = 8, "Pastel1")[6:7]
col.violet <- brewer.pal(n = 8, "PuOr")[7:8]
col.yellow <- brewer.pal(n = 8, "YlOrRd")[c(1,3)]
col.purple <- brewer.pal(n = 8, "PuRd")[c(7,8)]
col.dark.orange <- brewer.pal(n = 9, "YlOrBr")[6]
col.bright.orange <- brewer.pal(n = 9, "YlOrBr")[4]


## Annual boxplots

# Temperature
bwplot.ta <- bwplot(Ta_200 ~ Type, data = data.yr, 
                    ylab = "Temperature [°C]", xlab = "Land cover type", col = "black", 
                    box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
                    par.settings = list(box.rectangle = list(col = "black"), 
                                        box.umbrella = list(col = "black", lty = 1), 
                                        plot.symbol = list(col = "black", pch = 4)), 
                    scales = list(y = list(at = seq(0,30,5)), 
                                  x = list(at = seq(1:12), rot = 45, tick.number = 12)))

# png("out/bwplot_ta.png", width = 1024 * 2, height = 1024 * 1.5, res = 300)
pdf("out/bwplot_ta.pdf", width = 10, height = 7)
plot(bwplot.ta)
dev.off()

# Humidity
bwplot.rh <- bwplot(rH_200 ~ Type, data = data.yr,  
                    ylab = "Relative humidity [%]", xlab = "Land cover type", col = "black", 
                    box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
                    par.settings = list(box.rectangle = list(col = "black"), 
                                        box.umbrella = list(col = "black", lty = 1), 
                                        plot.symbol = list(col = "black", pch = 4)), 
                    scales = list(y = list(at = seq(40,105,10)), 
                                  x = list(at = seq(1:12), rot = 45, tick.number = 12)))

# png("out/bwplot_rh.png", width = 1024 * 2, height = 1024 * 1.5, res = 300)
pdf("out/bwplot_rh.pdf", width = 10, height = 7)
plot(bwplot.rh)
dev.off()


# ## Monthly boxplots -> currently not working
# 
# lapply(seq(data.monthly.month), function(i) {
#   
#   # Temperature
#   bwplot.month.ta <- bwplot(Ta_200 ~ Type, data = subset(data.monthly.month[[i]], Ta_200 < 100),
#                             #                             ylim = c(-12.5, 50),
#                             ylim = c(-2.5, 30),
#                             main = paste("Temperature (", unique(data.monthly.month[[i]]$Month), ")", sep = ""),
#                             ylab = "Temperature [Â°C]", xlab = "Land cover type", col = "black", 
#                             box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
#                             par.settings = list(box.rectangle = list(col = "black"), 
#                                                 box.umbrella = list(col = "black", lty = 1), 
#                                                 plot.symbol = list(col = "black", pch = 4)), 
#                             #                             scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
#                             #                                           y = list(at = seq(floor(range(data.monthly.month[[i]]$Ta_200, na.rm = TRUE)[1] / 5) * 5, 
#                             #                                                             ceiling(range(data.monthly.month[[i]]$Ta_200, na.rm = TRUE)[2] / 5) * 5, 5))))
#                             scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
#                                           y = list(at = seq(-10, 45, 5))))
#   
#   
#   png(filename = paste("/media/permanent/r_ki_visualization/bwplot/vis/monthly/ta/bwplot_ta_", unique(data.monthly.month[[i]]$Month_Num), "_rug.png", sep = ""), 
#       width = 1024 * 2, height = 1024 * 1.5, res = 300)
#   plot(bwplot.month.ta)
#   dev.off()
#   
#   # Relative humidity
#   bwplot.month.rh <- bwplot(rH_200 ~ Type, data = data.monthly.month[[i]],
#                             #                             ylim = c(0, 105),
#                             ylim = c(42.5, 102.5),
#                             main = paste("Relative humidity (", unique(data.monthly.month[[i]]$Month), ")", sep = ""),
#                             ylab = "Relative humidity [%]", xlab = "Land cover type", col = "black", 
#                             box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
#                             par.settings = list(box.rectangle = list(col = "black"), 
#                                                 box.umbrella = list(col = "black", lty = 1), 
#                                                 plot.symbol = list(col = "black", pch = 4)), 
#                             #                             scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
#                             #                                           y = list(at = seq(floor(range(data.monthly.month[[i]]$rH_200, na.rm = TRUE)[1] / 10) * 10, 
#                             #                                                             ceiling(range(data.monthly.month[[i]]$rH_200, na.rm = TRUE)[2] / 10) * 10, 10))))
#                             scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
#                                           y = list(at = seq(0, 100, 10))))
#   
#   png(filename = paste("/media/permanent/r_ki_visualization/bwplot/vis/monthly/rh/bwplot_rh_", unique(data.monthly.month[[i]]$Month_Num), "_rug.png", sep = ""), 
#       width = 1024 * 2, height = 1024 * 1.5, res = 300)
#   plot(bwplot.month.rh)
#   dev.off()
#   
# })