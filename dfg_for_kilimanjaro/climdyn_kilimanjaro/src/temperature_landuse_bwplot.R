################################################################################
##  
##  This program evaluates the air temperature dynamics with respect to
##  different land-cover types.
##  
################################################################################
##
##  Copyright (C) 2013 Thomas Nauss, Tim Appelhans
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##  Please send any comments, suggestions, criticism, or (for our sake) bug
##  reports to admin@environmentalinformatics-marburg.de
##
################################################################################

# Clear workspace
rm(list = ls(all = TRUE))

# Filepaths
# filepath.wd <- "/home/dogbert/software/development/julendat/src/julendat/rmodules"
# filepath.data <- "/media/permanent/r_ki_visualization/bwplot/data/ki"
filepath.wd <- "C://Users//fdetsch//Documents//software//development//julendat//src//julendat//rmodules"
filepath.data <- "D://r_ki_visualization//bwplot//data//"
filepath.output <- "D://r_ki_visualization//bwplot//vis//"

# Working directory
setwd(filepath.wd)

# Required packages
library(zoo)
library(latticeExtra)
library(grid)

# Required functions
source("aggregate.ki.data.R")
source("as.ki.data.R")
# source("/media/permanent/r_ki_visualization/focal/gfRainAmount.R")
source("D://r_ki_visualization//focal_plots//gfRainAmount.R")

# Years
year <- 2012
# Plotting parameters
prm.plot <- c("Ta_200", "rH_200")

# Get unique landuse names via folder names
# dirs <- list.dirs(filepath.data, full.names = FALSE, recursive = FALSE)
# types <- unique(substr(dirs, nchar(dirs)-3, nchar(dirs)-1))
types = c("sav", "mai", "cof", "gra", "hom", "flm", "foc", "fod", "fpo", "fpd", "fer", "hel")

# Loop through landuse types
for (z in seq(types)) {
  
  files.rug <- list.files(filepath.data, recursive = TRUE, full.names = TRUE, pattern = paste(types[z], "rug", "0310.dat$", sep = ".*"))
#   files.wxt <- list.files(filepath.data, recursive = TRUE, full.names = TRUE, pattern = paste(types[z], "wxt", "0310.dat$", sep = ".*"))
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
#   
#   files <- c(files.rug, files.wxt.unique)
  files <- files.rug
  
#   files.agg.diurnal <- do.call("rbind", lapply(seq(files), function(i) {
#     tmp.ki.data <- as.ki.data(files[[i]])
#     data.frame(do.call("data.frame", tmp.ki.data@Parameter)[,prm.plot], 
#                Type = types[z], Month = substr(as.yearmon(tmp.ki.data@AggregationLevels$AggMonth, "%Y%m"), 1, 3), 
#                Month_Num = substr(tmp.ki.data@AggregationLevels$AggMonth, 5, 6))
#   }))
  files.agg.month <- do.call("rbind", lapply(seq(files), function(i) {
    tmp.ki.data <- aggregate.ki.data(files[[i]], "month")
    data.frame(tmp.ki.data[,prm.plot], Type = types[z], Month = substr(as.yearmon(rownames(tmp.ki.data), "%Y%m"), 1, 3), 
               Month_Num = substr(rownames(tmp.ki.data), 5, 6))
  }))
  
  
  if (z == 1) {
#     data.diurnal <- files.agg.diurnal
    data.month <- files.agg.month
  } else {
#     data.diurnal <- rbind(data.diurnal, files.agg.diurnal)
    data.month <- rbind(data.month, files.agg.month)
  }
    
} # End of loop through landuse types

# # Split diurnal data by month
# data.diurnal.month <- split(data.diurnal, data.diurnal$Month)
# Split monthly data by month
data.monthly.month <- split(data.month, data.month$Month)


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
pdf(file = paste(filepath.output, "bwplot_ta.pdf", sep = ""), width = 10, height = 7)
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
pdf(file = paste(filepath.output, "bwplot_rh.pdf", sep = ""), width = 10, height = 7)
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