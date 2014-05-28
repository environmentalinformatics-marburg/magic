# Clear workspace
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Windows" = setwd("E:/programming/r/various/ki_visualization/bwplot/"), 
       "Linux" = setwd("/media/permanent/programming/r/various/ki_visualization/bwplot"))

# File paths
path.data <- "data"
path.out <- "vis"

# Required packages
lib <- c("zoo", "latticeExtra", "grid")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

# Required functions
source("aggregate.ki.data.R")
source("as.ki.data.R")
# source("D://r_ki_visualization//focal_plots//gfRainAmount.R")

# # Get latest version of processing level 310 for all available plots
# rsync -zarv --include="*/"  --include='*rug*0310.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_ki_pastprocessing/processing/plots/ki/ .
# rsync -zarv --include="*/"  --include='*rug*0310.dat' --exclude='*' eikistations@192.168.191.182:/media/memory01/ei_data_kilimanjaro/processing/plots/ki/ .

# Plotting parameters
prm.plot <- c("Ta_200", "rH_200")

# Get unique landuse names via folder names
# dirs <- list.dirs(filepath.data, full.names = FALSE, recursive = FALSE)
# luc <- unique(substr(dirs, nchar(dirs)-3, nchar(dirs)-1))
luc <- c("sav", "mai", "cof", "hom", "gra", 
         "flm", "foc", "fod", "fpo", "fpd", "fer", "hel")

# Loop through landuse types
data.yr <- do.call("rbind", lapply(luc, function(z) {
  
  files.rug <- list.files(path.data, recursive = TRUE, full.names = TRUE, 
                          pattern = paste(z, "rug", "0310.dat$", sep = ".*"))
  
  #   files.wxt <- list.files(filepath.data, recursive = TRUE, full.names = TRUE, 
  #                           pattern = paste(z, "wxt", "0310.dat$", sep = ".*"))
  #   
  #   if (length(files.wxt) > 0) {
  #     files.wxt.unique <- unlist(lapply(seq(files.wxt), function(i) {
  #       tmp.wxt <- unlist(strsplit(files.wxt[i], "/"))
  #       tmp.plot <- substr(tmp.wxt[length(tmp.wxt)], 8, 11)
  #       tmp.year <- substr(tmp.wxt[length(tmp.wxt)], 20, 23)
  #       
  #       if (anyDuplicated(c(grep(tmp.plot, files.rug), grep(tmp.year, files.rug))) == 0)
  #         files.wxt[i]
  #     }))
  #   }
    
  files <- files.rug
  files <- c(files.rug, files.wxt.unique)
  
  #   files.agg.month <- do.call("rbind", lapply(files, function(i) {
  #     tmp.ki.data <- aggregate.ki.data(i, "month")
  #     data.frame(tmp.ki.data[, prm.plot], Type = z, 
  #                Month = substr(as.yearmon(rownames(tmp.ki.data), "%Y%m"), 1, 3), 
  #                Month_Num = substr(rownames(tmp.ki.data), 5, 6))
  #   }))
  
  plt <- unique(substr(basename(files), 8, 11))
  
  files.agg.yr.mean <- do.call("rbind", lapply(plt, function(h) {
    
    tmp.fls <- files[grep(h, files)]
  
    files.agg.mnth <- lapply(tmp.fls, function(i) {
      tmp.ki.data <- aggregate.ki.data(i, "month")
      data.frame(PlotId = h, 
                 round(tmp.ki.data[, prm.plot], 1), 
                 Type = z)
    })
    
    if (length(files.agg.mnth) == 1) {
      files.agg.mnth.mean <- data.frame(files.agg.mnth)
    } else {
      files.agg.mnth.mean <- data.frame(PlotId = h, 
                                        Ta_200 = rowMeans(sapply(files.agg.mnth, "[[", 2), na.rm = TRUE), 
                                        rH_200 = rowMeans(sapply(files.agg.mnth, "[[", 3), na.rm = TRUE),
                                        Type = z)
    }
    
    return(data.frame(PlotId = h, 
                      Ta_200 = round(mean(files.agg.mnth.mean$Ta_200, na.rm = TRUE), 1), 
                      rh_200 = round(mean(files.agg.mnth.mean$rH_200, na.rm = TRUE), 1), 
                      Type = z))
  
  }))
  
  #   if (z == 1) {
  # #     data.diurnal <- files.agg.diurnal
  #     data.month <- files.agg.month
  #   } else {
  # #     data.diurnal <- rbind(data.diurnal, files.agg.diurnal)
  #     data.month <- rbind(data.month, files.agg.month)
  #   }
  
  return(files.agg.yr.mean)
  
}))

# # Split diurnal data by month
# data.diurnal.month <- split(data.diurnal, data.diurnal$Month)
# # Split monthly data by month
# data.monthly.month <- split(data.month, data.month$Month)


### Plotting

# Colors
# col.ta <- brewer.pal(9, "RdBu")[1] # red
# col.rh <- brewer.pal(9, "RdBu")[length(brewer.pal(9, "RdBu"))] # blue

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

bwplot.ta <- bwplot(Ta_200 ~ Type, data = data.month, 
                    ylab = "Temperature [°C]", xlab = "Land cover type", col = "black", 
                    box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
                    par.settings = list(box.rectangle = list(col = "black"), 
                                        box.umbrella = list(col = "black", lty = 1), 
                                        plot.symbol = list(col = "black", pch = 4)), 
                    scales = list(y = list(at = seq(0,30,5)), 
                                  x = list(at = seq(1:12), rot = 45, tick.number = 12)))

# png(filename = "/media/permanent/r_ki_visualization/bwplot/vis/bwplot_ta.png", width = 1024 * 2, height = 1024 * 1.5, res = 300)
# svg(filename = "/media/permanent/r_ki_visualization/bwplot/vis/bwplot_ta.svg", width = 10, height = 7)
pdf(file = paste(filepath.out, "bwplot_ta.pdf", sep = ""), width = 10, height = 7)
plot(bwplot.ta)
dev.off()


bwplot.rh <- bwplot(rH_200 ~ Type, data = data.month,  
                    ylab = "Relative humidity [%]", xlab = "Land cover type", col = "black", 
                    box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
                    par.settings = list(box.rectangle = list(col = "black"), 
                                        box.umbrella = list(col = "black", lty = 1), 
                                        plot.symbol = list(col = "black", pch = 4)), 
                    scales = list(y = list(at = seq(40,105,10)), 
                                  x = list(at = seq(1:12), rot = 45, tick.number = 12)))

# png(filename = "/media/permanent/r_ki_visualization/bwplot/vis/bwplot_rh.png", width = 1024 * 2, height = 1024 * 1.5, res = 300)
# svg(filename = "/media/permanent/r_ki_visualization/bwplot/vis/bwplot_rh.svg", width = 10, height = 7)
pdf(file = paste(filepath.out, "bwplot_rh.pdf", sep = ""), width = 10, height = 7)
plot(bwplot.rh)
dev.off()


## Monthly boxplots

lapply(seq(data.monthly.month), function(i) {
  
  # Temperature
  bwplot.month.ta <- bwplot(Ta_200 ~ Type, data = subset(data.monthly.month[[i]], Ta_200 < 100),
                            #                             ylim = c(-12.5, 50),
                            ylim = c(-2.5, 30),
                            main = paste("Temperature (", unique(data.monthly.month[[i]]$Month), ")", sep = ""),
                            ylab = "Temperature [Â°C]", xlab = "Land cover type", col = "black", 
                            box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
                            par.settings = list(box.rectangle = list(col = "black"), 
                                                box.umbrella = list(col = "black", lty = 1), 
                                                plot.symbol = list(col = "black", pch = 4)), 
                            #                             scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
                            #                                           y = list(at = seq(floor(range(data.monthly.month[[i]]$Ta_200, na.rm = TRUE)[1] / 5) * 5, 
                            #                                                             ceiling(range(data.monthly.month[[i]]$Ta_200, na.rm = TRUE)[2] / 5) * 5, 5))))
                            scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
                                          y = list(at = seq(-10, 45, 5))))
  
  
  png(filename = paste("/media/permanent/r_ki_visualization/bwplot/vis/monthly/ta/bwplot_ta_", unique(data.monthly.month[[i]]$Month_Num), "_rug.png", sep = ""), 
      width = 1024 * 2, height = 1024 * 1.5, res = 300)
  plot(bwplot.month.ta)
  dev.off()
  
  # Relative humidity
  bwplot.month.rh <- bwplot(rH_200 ~ Type, data = data.monthly.month[[i]],
                            #                             ylim = c(0, 105),
                            ylim = c(42.5, 102.5),
                            main = paste("Relative humidity (", unique(data.monthly.month[[i]]$Month), ")", sep = ""),
                            ylab = "Relative humidity [%]", xlab = "Land cover type", col = "black", 
                            box.ratio = 1, fill = c(col.purple, rep(col.dark.orange, 3), col.bright.orange, col.green, col.blue, rep(col.bright.orange, 2)), pch = "|",
                            par.settings = list(box.rectangle = list(col = "black"), 
                                                box.umbrella = list(col = "black", lty = 1), 
                                                plot.symbol = list(col = "black", pch = 4)), 
                            #                             scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
                            #                                           y = list(at = seq(floor(range(data.monthly.month[[i]]$rH_200, na.rm = TRUE)[1] / 10) * 10, 
                            #                                                             ceiling(range(data.monthly.month[[i]]$rH_200, na.rm = TRUE)[2] / 10) * 10, 10))))
                            scales = list(x = list(at = seq(1:12), rot = 45, tick.number = 12), 
                                          y = list(at = seq(0, 100, 10))))
  
  png(filename = paste("/media/permanent/r_ki_visualization/bwplot/vis/monthly/rh/bwplot_rh_", unique(data.monthly.month[[i]]$Month_Num), "_rug.png", sep = ""), 
      width = 1024 * 2, height = 1024 * 1.5, res = 300)
  plot(bwplot.month.rh)
  dev.off()
  
})