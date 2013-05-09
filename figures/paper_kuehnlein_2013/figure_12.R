## load packages
library(latticeExtra)
library(grid)

## read data
inpath <- "/media/Meero/validation_atlantic_myd06/figures/figure_12"

dat <- read.table(paste(inpath, "mergeCloudMSG_200806111415_mask_tau_gt_00.dat",
                         sep = "/"), header=T, na.strings="-99.000000")

dat1 <- read.table(paste(inpath, "mergeCloudMSG_200806111415_mask_tau_gt_00_all_01.dat",
                         sep = "/"), header=T, na.strings="-99.000000")
dat2 <- read.table(paste(inpath, "mergeCloudMSG_200806111415_mask_tau_gt_00_all_02.dat",
                         sep = "/"), header=T, na.strings="-99.000000")

dat1 <- subset(dat1, lat >= 36)
dat2 <- subset(dat2, lat < 44.2)

lat1 <- aggregate(dat1$lat, list(dat1$Pixel), FUN = mean)
#lat1 <- subset(lat1, lat1$x < 44.2)
lon1 <- aggregate(dat1$lon, list(dat1$Pixel), FUN = mean)
lon1 <- subset(lon1, lon1$x > -17.8)
lat1 <- round(lat1[,2], 2)
lon1 <- round(lon1[,2], 2)
latlon1 <- paste(as.character(lat1), as.character(lon1), sep = "/")
xat1 <- seq(unique(latlon1))
xat1 <- seq(min(xat1), max(xat1), 15)
xlabs1 <- unique(latlon1[xat1])
# xat1 <- seq(unique(dat1$Pixel))
# xat1 <- seq(min(xat1), max(xat1), 20)
# xlabs1 <- unique(dat1$Pixel)[xat1]
yat <- seq(0, 35, 5)

lat2 <- aggregate(dat2$lat, list(dat2$Pixel), FUN = mean)
#lat2 <- subset(lat2, lat2$x < 44.2)
lon2 <- aggregate(dat2$lon, list(dat2$Pixel), FUN = mean)
lon2 <- subset(lon2, lon2$x > -17.8)
lat2 <- round(lat2[,2], 2)
lon2 <- round(lon2[,2], 2)
latlon2 <- paste(as.character(lat2), as.character(lon2), sep = "/")
xat2 <- seq(unique(latlon2))
xat2 <- seq(min(xat2), max(xat2), 15)
xlabs2 <- unique(latlon2[xat2])

bwplot1 <- bwplot(dat1$CloudTau ~ dat1$Pixel, pch = 8, lty = 1, coef = 0, 
                  alpha = 0, box.ratio = 0, clip = "off",
                  scales = list(x = list(at = xat1, labels = xlabs1, 
                                         alternating = 1, tck = c(1, 0)),
                                y = list(at = yat)),
                  par.settings = list(box.umbrella = list(lty = 1, col="black"),
                                      box.rectangle=list(col="black")),
                  page = function(page) grid.text('b)', x = 0.015, y = 0.85))#, 
                  
bwplot1

xyplot1 <- xyplot(dat1$MSGTau ~ dat1$Pixel, col = "red", pch = 18)

plot1 <- bwplot1 +as.layer(xyplot1)
update(plot1, asp = 0.2)
plot1 <- update(plot1, asp = 0.2, ylab = "Optical thickness") +
  layer_(panel.abline(h = yat, col = "grey80", lwd = 0.5))
plot1

bwplot2 <- bwplot(dat2$CloudTau ~ dat2$Pixel, pch = 8, lty = 1, coef = 0, 
                  alpha = 0, box.ratio = 0,
                  scales = list(x = list(
                    at = xat2, labels = xlabs2, alternating = 2, tck = c(0, 1)),
                                y = list(at = yat)),
                  par.settings = list(box.umbrella = list(lty = 1, col="black"),
                                      box.rectangle=list(col="black")),
                  page = function(page) grid.text('a)', x = 0.015, y = 0.85))#, 

bwplot2

xyplot2 <- xyplot(dat2$MSGTau ~ dat2$Pixel, col = "red", pch = 18)

plot2 <- bwplot2 +as.layer(xyplot2)
plot2
plot2 <- update(plot2, asp = 0.2, ylab = "Optical thickness") +
  layer_(panel.abline(h = yat, col = "grey80", lwd = 0.5)) 

plot2
plot1

png(paste(inpath, "figure_4.png", sep = "/"), res = 300, width = 1024*3, 
    height = 768*3)
print(plot2, position = c(0, -0.4, 1, 1), split = c(1,1,1,2), more = T)
print(plot1, position = c(0, 0, 1, 1.4), split = c(1,2,1,2))
dev.off()
# # file1
# plot <- update(plot, scales = list(x = list(at = c(10,30,50,70)), labels = c("330-227","330-223","331-243","332-263")))
# plot <- update(plot, scales = list(y = list(at = c(5,10,15,20,25,30,35,40)), labels = c("5","10","15","20","25","30","35","40")))
# # Date: 02
# #plot <- update(plot, scales = list(x = list(at = c(0,20,40,60,80,100,115)), labels = c("327-171","327-150","326-131","326-98","326-75","327-42","328-11")))
# 
# 
# plot
# 
# png(filename="verlauf_tau_europe_profiles_04.png", width=1200, height=400, pointsize = 18)
# plot
# dev.off()
# 
