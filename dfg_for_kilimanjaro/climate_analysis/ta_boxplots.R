library(latticeExtra)

path <- "/media/tims_ex/kiliDEM"
setwd(path)

ta <- read.csv("ta_interp/SP1_mean_annual_temperature_all_plots.csv")
ta.obs <- read.csv("ta_interp/sp01_plot_annual_mean_temperature.csv")
ta$type <- substr(ta$PlotID, 1, 3)
ta.obs$type <- substr(ta.obs$PlotID, 1, 3)

mean.elev <- aggregate(ta$elevation, by = list(ta$type), FUN = mean)
sort <- mean.elev[order(mean.elev$x), ]
levels(ta$type) <- sort$Group.1
ta <- ta[-which(ta$type == "sun"), ]
ta.obs <- ta.obs[-which(ta.obs$type == "sun"), ]
ta$type <- factor(ta$type, levels = sort$Group.1)
ta.obs$type <- factor(ta.obs$type, levels = sort$Group.1)

### Plotting
col.blue <- brewer.pal(n = 8, "Paired")[1:2]
col.green <- brewer.pal(n = 8, "Paired")[4:3]
col.red <- brewer.pal(n = 9, "Reds")[c(6,8)]
col.orange <- brewer.pal(n = 8, "Paired")[7:8]
col.brown <- brewer.pal(n = 8, "Pastel1")[6:7]
col.violet <- brewer.pal(n = 8, "PuOr")[7:8]
col.yellow <- brewer.pal(n = 8, "YlOrRd")[c(1,3)]
col.purple <- brewer.pal(n = 8, "PuRd")[c(7,8)]
col.dark.orange <- brewer.pal(n = 9, "YlOrBr")[6]
col.bright.orange <- brewer.pal(n = 9, "YlOrBr")[4]


## Annual boxplots
bwplot.ta <- bwplot(Ta_200 ~ type, data = ta, 
                    ylab = "Temperature [°C]", xlab = "Land cover type", 
                    col = "black", box.ratio = 1, 
                    fill = c(col.purple, rep(col.dark.orange, 3), 
                             col.bright.orange, col.green, col.blue, 
                             rep(col.bright.orange, 2)), pch = "|",
                    par.settings = list(box.rectangle = list(col = "black"), 
                                        box.umbrella = list(col = "black", 
                                                            lty = 1), 
                                        plot.symbol = list(col = "black", 
                                                           pch = 4)), 
                    scales = list(y = list(at = seq(0,30,5)), 
                                  x = list(at = seq(1:12), rot = 45, 
                                           tick.number = 12)))

ta.obs.p <- xyplot(Temp ~ type, data = ta.obs, pch = "*", col = "grey40",
                   cex = 1.8)

png(file = "ta_interp/bwplot_ta_all_est.png", width = 15, height = 15, units = "cm",
    res = 300)
print(bwplot.ta + as.layer(ta.obs.p))
dev.off()



### rH
rh <- read.csv("ta_interp/SP1_mean_annual_rh_all_plots.csv")
rh.obs <- read.csv("ta_interp/sp01_plot_annual_mean_humidity.csv")
rh$type <- substr(rh$PlotID, 1, 3)
rh.obs$type <- substr(rh.obs$PlotID, 1, 3)

mean.elev <- aggregate(rh$elevation, by = list(rh$type), FUN = mean)
sort <- mean.elev[order(mean.elev$x), ]
rh <- rh[-which(rh$type == "sun"), ]
rh.obs <- rh.obs[-which(rh.obs$type == "sun"), ]

rh$type <- factor(rh$type, levels = sort$Group.1)
rh.obs$type <- factor(rh.obs$type, levels = sort$Group.1)

bwplot.rh <- bwplot(rH_200 ~ type, data = rh, 
                    ylab = "Relative Humidity [%]", xlab = "Land cover type", 
                    col = "black", box.ratio = 1, 
                    fill = c(col.purple, rep(col.dark.orange, 3), 
                             col.bright.orange, col.green, col.blue, 
                             rep(col.bright.orange, 2)), pch = "|",
                    par.settings = list(box.rectangle = list(col = "black"), 
                                        box.umbrella = list(col = "black", 
                                                            lty = 1), 
                                        plot.symbol = list(col = "black", 
                                                           pch = 4)), 
                    scales = list(y = list(at = seq(0,100,5)), 
                                  x = list(at = seq(1:12), rot = 45, 
                                           tick.number = 12)))

rh.obs.p <- xyplot(Temp ~ type, data = rh.obs, pch = "*", col = "grey40",
                   cex = 1.8)

png(file = "ta_interp/bwplot_rh_all_est.png", width = 15, height = 15, units = "cm",
    res = 300)
print(bwplot.rh + as.layer(rh.obs.p))
dev.off()