## load packages
library(latticeExtra)
library(grid)
library(RColorBrewer)

## read data
inpath <- "/media/PRECI/slalom_vergleich/sandbox/slalom_vs_mod06/validation/atlantiv_coefficients_feb/figures/figure_13"

##dat <- read.csv(paste(inpath, "cloudsat_py72_py82.csv", sep = "/"), header=T, na.strings="-99.000000")

##dat$cloudsat=dat$cloudsat/100
##dat <- subset(dat, lat >= 36)
##dat <- subset(dat, lat < 44.2)
##dat <- subset(dat, dat$cloudsat > 0)
##dat <- subset(dat, dat$py72 > 0)
##dat <- subset(dat, dat$py82 > 0)

## separating into data for plot 1 and data for plot 2
##dat1 <- subset(dat, lat >= 39.97)
##dat1 <- dat1[order(dat1$lat, decreasing = TRUE),]
##dat2 <- subset(dat, lat <= 39.97 )
##dat2 <- dat2[order(dat2$lat, decreasing = TRUE),]

##write.table(dat1,"dat1.txt")
##write.table(dat2,"dat2.txt")

dat1 <- read.table(paste(inpath, "dat1.txt", sep = "/"), header=T, na.strings="-99.000000")
dat2 <- read.table(paste(inpath, "dat2.txt", sep = "/"), header=T, na.strings="-99.000000")

## Beschriftung
lat1 <- aggregate(dat1$lat, list(dat1$num), FUN = mean)
lon1 <- aggregate(dat1$lon, list(dat1$num), FUN = mean)
lat1 <- round(dat1$lat, 2)
lon1 <- round(dat1$lon, 2)
latlon1 <- paste(as.character(lat1), as.character(lon1), sep = "/")
xat1 <- seq(unique(latlon1))
xat1 <- seq(min(xat1), max(xat1), 25)
xlabs1 <- unique(latlon1[xat1])


lat2 <- aggregate(dat2$lat, list(dat2$num), FUN = mean)
lon2 <- aggregate(dat2$lon, list(dat2$num), FUN = mean)
lat2 <- round(dat2$lat, 2)
lon2 <- round(dat2$lon, 2)
latlon2 <- paste(as.character(lat2), as.character(lon2), sep = "/")
xat2 <- seq(unique(latlon2))
xat2 <- seq(min(xat2), max(xat2), 25)
xlabs2 <- unique(latlon2[xat2])

yat <- seq(0, 35, 5)

## upper plot (=1)
xyplot1 <- xyplot(dat1$py82 ~ dat1$num , 
                  col = brewer.pal(6, "Greys")[3], 
                  pch = 15,
                  scales = list(x = list(at = xat1, labels = xlabs1, 
                                         alternating = 2, tck = c(0, 1)),
                                y = list(at = yat)),
                  par.settings = list(box.umbrella = list(lty = 1, col="black"),
                                      box.rectangle=list(col="black")),
                  page = function(page) grid.text('a)', x = 0.015, y = 0.85),
                  panel = function(...) {
                    panel.xyplot(...)
                    draw.key(list(text=list(c("2B-TAU","M06","SLALOM MODIS"), cex = 0.9),
                                  columns = 1, rows = 3,
                                  points = list(pch = c(18, 17, 15),
                                                cex = 1.2,
                                                col = c(brewer.pal(6, "Greys")[5],brewer.pal(6, "Greys")[4],brewer.pal(6, "Greys")[3])),
                                  background = "white", border = T,
                                  padding.text = 2),
                             draw = T,
                             vp = viewport(x = unit(0.9, "npc"),
                                           y = unit(0.8, "npc"),
                                           just = "centre"))})


xyplot2 <- xyplot(dat1$py72 ~ dat1$num , col = brewer.pal(6, "Greys")[4], pch = 17)
xyplot3 <- xyplot(dat1$cloudsat  ~ dat1$num , col = brewer.pal(6, "Greys")[5], pch = 18)

plot1 <- xyplot1 +as.layer(xyplot2)+as.layer(xyplot3)
plot1 <- update(plot1, 
                asp = 0.2, 
                ylab = "Optical thickness", 
                xlab = "",
                ylim = c (0,36)) +
  layer_(panel.abline(h = yat, col = "grey80", lwd = 0.5))

plot1

## bottom plot (=2)
xyplot1 <- xyplot(dat2$py82 ~ dat2$num , 
                  col = brewer.pal(6, "Greys")[3], 
                  pch = 15,
                  scales = list(x = list(at = xat2, labels = xlabs2, 
                                         alternating = 1, tck = c(1, 0)),
                                y = list(at = yat)),
                  par.settings = list(box.umbrella = list(lty = 1, col="black"),
                                      box.rectangle=list(col="black")),
                  page = function(page) grid.text('b)', x = 0.015, y = 0.85),
#                  panel = function(...) {
#                    panel.xyplot(...)
#                    draw.key(list(text=list(c("2B-TAU","M06","SLALOM MODIS"), cex = 0.9),
#                                  columns = 1, rows = 3,
#                                  points = list(pch = c(18, 15, 17),
#                                                cex = 1.2,
#                                                col = c(brewer.pal(6, "Greys")[5],brewer.pal(6, "Greys")[4],brewer.pal(6, "Greys")[3])),
#                                  background = "white", border = T,
#                                  padding.text = 2),
#                             draw = T,
#                             vp = viewport(x = unit(0.9, "npc"),
#                                           y = unit(0.8, "npc"),
#                                           just = "centre"))})
                    )


xyplot2 <- xyplot(dat2$py72 ~ dat2$num , col = brewer.pal(6, "Greys")[4], pch = 17)
xyplot3 <- xyplot(dat2$cloudsat  ~ dat2$num , col = brewer.pal(6, "Greys")[5], pch = 18)

plot2 <- xyplot1 +as.layer(xyplot2)+as.layer(xyplot3)
plot2 <- update(plot2, 
                asp = 0.2, 
                ylab = "Optical thickness", 
                xlab = "",
                ylim = c (0,36)) +
                  layer_(panel.abline(h = yat, col = "grey80", lwd = 0.5))

plot2


### print ###
png(paste(inpath, "figure_13.png", sep = "/"), res = 300, width = 1024*3, 
    height = 768*3)
print(plot1, position = c(0, -0.4, 1, 1), split = c(1,1,1,2), more = T)
print(plot2, position = c(0, 0, 1, 1.4), split = c(1,2,1,2))
dev.off()

