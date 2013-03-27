################################################################################
##  
##  This program analyses NDVI dynamics based on the GIMMS and MODIS datasets.
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

### Staging area ###############################################################
# Load libraries (echo=FALSE,)
library(lattice)
library(latticeExtra)
library(Kendall)
library(mgcv)
library(gamair)
library(stats)
library(bfast)
library (ggplot2)
library (mapproj)
library (maps)
library (maptools)
library(gridExtra)
library(dtw)

# Check operation system and set paths.
actsys <- Sys.info()['sysname']
path.gis.win <- "D:/temp/kilimanjaro_ndvi_dynamics/gis"
path.gis.lin <- "/media/permanent/temp/kilimanjaro_ndvi_dynamics/gis"
path.ghcn.win <- "D:/temp/lcd_kilimanjaro/rainfall/ghcn" 
path.ghcn.lin <- "/media/permanent/temp/lcd_kilimanjaro/rainfall/ghcn"
path.snht.win <- "D:/temp/kilimanjaro_ndvi_dynamics/scripts/ndvidyn/src/snht.R"
path.snht.lin <- "/media/permanent/temp/kilimanjaro_ndvi_dynamics/scripts/ndvidyn/src/snht.R"
path.ioa.win <- "D:/temp/kilimanjaro_ndvi_dynamics/scripts/ndvidyn/src/ioa.R"
path.ioa.lin <- "/media/permanent/temp/kilimanjaro_ndvi_dynamics/scripts/ndvidyn/src/ioa.R"

# Script from http://www.student.unibe.ch/user/phaenggi/rscripts.html
if (actsys == "Windows") {
  source(path.snht.win)
  source(path.ioa.win)
} else {
  source(path.snht.lin)
  source(path.ioa.lin)
}

# Set mode
compute <- FALSE

# NDVI dynamics between 1982 and 2006
# To analyse vegetation dynamics between 1982 and 2006, the AVHRR-based
# GIMMS dataset is used. The original GIMMS values have been extracted for 169
# pixels centered arround Mt. Kilimanjaro using SAGA GIS.
# The NOAA-AVHRR systems used within this study are
# NOAA 7 for 01/1982 to 02/1985
# NOAA 9 for 03/1985 to 10/1988
# NOAA 11 for 11/1988 to 08/1994
# NOAA 9 for 09/1994 to 01/1995
# NOAA 14 for 02/1995 to 10/2000
# NOAA 16 for 11/2000 to 12/2003
# NOAA 17 for 01/2004 to 12/2006
# Read original gimms values for 1982 to 2006 for 169 pixels arround
# Kilimanjaro, set headers using PIDs and convert date infomration to date
# object.
if (actsys == "Windows") {
  wd <- path.gis.win
  setwd(wd)
} else {
  wd <- path.gis.lin
  setwd(wd)
}
gndvi.org <- read.csv("01_kilimanjaro_pixel_gimms_region_2012-12-10_gimms.csv",
                      header=TRUE, sep = ",")
colnames(gndvi.org) <- c(colnames(gndvi.org[1]), colnames(gndvi.org[2]),  
                              paste("PID", 
                                    apply(gndvi.org[4,3:length(gndvi.org)], 2,
                                          toString),
                                    sep="")[1:(length(gndvi.org)-2)])
gndvi.org$DATE <- as.Date(strptime(paste(gndvi.org$DATE), "%Y-%m-%d"))

### Pixel-based analysis #######################################################
### Time-series decomposition and Mann-Kendall trend ###########################
# Decompose time series, identify breacks and compute 11-year running
# Mann-Kendall trend. Plot time series graphs for each Pixel to a pdf file.
# Store the resulting datasets as csv file for further analysis so this
# procedure can be scipped next time.
gndvi.org.pdat <- subset(gndvi.org, gndvi.org$DATE > 1900)
if (compute) {
  pdf("gndvi.org.pdat.pdf")
  gndvi.org.pdat.mk11 <- list()
  gndvi.org.pdat.bfast <- list()
  for (j in 1:(length(gndvi.org)-2)) {
    i <- j+2
    gndvi.org.pdat.ts <- ts(gndvi.org.pdat[, i], 
                            start=as.numeric(format(head(gndvi.org.pdat$DATE,
                                                         1),format = "%Y")), 
                            freq=12)
    
    # STL
    gndvi.org.pdat.ts.stl <- stl((gndvi.org.pdat.ts),
                                 s.window="periodic", t.window=12)
    
    gndvi.org.pdat.ts.stl300 <- stl((gndvi.org.pdat.ts),
                                    s.window="periodic", t.window=300)
    
    # 11-year running Mann-Kendall trend
    gndvi.org.pdat.mk11[[j]] <- sapply(seq(15), function(k) {
      date.start <- 1981 + k
      date.end <- date.start + 11
      gndvi.org.pdat.ts.stl.trend <- gndvi.org.pdat.ts.stl$time.series[,'trend']
      gndvi.org.pdat.ts.stl.trend.sub <- gndvi.org.pdat.ts.stl.trend[
        time(gndvi.org.pdat.ts.stl.trend)>= date.start &
          time(gndvi.org.pdat.ts.stl.trend)< date.end]
      temp.mk <- cor.test(gndvi.org.pdat.ts.stl.trend.sub,
                          time(seq(from=date.start, to=date.end-1/12, by=1/12)),
                          method="kendall", alternative = "two.sided")
      return.mk <- list(PID = j,
                        DATEMEAN = date.start + (date.end-date.start-1)/2,
                        tau = temp.mk$estimate,
                        p = temp.mk$p.value)
      return(return.mk)
    })
    
    # Correlation and regression
    gndvi.org.pdat.sm <- cor.test(
      gndvi.org.pdat.ts.stl300$time.series[,'trend'],
      time(gndvi.org.pdat$DATE),
      method="spearman", alternative = "two.sided")
    gndvi.org.pdat.mk <- cor.test(
      gndvi.org.pdat.ts.stl300$time.series[,'trend'],
      time(gndvi.org.pdat$DATE),
      method="kendall", alternative = "two.sided")
    gndvi.org.pdat.lm <- lm(gndvi.org.pdat.ts.stl$time.series[,'trend'] ~ 
                              time(gndvi.org.pdat.ts))
    
    # BFAST
    rdist <- 10/length(gndvi.org.pdat.ts)
    gndvi.org.pdat.ts.bfit <- bfast(gndvi.org.pdat.ts, h=rdist,
                                    season="harmonic", max.iter=1, breaks=5)
    gndvi.org.pdat.ts.bfit.niter <- length(gndvi.org.pdat.ts.bfit$output)
    gndvi.org.pdat.ts.bfit.final <- gndvi.org.pdat.ts.bfit$output[[
      gndvi.org.pdat.ts.bfit.niter]]
    gndvi.org.pdat.ts.bfit.final.breakpoints <- round(as.numeric(
      format(head(gndvi.org.pdat$DATE, 1),format = "%Y")) +
      gndvi.org.pdat.ts.bfit.final$bp.Vt$breakpoints/12, digits=0)
    
    plot(gndvi.org.pdat.ts.stl,
         main = paste("PID: ", gndvi.org[4,i],
                      ", MK: ", round(gndvi.org.pdat.mk$estimate, digits = 3),
                      ", SC:", round(gndvi.org.pdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(gndvi.org.pdat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(gndvi.org.pdat.ts,
         ylim = range(gndvi.org.pdat.ts), 
         xlab = "Date", ylab = "NDVI",
         main = paste("PID: ", colnames(gndvi.org.pdat)[i],
                      ", MK: ", round(gndvi.org.pdat.mk$estimate, digits = 3),
                      ", SC:", round(gndvi.org.pdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(gndvi.org.pdat.ts.bfit.final.breakpoints),
                      sep=""))
    par(new=TRUE)
    plot(gndvi.org.pdat.ts.stl$time.series[,'trend'],
         ylim = range(gndvi.org.pdat.ts), col = "green", lwd = 2,
         xlab = "", ylab = "")
    par(new=TRUE)
    plot(gndvi.org.pdat.ts.stl300$time.series[,'trend'],
         ylim = range(gndvi.org.pdat.ts), col = "blue", lwd = 2,
         xlab = "", ylab = "")
    abline(gndvi.org.pdat.lm, col = "red", lwd = 2)
    legend('top', c("Original NDVI series","1-year running trend", 
                    "11-year running trend", "linear trend"), 
           cex=0.5, col=c("black", "green", "blue", "red"), lty = 1)
    par(new=FALSE)
    
    gndvi.org.pdat.bfast[[j]] <- c(PID = gndvi.org[4,i],
                                   MK = round(gndvi.org.pdat.mk$estimate, 
                                              digits = 3),
                                   SM = round(gndvi.org.pdat.sm$estimate, 
                                              digits = 3),
                                   NIter = gndvi.org.pdat.ts.bfit.niter,
                                   BP = gndvi.org.pdat.ts.bfit.final.breakpoints)
  }
  dev.off()
  gndvi.org.pdat.mk11 <- data.frame(sapply(
    data.frame(t(do.call("cbind", gndvi.org.pdat.mk11))), unlist))
  gndvi.org.pdat.bfast <- data.frame(t(do.call("cbind", gndvi.org.pdat.bfast)))
  write.table(gndvi.org.pdat.mk11,
              file="gndvi.org.pdat.mk11.csv", sep = ",", dec = ".")
  write.table(gndvi.org.pdat.bfast,
              file="gndvi.org.pdat.bfast.csv", sep = ",", dec = ".")  
  write.table(gndvi.org.pdat,
              file="gndvi.org.pdat.csv", sep = ",", dec = ".")  
}



### Cluster Mann-Kendall trends and visualize spatial patterns #################
# Read trends from csv file (generated by previous section) and identify
# identical PIDs. This is necessary because several pixels show exactly the same
# values at Mt. Kilimanjaro. Cluster the individual trends by correlation
# similarity and plot the results in a satellite pixel style plot.
if (compute == FALSE) {
  gndvi.org.pdat.mk11 <- read.table(
    file="gndvi.org.pdat.mk11.csv", sep = ",", dec = ".")
  gndvi.org.pdat.bfast <- read.table(
    file="gndvi.org.pdat.bfast.csv", sep = ",", dec = ".")
}

# Identify pixels with duplicated values
gndvi.org.duplicates = list()
for(i in seq(max(gndvi.org.pdat.mk11$PID))) {
  sub1 <- subset(gndvi.org.pdat.mk11, gndvi.org.pdat.mk11$PID==i)
  sub2 <- subset(gndvi.org.pdat.mk11, gndvi.org.pdat.mk11$PID==i+1)
  if(all(sub1[,3]==sub2[,3]) & i != 169) {
    gndvi.org.duplicates <- c(gndvi.org.duplicates, list(i+1))
  }
}

# Compute fit for time series of each pixel (i.e. PID).
if (compute) {
  gndvi.org.pdat.mk11.fit <- list()
  for(i in seq(length(gndvi.org)-2)) {
    gndvi.org.pdat.mk11.temp <- StructTS(subset(gndvi.org.pdat.mk11$tau,
                                                gndvi.org.pdat.mk11$PID==i))
    gndvi.org.pdat.mk11.fit <- c(gndvi.org.pdat.mk11.fit,
                                 list(data.frame(PID=c(rep(i,length(
                                   gndvi.org.pdat.mk11.temp$fitted)/2)),
                                      FIT=data.frame(
                                            gndvi.org.pdat.mk11.temp$fitted))))
  }
  gndvi.org.pdat.mk11.fit <- data.frame(do.call("rbind",
                                                gndvi.org.pdat.mk11.fit))
  write.table(gndvi.org.pdat.mk11.fit, file="gndvi.org.pdat.mk11.fit.csv",
              sep = ",", dec = ".")
} else {
  gndvi.org.pdat.mk11.fit <- read.table(file="gndvi.org.pdat.mk11.fit.csv",
                                        sep = ",", dec = ".")
}

# Compute ioa for fitted time series PIDs and identify PID-pairs with maximum
# ioa. Cluster time series based on ioa.
if (compute) {
  gndvi.org.pdat.mk11.fit.ioa <- list()
  for(i in seq(length(gndvi.org)-2)) {
    for(j in seq(length(gndvi.org)-2)) {
      if (i != j
          & any(gndvi.org.duplicates==i)==FALSE 
          & any(gndvi.org.duplicates==j)==FALSE) {
        gndvi.org.pdat.mk11.fit.ioa <- c(gndvi.org.pdat.mk11.fit.ioa, 
          list(data.frame(PID=i, vPID=j,IOA=ioa(
            gndvi.org.pdat.mk11.fit$FIT.slope[gndvi.org.pdat.mk11.fit$PID==i],
            gndvi.org.pdat.mk11.fit$FIT.slope[gndvi.org.pdat.mk11.fit$PID==j]))))
      }
    }
  }
  gndvi.org.pdat.mk11.fit.ioa <- data.frame(do.call("rbind",
                                                    gndvi.org.pdat.mk11.fit.ioa))
  
  write.table(gndvi.org.pdat.mk11.fit.ioa, file="gndvi.org.pdat.mk11.fit.ioa.csv",
              sep = ",", dec = ".")
} else {
  gndvi.org.pdat.mk11.fit.ioa <- read.table(
    file="gndvi.org.pdat.mk11.fit.ioa.csv", sep = ",", dec = ".")
}

gndvi.org.pdat.mk11.fit.ioa.max <- list()
for(i in seq(length(gndvi.org)-2)) {
  temp <- subset(gndvi.org.pdat.mk11.fit.ioa,gndvi.org.pdat.mk11.fit.ioa$PID==i)
  gndvi.org.pdat.mk11.fit.ioa.max <- c(gndvi.org.pdat.mk11.fit.ioa.max,
                                       list(temp[which.max(temp$IOA),]))
}
gndvi.org.pdat.mk11.fit.ioa.max <- data.frame(
  do.call("rbind",gndvi.org.pdat.mk11.fit.ioa.max))

gndvi.org.pdat.mk11.fit.ioa.max$Cluster <- kmeans(
  gndvi.org.pdat.mk11.fit.ioa.max$IOA, 5)$cluster


# Compute Spearman correlation of fitted time series PIDs and identify PID-pairs
# with maximum correlation. Cluster time series based on correlation of fit.
if (compute) {
  gndvi.org.pdat.mk11.fit.cor <- list()
  for(i in seq(length(gndvi.org)-2)) {
    for(j in seq(length(gndvi.org)-2)) {
      if (i != j
          & any(gndvi.org.duplicates==i)==FALSE 
          & any(gndvi.org.duplicates==j)==FALSE) {
        gndvi.org.pdat.mk11.fit.cor <- c(gndvi.org.pdat.mk11.fit.cor,
          list(data.frame(PID=i, vPID=j,
                          cor=cor.test(subset(gndvi.org.pdat.mk11.fit$FIT.slope,
                                              gndvi.org.pdat.mk11.fit$PID==i),
                                       subset(gndvi.org.pdat.mk11.fit$FIT.slope,
                                              gndvi.org.pdat.mk11.fit$PID==j),
                                       method="spearman", 
                                       alternative = "two.sided")$estimate)))
      }
    }
  }
  gndvi.org.pdat.mk11.fit.cor <- data.frame(do.call("rbind",
                                                    gndvi.org.pdat.mk11.fit.cor))
  write.table(gndvi.org.pdat.mk11.fit.cor, file="gndvi.org.pdat.mk11.fit.cor.csv",
              sep = ",", dec = ".")
} else {
  gndvi.org.pdat.mk11.fit.cor <- read.table(file="gndvi.org.pdat.mk11.fit.cor.csv",
                                            sep = ",", dec = ".")
}
  
gndvi.org.pdat.mk11.fit.cor.max <- list()
for(i in seq(length(gndvi.org)-2)) {
  temp <- subset(gndvi.org.pdat.mk11.fit.cor,gndvi.org.pdat.mk11.fit.cor$PID==i)
  gndvi.org.pdat.mk11.fit.cor.max <- c(gndvi.org.pdat.mk11.fit.cor.max,
                                       list(temp[which.max(temp$cor),]))
}
gndvi.org.pdat.mk11.fit.cor.max <- data.frame(
  do.call("rbind",gndvi.org.pdat.mk11.fit.cor.max))

gndvi.org.pdat.mk11.fit.cor.max$Cluster <- kmeans(
  gndvi.org.pdat.mk11.fit.cor.max$cor, 5)$cluster

# Compute Spearman correlation of Mann-Kendall trend series and identify 
# PID-pairs with maximum correlation. Cluster time series based on correlation.
if (compute) {
  gndvi.org.pdat.mk11.cor <- list()
  for(i in seq(length(gndvi.org)-2)) {
    for(j in seq(length(gndvi.org)-2)) {
      if (i != j
          & any(gndvi.org.duplicates==i)==FALSE 
          & any(gndvi.org.duplicates==j)==FALSE) {
        gndvi.org.pdat.mk11.cor <- c(gndvi.org.pdat.mk11.cor,
          list(data.frame(PID=i, vPID=j,
                          cor=cor.test(subset(gndvi.org.pdat.mk11$tau,
                                              gndvi.org.pdat.mk11$PID==i),
                                       subset(gndvi.org.pdat.mk11$tau,
                                              gndvi.org.pdat.mk11$PID==j),
                                       method="spearman", 
                                       alternative = "two.sided")$estimate)))
      }
    }
  }
  gndvi.org.pdat.mk11.cor <- data.frame(do.call("rbind",gndvi.org.pdat.mk11.cor))
  write.table(gndvi.org.pdat.mk11.cor, file="gndvi.org.pdat.mk11.cor.csv",
              sep = ",", dec = ".")
} else {
  gndvi.org.pdat.mk11.cor <- read.table(file="gndvi.org.pdat.mk11.cor.csv",
                                        sep = ",", dec = ".")
}

gndvi.org.pdat.mk11.cor.max <- list()
for(i in seq(length(gndvi.org)-2)) {
  temp <- subset(gndvi.org.pdat.mk11.cor,gndvi.org.pdat.mk11.cor$PID==i)
  gndvi.org.pdat.mk11.cor.max <- c(gndvi.org.pdat.mk11.cor.max,
                                   list(temp[which.max(temp$cor),]))
}
gndvi.org.pdat.mk11.cor.max <- data.frame(
  do.call("rbind",gndvi.org.pdat.mk11.cor.max))

gndvi.org.pdat.mk11.cor.max$Cluster <- kmeans(
  gndvi.org.pdat.mk11.cor.max$cor, 5)$cluster

# Compute DTW of Mann-Kendall trend series and identify PID-pairs with minimum
# distance. Cluster time series based on correlation.
if (compute) {
  gndvi.org.pdat.mk11.dtw <- list()
  for(i in seq(length(gndvi.org)-2)) {
    for(j in seq(length(gndvi.org)-2)) {
      if (i != j
          & any(gndvi.org.duplicates==i)==FALSE 
          & any(gndvi.org.duplicates==j)==FALSE) {
        gndvi.org.pdat.mk11.dtw <- c(gndvi.org.pdat.mk11.dtw,
          list(data.frame(PID=i, vPID=j,
                          dtw=dtw(subset(gndvi.org.pdat.mk11$tau,
                                         gndvi.org.pdat.mk11$PID==i),
                                  subset(gndvi.org.pdat.mk11$tau,
                                         gndvi.org.pdat.mk11$PID==j),
                                  keep=TRUE)$distance)))
      }
    }
  }
  gndvi.org.pdat.mk11.dtw <- data.frame(do.call("rbind",gndvi.org.pdat.mk11.dtw))
  write.table(gndvi.org.pdat.mk11.dtw, file="gndvi.org.pdat.mk11.dtw.csv",
              sep = ",", dec = ".")
} else {
  gndvi.org.pdat.mk11.dtw <- read.table(file="gndvi.org.pdat.mk11.dtw.csv",
                                        sep = ",", dec = ".")
}

gndvi.org.pdat.mk11.dtw.max <- list()
for(i in seq(length(gndvi.org)-2)) {
  temp <- subset(gndvi.org.pdat.mk11.dtw,gndvi.org.pdat.mk11.dtw$PID==i)
  gndvi.org.pdat.mk11.dtw.max <- c(gndvi.org.pdat.mk11.dtw.max,
                                     list(temp[which.max(temp$dtw),]))
}
gndvi.org.pdat.mk11.dtw.max <- data.frame(
  do.call("rbind",gndvi.org.pdat.mk11.dtw.max))

gndvi.org.pdat.mk11.dtw.max$Cluster <- kmeans(
  gndvi.org.pdat.mk11.dtw.max$dtw, 12)$cluster

# gndvi.org.pdat.mk11.dtw.max$Cluster <- cutree(
#   hclust(dist(gndvi.org.pdat.mk11.dtw.max$dtw)),5)

# Compute DTW of original time series and identify PID-pairs with minimum
# distance. Cluster time series based on correlation.
if (compute) {
  gndvi.org.pdat.dtw <- list()
  for(i in seq(length(gndvi.org)-2)) {
    for(j in seq(length(gndvi.org)-2)) {
      if (i != j
          & any(gndvi.org.duplicates==i)==FALSE 
          & any(gndvi.org.duplicates==j)==FALSE) {
        gndvi.org.pdat.dtw <- c(gndvi.org.pdat.dtw,
                                list(data.frame(PID=i, vPID=j,
                                         dtw=dtw(gndvi.org.pdat[,i+2],
                                                 gndvi.org.pdat[,j+2],
                                                 keep=TRUE)$distance)))
      }
    }
  }
  gndvi.org.pdat.dtw <- data.frame(do.call("rbind",gndvi.org.pdat.dtw))
  write.table(gndvi.org.pdat.dtw, file="gndvi.org.pdat.dtw.csv",
              sep = ",", dec = ".")
} else {
  gndvi.org.pdat.dtw <- read.table(file="gndvi.org.pdat.dtw.csv",
                                   sep = ",", dec = ".")
}

gndvi.org.pdat.dtw.max <- list()
for(i in seq(length(gndvi.org)-2)) {
  temp <- subset(gndvi.org.pdat.dtw, gndvi.org.pdat.dtw$PID==i)
  gndvi.org.pdat.dtw.max <- c(gndvi.org.pdat.dtw.max,
                              list(temp[which.max(temp$dtw),]))
}
gndvi.org.pdat.dtw.max <- data.frame(
  do.call("rbind",gndvi.org.pdat.dtw.max))

gndvi.org.pdat.dtw.max$Cluster <- kmeans(
  gndvi.org.pdat.dtw.max$dtw, 12)$cluster

# gndvi.org.pdat.dtw.max$Cluster <- cutree(
#    hclust(dist(gndvi.org.pdat.dtw.max$dtw)),5)

#> sc <- read.table("E:/Rtmp/synthetic_control.data", header=F, sep="")
# randomly sampled n cases from each class, to make it easy for plotting
# > n <- 10
#                    > s <- sample(1:100, n)
#                    > idx <- c(s, 100+s, 200+s, 300+s, 400+s, 500+s)
#                    > sample2 <- sc[idx,]
#                    > observedLabels <- c(rep(1,n), rep(2,n), rep(3,n), rep(4,n), rep(5,n), rep(6,n))
#                    # compute DTW distances
#                    > library(dtw)
#                    > distMatrix <- dist(sample2, method="DTW")
#                    # hierarchical clustering
#                    > hc <- hclust(distMatrix, method="average")
#                    > plot(hc, labels=observedLabels, main="")

# Plot Mann-Kendall trends for each datasets. 
geometry.x <- 13
geometry.y <- 13
clusters <- list(gndvi.org.pdat.dtw.max,
              gndvi.org.pdat.mk11.dtw.max,
              gndvi.org.pdat.mk11.fit.ioa.max,
              gndvi.org.pdat.mk11.fit.cor.max,
              gndvi.org.pdat.mk11.cor.max)
clusters.names <- c("NDVI Dynamics 1982-2006 (DTW Clustering)",
                    "NDVI Dynamics 1982-2006 (MK/DTW Clustering)",
                    "NDVI Dynamics 1982-2006 (MK-fit/IOA Clustering)",
                    "NDVI Dynamics 1982-2006 (MK-fit/COR Clustering)",
                    "NDVI Dynamics 1982-2006 (MK/COR Clustering)")
pdf("gndvi.org.pdat.mk11.plots.pdf")
for (cid in seq(length(clusters))) {
  print(cid)
  cluster <- as.data.frame(clusters[cid])
  color.cluster <- cluster$Cluster
  p.thv <- 0.05
  for (i in gndvi.org.duplicates) { 
    color.cluster <- append(color.cluster, color.cluster[[i-1]], after=i-1)
  }
  plot.background.color <- data.frame(color=c(
    topo.colors((max(color.cluster)+1))))
  gndvi.org.pdat.mk11.plots <- lapply(seq(length(gndvi.org)-2), function(i){
    gndvi.org.pdat.mk11.subset <- subset(gndvi.org.pdat.mk11,
                                         gndvi.org.pdat.mk11$PID == i)
    gndvi.org.pdat.mk11.p.subset <- subset(gndvi.org.pdat.mk11.subset,
                                           gndvi.org.pdat.mk11.subset$p > p.thv)
    gndvi.org.pdat.mk11.ps.subset <- subset(gndvi.org.pdat.mk11.subset,
                                            gndvi.org.pdat.mk11.subset$p <= p.thv)
    gndvi.org.pdat.bfast.subset <- subset(gndvi.org.pdat.bfast,
                                          gndvi.org.pdat.bfast$PID == i)
    plot.color <- plot.background.color$color[color.cluster[i]]
    plot <- xyplot(gndvi.org.pdat.mk11.subset$tau ~
                     gndvi.org.pdat.mk11.subset$DATE,
                   col = 'red', type = 'l', xlab=FALSE, ylab=FALSE, main=i,
                   ylim = range(-0.5, 0.5),
                   panel = function(...) {
                     panel.fill(col = toString(plot.color))
                     panel.abline(h = 0, col = 'grey')
                     panel.abline(v = c(gndvi.org.pdat.bfast.subset
                                        [5:length(gndvi.org.pdat.bfast.subset)]),
                                  col = 'blue', lty = "dotted")
                     panel.points(gndvi.org.pdat.mk11.p.subset$DATE, 
                                  gndvi.org.pdat.mk11.p.subset$tau, 
                                  pch = 16, cex = 0.25, col = "red")
                     panel.points(gndvi.org.pdat.mk11.ps.subset$DATE, 
                                  gndvi.org.pdat.mk11.ps.subset$tau, 
                                  pch = 16, cex = 0.5, col = "black")
                     panel.xyplot(...)})
    return(plot)
  })
  out <- gndvi.org.pdat.mk11.plots[[1]]
  for (i in 2:length(gndvi.org.pdat.mk11.plots)) {
    out <- c(out, gndvi.org.pdat.mk11.plots[[i]], x.same=TRUE, y.same=TRUE,
             layout = c(geometry.x, geometry.y))
  }
  out <- update(out, as.table = TRUE, xlab=NULL, ylab=NULL, 
                main=clusters.names[cid])
  plot(out)
}
dev.off()



### Height-based analysis ######################################################
### Time-series decomposition and Mann-Kendall trend ###########################
# Decompose time series, identify breacks and compute 11-year running
# Mann-Kendall trend. Plot time series graphs for each Pixel to a pdf file.
# Store the resulting datasets as csv file for further analysis so this
# procedure can be scipped next time.
gndvi.org.hdat <- c(list(data.frame(
                      as.Date(subset(gndvi.org$DATE, gndvi.org$DATE > 1900)))),
                    list(data.frame(
                      subset(gndvi.org$META, gndvi.org$DATE > 1900))))
col = list()
for(i in seq(500, 4500, by=1000)) {
  col <- list(col, paste("H", toString(i), sep = ""))
  gndvi.org.hdat <- c(gndvi.org.hdat,
                      list(data.frame(col = rowMeans(
                        subset(subset(gndvi.org, 
                          select = c(which(gndvi.org[3,3:length(gndvi.org)]
                                           > i &
                                           gndvi.org[3,3:length(gndvi.org)]
                                           <= i+1000)+2)), 
                          gndvi.org$DATE > 1900)))))
}
gndvi.org.hdat <- data.frame(do.call("cbind", gndvi.org.hdat))
colnames(gndvi.org.hdat) <- c("DATE", "META", unlist(col))
if (compute) {
  pdf("gndvi_org_hdat.pdf")
  gndvi.org.hdat.mk11 <- list()
  gndvi.org.hdat.bfast <- list()
  for (j in 1:(length(gndvi.org.hdat)-2)) {
    i <- j+2
    gndvi.org.hdat.ts <- ts(gndvi.org.hdat[, i], 
                            start=as.numeric(format(head(gndvi.org.hdat$DATE,
                                                         1),format = "%Y")), 
                            freq=12)
    
    # STL
    gndvi.org.hdat.ts.stl <- stl((gndvi.org.hdat.ts),
                                 s.window="periodic", t.window=12)
    
    gndvi.org.hdat.ts.stl300 <- stl((gndvi.org.hdat.ts),
                                    s.window="periodic", t.window=300)
    
    # 11-year running Mann-Kendall trend
    gndvi.org.hdat.mk11[[j]] <- sapply(seq(15), function(k) {
      date.start <- 1981 + k
      date.end <- date.start + 11
      gndvi.org.hdat.ts.stl.trend <- gndvi.org.hdat.ts.stl$time.series[,'trend']
      gndvi.org.hdat.ts.stl.trend.sub <- gndvi.org.hdat.ts.stl.trend[
        time(gndvi.org.hdat.ts.stl.trend)>= date.start &
          time(gndvi.org.hdat.ts.stl.trend)< date.end]
      temp.mk <- cor.test(gndvi.org.hdat.ts.stl.trend.sub,
                          time(seq(from=date.start, to=date.end-1/12, by=1/12)),
                          method="kendall", alternative = "two.sided")
      return.mk <- list(HEIGHT = j,
                        DATEMEAN = date.start + (date.end-date.start-1)/2,
                        tau = temp.mk$estimate,
                        p = temp.mk$p.value)
      return(return.mk)
    })
    
    # Correlation and regression
    gndvi.org.hdat.sm <- cor.test(
      gndvi.org.hdat.ts.stl300$time.series[,'trend'],
      time(gndvi.org.hdat$DATE),
      method="spearman", alternative = "two.sided")
    gndvi.org.hdat.mk <- cor.test(
      gndvi.org.hdat.ts.stl300$time.series[,'trend'],
      time(gndvi.org.hdat$DATE),
      method="kendall", alternative = "two.sided")
    gndvi.org.hdat.lm <- lm(gndvi.org.hdat.ts.stl$time.series[,'trend'] ~
                              time(gndvi.org.hdat.ts))
    

    # BFAST
    rdist <- 10/length(gndvi.org.hdat.ts)
    gndvi.org.hdat.ts.bfit <- bfast(gndvi.org.hdat.ts, h=rdist,
                                    season="harmonic", max.iter=1, breaks=5)
    gndvi.org.hdat.ts.bfit.niter <- length(gndvi.org.hdat.ts.bfit$output)
    gndvi.org.hdat.ts.bfit.final <- gndvi.org.hdat.ts.bfit$output[[
      gndvi.org.hdat.ts.bfit.niter]]
    gndvi.org.hdat.ts.bfit.final.breakpoints <- round(as.numeric(
      format(head(gndvi.org.hdat$DATE, 1),format = "%Y")) +
                  gndvi.org.hdat.ts.bfit.final$bp.Vt$breakpoints/12, digits=0)
    
    plot(gndvi.org.hdat.ts.stl,
         main = paste("HEIGHT: ", colnames(gndvi.org.hdat)[i],
                      ", MK: ", round(gndvi.org.hdat.mk$estimate, digits = 3),
                      ", SC:", round(gndvi.org.hdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(gndvi.org.hdat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(gndvi.org.hdat.ts.stl300,
         main = paste("HEIGHT: ", colnames(gndvi.org.hdat)[i],
                      ", MK: ", round(gndvi.org.hdat.mk$estimate, digits = 3),
                      ", SC:", round(gndvi.org.hdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(gndvi.org.hdat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(gndvi.org.hdat.ts,
         ylim = range(gndvi.org.hdat.ts), 
         xlab = "Date", ylab = "NDVI",
         main = paste("HEIGHT: ", colnames(gndvi.org.hdat)[i],
                      ", MK: ", round(gndvi.org.hdat.mk$estimate, digits = 3),
                      ", SC:", round(gndvi.org.hdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(gndvi.org.hdat.ts.bfit.final.breakpoints),
                      sep=""))
    par(new=TRUE)
    plot(gndvi.org.hdat.ts.stl$time.series[,'trend'],
         ylim = range(gndvi.org.hdat.ts), col = "green", lwd = 2,
         xlab = "", ylab = "")
    par(new=TRUE)
    plot(gndvi.org.hdat.ts.stl300$time.series[,'trend'],
         ylim = range(gndvi.org.hdat.ts), col = "blue", lwd = 2,
         xlab = "", ylab = "")
    abline(gndvi.org.hdat.lm, col = "red", lwd = 2)
    legend('top', c("Original NDVI series","1-year running trend", 
                    "11-year running trend", "linear trend"), 
           cex=0.5, col=c("black", "green", "blue", "red"), lty = 1)
    par(new=FALSE)
    
    gndvi.org.hdat.bfast[[j]] <- c(HEIGHT = gndvi.org[4,i],
                                   MK = round(gndvi.org.hdat.mk$estimate, 
                                              digits = 3),
                                   SM = round(gndvi.org.hdat.sm$estimate, 
                                              digits = 3),
                                   NIter = gndvi.org.hdat.ts.bfit.niter,
                                   BP = gndvi.org.hdat.ts.bfit.final.breakpoints)
  }
  dev.off()
  gndvi.org.hdat.mk11 <- data.frame(sapply(
    data.frame(t(do.call("cbind", gndvi.org.hdat.mk11))), unlist))
  gndvi.org.hdat.bfast <- data.frame(t(do.call("cbind", gndvi.org.hdat.bfast)))
  write.table(gndvi.org.hdat.mk11, 
              file="gndvi.org.hdat.mk11.csv", sep = ",", dec = ".")
  write.table(gndvi.org.hdat.bfast,
              file="gndvi.org.hdat.bfast.csv", sep = ",", dec = ".")
}

# Plot Mann-Kendall trends for each datasets. 
if (compute == FALSE) {
  gndvi.org.hdat.mk11 <- read.table(
    file="gndvi.org.hdat.mk11.csv", sep = ",", dec = ".")
  gndvi.org.hdat.bfast <- read.table(
    file="gndvi.org.hdat.bfast.csv", sep = ",", dec = ".")
}

p.thv <- 0.05
colors <- c("darkgoldenrod2", "darkolivegreen", "darkolivegreen3",
             "chartreuse2", "cadetblue4")
out <- xyplot(gndvi.org.hdat.mk11$tau ~ gndvi.org.hdat.mk11$DATEMEAN, 
       groups=gndvi.org.hdat.mk11$HEIGHT,
       col = colors, type = 'spline', lwd = 2, 
       xlab="Date", ylab="Mann Kendall's tau", 
       main="Mann-Kendall's tau for height levels", 
       auto.key=list(text = c("  500 to 1500 m", "1500 to 2500 m", 
                              "2500 to 3500 m", "3500 to 4500 m", 
                              "4500 to 5500 m"),
                     col = colors, 
                     points = FALSE, lines = FALSE, 
                     x = 0.1, y=0.1, corner=c(0,0)),
       ylim = range(-0.5, 0.5),
       panel = function(...) {
         panel.abline(h = 0, col = 'grey')
         for (i in seq(1,5)){
           panel.points(subset(gndvi.org.hdat.mk11, 
                               gndvi.org.hdat.mk11$HEIGHT==i)$DATEMEAN[
                                 gndvi.org.hdat.mk11$p<=p.thv], 
                        subset(gndvi.org.hdat.mk11, 
                               gndvi.org.hdat.mk11$HEIGHT==i)$tau[
                                 gndvi.org.hdat.mk11$p<=p.thv],
                        pch = 8, cex = 1.5, col = colors[i])
           panel.points(subset(gndvi.org.hdat.mk11, 
                               gndvi.org.hdat.mk11$HEIGHT==i)$DATEMEAN[
                                 gndvi.org.hdat.mk11$p>p.thv], 
                        subset(gndvi.org.hdat.mk11, 
                               gndvi.org.hdat.mk11$HEIGHT==i)$tau[
                                 gndvi.org.hdat.mk11$p>p.thv],
                        pch = 4, cex = 1.5, col = colors[i])
         }
         panel.xyplot(...)})
pdf("gndvi.org.hdat.mk11.pdf")
plot(out)
dev.off()



# MODIS dynamics between 2000 and 2011
# To analyse vegetation dynamics between 2000 and 2011, the MODIS-based
# MOD13/MYD13 dataset is used. The original product values have been extracted
# for the same area as the GIMMS dataset above using SAGA GIS. In addition,
# MODIS-NDVI time seires for each research plot have been extracted.
# Read original MOD13/MYD13 values for 2000 to 2011.
if (actsys == "Windows") {
  wd <- path.gis.win
  setwd(wd)
} else {
  wd <- path.gis.lin
  setwd(wd)
}

mndvi.org <- read.csv("02_kilimanjaro_plots_2013-01-11_modis.csv",
                      header=TRUE, sep = ",")
mndvi.org$DATE <- as.Date(strptime(paste(mndvi.org$DATE), "%Y-%m-%d"))



train.dm <- read.csv("03_trmm_bilinear_dmonthly.csv", 
                     header=TRUE, sep = ";", dec=",")
train.dm$DATE <- as.Date(strptime(paste(train.dm$DATE), 
                                   "%Y-%m-%d"))

### Height-based analysis ######################################################
### Time-series decomposition and Mann-Kendall trend ###########################
# Decompose time series, identify breacks and compute Mann-Kendall trend.
# Plot time series graphs for each height-level to a pdf file.
# Store the resulting datasets as csv file for further analysis so this
# procedure can be scipped next time.
mndvi.org.hdat <- c(list(data.frame(
  as.Date(subset(mndvi.org$DATE, mndvi.org$DATE >= as.Date(strptime(
    paste("2001-01-01"), "%Y-%m-%d")))))),
                    list(data.frame(
                      subset(mndvi.org$META, mndvi.org$DATE >= as.Date(strptime(
                        paste("2001-01-01"), "%Y-%m-%d"))))))
col = list()
for(i in seq(500, 4500, by=1000)) {
  col <- list(col, paste("H", toString(i), sep = ""))
  mndvi.org.hdat <- c(mndvi.org.hdat,
                      list(data.frame(col = rowMeans(
                        subset(subset(mndvi.org, 
                          select = c(which(as.numeric(
                            mndvi.org[3,3:length(mndvi.org)])> i &
                                           as.numeric(
                            mndvi.org[3,3:length(mndvi.org)])<= i+1000)+2)), 
                        mndvi.org$DATE >= as.Date(strptime(paste(
                          "2001-01-01"), "%Y-%m-%d")))))))
}
mndvi.org.hdat <- data.frame(do.call("cbind", mndvi.org.hdat))
colnames(mndvi.org.hdat) <- c("DATE", "META", unlist(col))


train.dm.hdat <- c(list(data.frame(
  as.Date(subset(train.dm$DATE, train.dm$DATE >= as.Date(strptime(
    paste("2001-01-01"), "%Y-%m-%d")))))),
                    list(data.frame(
                      subset(train.dm$META, train.dm$DATE >= as.Date(strptime(
                        paste("2001-01-01"), "%Y-%m-%d"))))))

col = list()
for(i in seq(500, 4500, by=1000)) {
  col <- list(col, paste("H", toString(i), sep = ""))
  train.dm.hdat <- c(train.dm.hdat,
                          list(data.frame(col = rowMeans(
                            subset(subset(train.dm, 
                                    select = c(which(as.numeric(
                                    train.dm[3,3:length(train.dm)])> i &
                                    as.numeric(train.dm[
                                      3,3:length(train.dm)])<= i+1000)+2)), 
                                   train.dm$DATE >= as.Date(strptime(paste(
                                     "2001-01-01"), "%Y-%m-%d")))))))
}
train.dm.hdat <- data.frame(do.call("cbind", train.dm.hdat))
colnames(train.dm.hdat) <- c("DATE", "META", unlist(col))
write.table(train.dm.hdat[,c(1,3:length(train.dm.hdat))],
            file="train.dm.tdat.hdat.csv", sep = ",", dec = ".")

if (compute) {
  pdf("mndvi_org_hdat.pdf")
  mndvi.org.hdat.mk11 <- list()
  mndvi.org.hdat.bfast <- list()
  for (j in 1:(length(mndvi.org.hdat)-2)) {
    i <- j+2
    mndvi.org.hdat.ts <- ts(mndvi.org.hdat[, i], 
                            start=as.numeric(format(head(mndvi.org.hdat$DATE,
                                                         1),format = "%Y")), 
                            freq=46)
    train.dm.hdat.ts <- ts(train.dm.hdat[, i], 
                           start=as.numeric(format(head(train.dm.hdat$DATE,1),
                                                   format = "%Y")), freq=12)
    
    # STL
    mndvi.org.hdat.ts.stl <- stl((mndvi.org.hdat.ts),
                                 s.window="periodic", t.window=46)
    
    mndvi.org.hdat.ts.stl300 <- stl((mndvi.org.hdat.ts),
                                    s.window="periodic", t.window=414)
    
    train.dm.hdat.ts.stl <- stl((train.dm.hdat.ts),
                                s.window="periodic", t.window=24)
    
    # 11-year running Mann-Kendall trend
    mndvi.org.hdat.mk11[[j]] <- sapply(seq(1), function(k) {
      date.start <- 2000 + k
      date.end <- date.start + 11
      mndvi.org.hdat.ts.stl.trend <- mndvi.org.hdat.ts.stl$time.series[,'trend']
      mndvi.org.hdat.ts.stl.trend.sub <- mndvi.org.hdat.ts.stl.trend[
        time(mndvi.org.hdat.ts.stl.trend)>= date.start &
          time(mndvi.org.hdat.ts.stl.trend)< date.end]
      temp.mk <- cor.test(mndvi.org.hdat.ts.stl.trend.sub,
                          time(seq(from=date.start, to=date.end-1/46, by=1/46)),
                          method="kendall", alternative = "two.sided")
      return.mk <- list(HEIGHT = j,
                        DATEMEAN = date.start + (date.end-date.start-1)/2,
                        tau = temp.mk$estimate,
                        p = temp.mk$p.value)
      return(return.mk)
    })
    
    # Correlation and regression
    mndvi.org.hdat.sm <- cor.test(
      mndvi.org.hdat.ts.stl300$time.series[,'trend'],
      time(mndvi.org.hdat$DATE),
      method="spearman", alternative = "two.sided")
    mndvi.org.hdat.mk <- cor.test(
      mndvi.org.hdat.ts.stl300$time.series[,'trend'],
      time(mndvi.org.hdat$DATE),
      method="kendall", alternative = "two.sided")
    mndvi.org.hdat.lm <- lm(mndvi.org.hdat.ts.stl$time.series[,'trend'] ~
                              time(mndvi.org.hdat.ts))
    
    
    # BFAST
    rdist <- 10/length(mndvi.org.hdat.ts)
    mndvi.org.hdat.ts.bfit <- bfast(mndvi.org.hdat.ts, h=rdist,
                                    season="harmonic", max.iter=1, breaks=5)
    mndvi.org.hdat.ts.bfit.niter <- length(mndvi.org.hdat.ts.bfit$output)
    mndvi.org.hdat.ts.bfit.final <- mndvi.org.hdat.ts.bfit$output[[
      mndvi.org.hdat.ts.bfit.niter]]
    mndvi.org.hdat.ts.bfit.final.breakpoints <- round(as.numeric(
      format(head(mndvi.org.hdat$DATE, 1),format = "%Y")) +
                    mndvi.org.hdat.ts.bfit.final$bp.Vt$breakpoints/46, digits=0)
    
    plot(mndvi.org.hdat.ts.stl,
         main = paste("HEIGHT: ", colnames(mndvi.org.hdat)[i],
                      ", MK: ", round(mndvi.org.hdat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.hdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.hdat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(mndvi.org.hdat.ts.stl300,
         main = paste("HEIGHT: ", colnames(mndvi.org.hdat)[i],
                      ", MK: ", round(mndvi.org.hdat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.hdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.hdat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(mndvi.org.hdat.ts,
         ylim = range(mndvi.org.hdat.ts), 
         xlab = "Date", ylab = "NDVI",
         main = paste("HEIGHT: ", colnames(mndvi.org.hdat)[i],
                      ", MK: ", round(mndvi.org.hdat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.hdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.hdat.ts.bfit.final.breakpoints),
                      sep=""))
    par(new=TRUE)
    plot(mndvi.org.hdat.ts.stl$time.series[,'trend'],
         ylim = range(mndvi.org.hdat.ts), col = "green", lwd = 2,
         xlab = "", ylab = "")
    par(new=TRUE)
    plot(mndvi.org.hdat.ts.stl300$time.series[,'trend'],
         ylim = range(mndvi.org.hdat.ts), col = "blue", lwd = 2,
         xlab = "", ylab = "")
    par(new=TRUE)
    plot(train.dm.hdat.ts.stl$time.series[,'trend'] / 
           max(abs(train.dm.hdat.ts.stl$time.series[,'trend'])) / 10.0 + 
           mean(mndvi.org.hdat.ts.stl$time.series[,'trend']),
         ylim = range(mndvi.org.hdat.ts), xlim = range(time(mndvi.org.hdat.ts)),
         col = "orange", lwd = 2,
         xlab = "", ylab = "")
    abline(mndvi.org.hdat.lm, col = "red", lwd = 2)
    legend('top', c("Original NDVI series","1-year running trend", 
                    "11-year running trend", "linear trend", "Relative rainfall"), 
           cex=0.5, col=c("black", "green", "blue", "red", "orange"), lty = 1)
    par(new=FALSE)
    
    mndvi.org.hdat.bfast[[j]] <- c(HEIGHT = mndvi.org[4,i],
                                   MK = round(mndvi.org.hdat.mk$estimate, 
                                              digits = 3),
                                   SM = round(mndvi.org.hdat.sm$estimate, 
                                              digits = 3),
                                   NIter = mndvi.org.hdat.ts.bfit.niter,
                                   BP = mndvi.org.hdat.ts.bfit.final.breakpoints)
  }
  dev.off()
  mndvi.org.hdat.mk11 <- data.frame(sapply(
    data.frame(t(do.call("cbind", mndvi.org.hdat.mk11))), unlist))
  mndvi.org.hdat.bfast <- data.frame(t(do.call("cbind", mndvi.org.hdat.bfast)))
  write.table(mndvi.org.hdat.mk11, 
              file="mndvi.org.hdat.mk11.csv", sep = ",", dec = ".")
  write.table(mndvi.org.hdat.bfast,
              file="mndvi.org.hdat.bfast.csv", sep = ",", dec = ".")
  write.table(mndvi.org.hdat[,c(1,3:length(mndvi.org.hdat))],
              file="mndvi.org.hdat.csv", sep = ",", dec = ".")
}

# Plot Mann-Kendall trends for each datasets. 
if (compute == FALSE) {
  mndvi.org.hdat.mk11 <- read.table(
    file="mndvi.org.hdat.mk11.csv", sep = ",", dec = ".")
  mndvi.org.hdat.bfast <- read.table(
    file="mndvi.org.hdat.bfast.csv", sep = ",", dec = ".")
}






### Plot-group-based analysis ##################################################
### Time-series decomposition and Mann-Kendall trend ###########################
# Decompose time series, identify breacks and compute Mann-Kendall trend.
# Plot time series graphs for each plot to a pdf file.
# Store the resulting datasets as csv file for further analysis so this
# procedure can be scipped next time.
mndvi.org.ldat <- c(list(data.frame(
  as.Date(subset(mndvi.org$DATE, mndvi.org$DATE >= 
                   as.Date(strptime(paste("2001-01-01"), "%Y-%m-%d")))))),
                    list(data.frame(
                      subset(mndvi.org$META, mndvi.org$DATE >= 
                               as.Date(strptime(paste("2001-01-01"), "%Y-%m-%d"))))))

columns <- colnames(mndvi.org[3:length(mndvi.org)])
col <- unique(substr(colnames(mndvi.org[3:length(mndvi.org)]), start=1, stop=3))
#col <- col[!col=="sun"]
for(i in 1:length(col)) {
  mndvi.org.ldat <- c(mndvi.org.ldat,
                      list(data.frame(col = rowMeans(
                        subset(subset(mndvi.org, 
                                      select = c(
                                        which(substr(columns, start=1, stop=3) 
                                              == col[[i]])+2)), 
                               mndvi.org$DATE >= as.Date(strptime(paste(
                                 "2001-01-01"), "%Y-%m-%d")))))))
}
mndvi.org.ldat <- data.frame(do.call("cbind", mndvi.org.ldat))
colnames(mndvi.org.ldat) <- c("DATE", "META", col)
write.table(mndvi.org.ldat[,c(1,3:length(mndvi.org.ldat))],
            file="mndvi.org.ldat.csv", sep = ",", dec = ".")


columns <- colnames(train.dm[3:length(train.dm)])
train.dm.ldat <- c(list(data.frame(
  as.Date(subset(train.dm$DATE, train.dm$DATE >= as.Date(strptime(
    paste("2001-01-01"), "%Y-%m-%d")))))),
                   list(data.frame(
                     subset(train.dm$META, train.dm$DATE >= as.Date(strptime(
                       paste("2001-01-01"), "%Y-%m-%d"))))))
for(i in 1:length(col)) {
  train.dm.ldat <- c(train.dm.ldat,
                      list(data.frame(col = rowMeans(
                        subset(subset(train.dm, 
                                      select = c(
                                        which(substr(columns, start=1, stop=3) 
                                              == col[[i]])+2)), 
                               train.dm$DATE >= as.Date(strptime(paste(
                                 "2001-01-01"), "%Y-%m-%d")))))))
}
train.dm.ldat <- data.frame(do.call("cbind", train.dm.ldat))
colnames(train.dm.ldat) <- c("DATE", "META", unlist(col))
write.table(train.dm.ldat[,c(1,3:length(mndvi.org.ldat))],
            file="train.dm.ldat.csv", sep = ",", dec = ".")

if (compute) {
  pdf("mndvi_org_ldat.pdf")
  mndvi.org.ldat.mk11 <- list()
  mndvi.org.ldat.bfast <- list()
  for (j in 1:(length(mndvi.org.ldat)-2)) {
    i <- j+2
    mndvi.org.ldat.ts <- ts(mndvi.org.ldat[, i], 
                            start=as.numeric(format(head(mndvi.org.ldat$DATE,
                                                         1),format = "%Y")), 
                            freq=46)
    
    
    train.dm.ldat.ts <- ts(train.dm.ldat[, i], 
                           start=as.numeric(format(head(train.dm.ldat$DATE,1),
                                                   format = "%Y")), freq=12)

    # STL
    mndvi.org.ldat.ts.stl <- stl((mndvi.org.ldat.ts),
                                 s.window="periodic", t.window=46)
    
    mndvi.org.ldat.ts.stl300 <- stl((mndvi.org.ldat.ts),
                                    s.window="periodic", t.window=414)
    train.dm.ldat.ts.stl <- stl((train.dm.ldat.ts),
                                s.window="periodic", t.window=24)
    
    # 11-year running Mann-Kendall trend
    mndvi.org.ldat.mk11[[j]] <- sapply(seq(1), function(k) {
      date.start <- 2000 + k
      date.end <- date.start + 11
      mndvi.org.ldat.ts.stl.trend <- mndvi.org.ldat.ts.stl$time.series[,'trend']
      mndvi.org.ldat.ts.stl.trend.sub <- mndvi.org.ldat.ts.stl.trend[
        time(mndvi.org.ldat.ts.stl.trend)>= date.start &
          time(mndvi.org.ldat.ts.stl.trend)< date.end]
      temp.mk <- cor.test(mndvi.org.ldat.ts.stl.trend.sub,
                          time(seq(from=date.start, to=date.end-1/46, by=1/46)),
                          method="kendall", alternative = "two.sided")
      return.mk <- list(HEIGHT = j,
                        DATEMEAN = date.start + (date.end-date.start-1)/2,
                        tau = temp.mk$estimate,
                        p = temp.mk$p.value)
      return(return.mk)
    })
    
    # Correlation and regression
    mndvi.org.ldat.sm <- cor.test(
      mndvi.org.ldat.ts.stl$time.series[,'trend'],
      time(mndvi.org.ldat$DATE),
      method="spearman", alternative = "two.sided")
    mndvi.org.ldat.mk <- cor.test(
      mndvi.org.ldat.ts.stl$time.series[,'trend'],
      time(mndvi.org.ldat$DATE),
      method="kendall", alternative = "two.sided")
    mndvi.org.ldat.lm <- lm(mndvi.org.ldat.ts.stl$time.series[,'trend'] ~
                              time(mndvi.org.ldat.ts))
    
    # BFAST
    rdist <- 10/length(mndvi.org.ldat.ts)
    mndvi.org.ldat.ts.bfit <- bfast(mndvi.org.ldat.ts, h=rdist,
                                    season="harmonic", max.iter=1, breaks=5)
    mndvi.org.ldat.ts.bfit.niter <- length(mndvi.org.ldat.ts.bfit$output)
    mndvi.org.ldat.ts.bfit.final <- mndvi.org.ldat.ts.bfit$output[[
      mndvi.org.ldat.ts.bfit.niter]]
    mndvi.org.ldat.ts.bfit.final.breakpoints <- round(as.numeric(
      format(head(mndvi.org.ldat$DATE, 1),format = "%Y")) +
                                                        mndvi.org.ldat.ts.bfit.final$bp.Vt$breakpoints/46, digits=0)
    
    plot(mndvi.org.ldat.ts.stl,
         main = paste("Plots: ", colnames(mndvi.org.ldat)[i],
                      ", MK: ", round(mndvi.org.ldat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.ldat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.ldat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(mndvi.org.ldat.ts.stl300,
         main = paste("Plots: ", colnames(mndvi.org.ldat)[i],
                      ", MK: ", round(mndvi.org.ldat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.ldat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.ldat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(mndvi.org.ldat.ts,
         ylim = c(0,1), 
         xlab = "Date", ylab = "NDVI",
         main = paste("Plots: ", colnames(mndvi.org.ldat)[i],
                      ", MK: ", round(mndvi.org.ldat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.ldat.sm$estimate, digits = 3),
                      sep=""))
    par(new=TRUE)
    plot(mndvi.org.ldat.ts.stl$time.series[,'trend'],
         ylim = c(0,1), col = "green", lwd = 2,
         xlab = "", ylab = "")
    par(new=TRUE)
    plot(train.dm.ldat.ts.stl$time.series[,'trend'] / 
           max(abs(train.dm.ldat.ts.stl$time.series[,'trend'])) / 10.0 + 
           mean(mndvi.org.ldat.ts.stl$time.series[,'trend']),
         ylim = c(0,1), xlim = range(time(mndvi.org.ldat.ts)),
         col = "orange", lwd = 2,
         xlab = "", ylab = "")
    par(new=TRUE)
    plot(mndvi.org.ldat.ts.stl300$time.series[,'trend'],
         ylim = c(0,1), col = "blue", lwd = 2,
         xlab = "", ylab = "")
    abline(mndvi.org.ldat.lm, col = "red", lwd = 2)
    abline(v = mndvi.org.ldat.ts.bfit.final.breakpoints, col = "black", lty = 2)
    legend('top', c("Original NDVI series","1-year running trend", 
                    "11-year running trend", "linear trend","Relative rainfall"), 
           cex=0.5, col=c("black", "green", "blue", "red", "orange"), lty = 1)
    par(new=FALSE)
    
    mndvi.org.ldat.bfast[[j]] <- c(HEIGHT = mndvi.org[4,i],
                                   MK = round(mndvi.org.ldat.mk$estimate, 
                                              digits = 3),
                                   SM = round(mndvi.org.ldat.sm$estimate, 
                                              digits = 3),
                                   NIter = mndvi.org.ldat.ts.bfit.niter,
                                   BP = mndvi.org.ldat.ts.bfit.final.breakpoints)
  }
  dev.off()
  mndvi.org.ldat.mk11 <- data.frame(sapply(
    data.frame(t(do.call("cbind", mndvi.org.ldat.mk11))), unlist))
  mndvi.org.ldat.bfast <- data.frame(t(do.call("cbind", mndvi.org.ldat.bfast)))
  write.table(mndvi.org.ldat.mk11, 
              file="mndvi.org.ldat.mk11.csv", sep = ",", dec = ".")
  write.table(mndvi.org.ldat.bfast,
              file="mndvi.org.ldat.bfast.csv", sep = ",", dec = ".")
}

# Plot Mann-Kendall trends for each datasets. 
if (compute == FALSE) {
  mndvi.org.ldat.mk11 <- read.table(
    file="mndvi.org.ldat.mk11.csv", sep = ",", dec = ".")
  mndvi.org.ldat.bfast <- read.table(
    file="mndvi.org.ldat.bfast.csv", sep = ",", dec = ".")
}



### Individual plot based analysis #############################################
### Time-series decomposition and Mann-Kendall trend ###########################
# Decompose time series, identify breacks and compute Mann-Kendall trend.
# Plot time series graphs for each plot to a pdf file.
# Store the resulting datasets as csv file for further analysis so this
# procedure can be scipped next time.
mndvi.org.kdat <- subset(mndvi.org, mndvi.org$DATE >= as.Date(strptime(
  paste("2001-01-01"), "%Y-%m-%d")))

train.dm.kdat <- subset(train.dm, train.dm$DATE >= as.Date(strptime(
  paste("2001-01-01"), "%Y-%m-%d")))

if (compute) {
  pdf("mndvi_org_kdat.pdf")
  mndvi.org.kdat.mk11 <- list()
  mndvi.org.kdat.bfast <- list()
  for (j in 1:(length(mndvi.org.kdat)-2)) {
    i <- j+2
    mndvi.org.kdat.ts <- ts(mndvi.org.kdat[, i], 
                            start=as.numeric(format(head(mndvi.org.kdat$DATE,
                                                         1),format = "%Y")), 
                            freq=46)
    
    train.dm.kdat.ts <- ts(train.dm.kdat[, 
                which(colnames(train.dm.kdat)==colnames(mndvi.org.kdat)[i])], 
                           start=as.numeric(format(head(train.dm.kdat$DATE,
                                                        1),format = "%Y")), 
                           freq=12)
    
    # STL
    mndvi.org.kdat.ts.stl <- stl((mndvi.org.kdat.ts),
                                 s.window="periodic", t.window=46)
    
    mndvi.org.kdat.ts.stl300 <- stl((mndvi.org.kdat.ts),
                                    s.window="periodic", t.window=414)
    
    train.dm.kdat.ts.stl <- stl((train.dm.kdat.ts),
                                 s.window="periodic", t.window=24)
    
    # 11-year running Mann-Kendall trend
    mndvi.org.kdat.mk11[[j]] <- sapply(seq(1), function(k) {
      date.start <- 2000 + k
      date.end <- date.start + 11
      mndvi.org.kdat.ts.stl.trend <- mndvi.org.kdat.ts.stl$time.series[,'trend']
      mndvi.org.kdat.ts.stl.trend.sub <- mndvi.org.kdat.ts.stl.trend[
        time(mndvi.org.kdat.ts.stl.trend)>= date.start &
          time(mndvi.org.kdat.ts.stl.trend)< date.end]
      temp.mk <- cor.test(mndvi.org.kdat.ts.stl.trend.sub,
                          time(seq(from=date.start, to=date.end-1/46, by=1/46)),
                          method="kendall", alternative = "two.sided")
      return.mk <- list(HEIGHT = j,
                        DATEMEAN = date.start + (date.end-date.start-1)/2,
                        tau = temp.mk$estimate,
                        p = temp.mk$p.value)
      return(return.mk)
    })
    
    # Correlation and regression
    mndvi.org.kdat.sm <- cor.test(
      mndvi.org.kdat.ts.stl300$time.series[,'trend'],
      time(mndvi.org.kdat$DATE),
      method="spearman", alternative = "two.sided")
    mndvi.org.kdat.mk <- cor.test(
      mndvi.org.kdat.ts.stl300$time.series[,'trend'],
      time(mndvi.org.kdat$DATE),
      method="kendall", alternative = "two.sided")
    mndvi.org.kdat.lm <- lm(mndvi.org.kdat.ts.stl$time.series[,'trend'] ~
                              time(mndvi.org.kdat.ts))
    
    
    # BFAST
    rdist <- 10/length(mndvi.org.kdat.ts)
    mndvi.org.kdat.ts.bfit <- bfast(mndvi.org.kdat.ts, h=rdist,
                                    season="harmonic", max.iter=1, breaks=5)
    mndvi.org.kdat.ts.bfit.niter <- length(mndvi.org.kdat.ts.bfit$output)
    mndvi.org.kdat.ts.bfit.final <- mndvi.org.kdat.ts.bfit$output[[
      mndvi.org.kdat.ts.bfit.niter]]
    mndvi.org.kdat.ts.bfit.final.breakpoints <- round(as.numeric(
      format(head(mndvi.org.kdat$DATE, 1),format = "%Y")) +
                mndvi.org.kdat.ts.bfit.final$bp.Vt$breakpoints/46, digits=0)
    
    plot(mndvi.org.kdat.ts.stl,
         main = paste("Plot: ", colnames(mndvi.org.kdat)[i],
                      ", MK: ", round(mndvi.org.kdat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.kdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.kdat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(mndvi.org.kdat.ts.stl300,
         main = paste("Plot: ", colnames(mndvi.org.kdat)[i],
                      ", MK: ", round(mndvi.org.kdat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.kdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.kdat.ts.bfit.final.breakpoints),
                      sep=""))
    
    plot(mndvi.org.kdat.ts,
         ylim = range(mndvi.org.kdat.ts), xlim = range(time(mndvi.org.kdat.ts)),
         xlab = "Date", ylab = "NDVI", col = "grey",
         main = paste("Plot: ", colnames(mndvi.org.kdat)[i],
                      ", MK: ", round(mndvi.org.kdat.mk$estimate, digits = 3),
                      ", SC:", round(mndvi.org.kdat.sm$estimate, digits = 3),
                      ", Years: ", 
                      toString(mndvi.org.kdat.ts.bfit.final.breakpoints),
                      sep=""))
    par(new=TRUE)
    plot(mndvi.org.kdat.ts.stl$time.series[,'trend'],
         ylim = range(mndvi.org.kdat.ts), xlim = range(time(mndvi.org.kdat.ts)),
         col = "green", lwd = 2,
         xlab = "", ylab = "")
    par(new=TRUE)
    plot(mndvi.org.kdat.ts.stl300$time.series[,'trend'],
         ylim = range(mndvi.org.kdat.ts), xlim = range(time(mndvi.org.kdat.ts)),
         col = "blue", lwd = 2,
         xlab = "", ylab = "")
    abline(mndvi.org.kdat.lm, col = "red", lwd = 2)
    par(new=TRUE)
    plot(train.dm.kdat.ts.stl$time.series[,'trend'] / 
           max(abs(train.dm.kdat.ts.stl$time.series[,'trend'])) / 10.0 + 
           mean(mndvi.org.kdat.ts.stl$time.series[,'trend']),
         ylim = range(mndvi.org.kdat.ts), xlim = range(time(mndvi.org.kdat.ts)),
         col = "orange", lwd = 2,
         xlab = "", ylab = "")
#     plot(train.dm.tdat.ts.stl$time.series[,'trend'] / 
#            max(abs(train.dm.tdat.ts.stl$time.series[,'trend'])) / 10.0 + 0.7,
#          col = "orange", lwd = 2, axes = FALSE,
#          xlab = "", ylab = "")
#     axis(side=4)
#     mtext(side=4, line=3, "Wetness")
    legend('top', c("Original NDVI series","1-year running trend", 
                    "11-year running trend", "linear trend", "Relative rainfall"), 
           cex=0.5, col=c("black", "green", "blue", "red", "orange"), lty = 1,
           fill = "white")
    par(new=FALSE)
    
    mndvi.org.kdat.bfast[[j]] <- c(HEIGHT = mndvi.org[4,i],
                                   MK = round(mndvi.org.kdat.mk$estimate, 
                                              digits = 3),
                                   SM = round(mndvi.org.kdat.sm$estimate, 
                                              digits = 3),
                                   NIter = mndvi.org.kdat.ts.bfit.niter,
                                   BP = mndvi.org.kdat.ts.bfit.final.breakpoints)
  }
  dev.off()
  mndvi.org.kdat.mk11 <- data.frame(sapply(
    data.frame(t(do.call("cbind", mndvi.org.kdat.mk11))), unlist))
  mndvi.org.kdat.bfast <- data.frame(t(do.call("cbind", mndvi.org.kdat.bfast)))
  write.table(mndvi.org.kdat.mk11, 
              file="mndvi.org.kdat.mk11.csv", sep = ",", dec = ".")
  write.table(mndvi.org.kdat.bfast,
              file="mndvi.org.kdat.bfast.csv", sep = ",", dec = ".")
  write.table(mndvi.org.kdat[,c(1,3:length(mndvi.org.kdat))],
              file="mndvi.org.kdat.bfast.csv", sep = ",", dec = ".")
}

# Plot Mann-Kendall trends for each datasets. 
if (compute == FALSE) {
  mndvi.org.kdat.mk11 <- read.table(
    file="mndvi.org.kdat.mk11.csv", sep = ",", dec = ".")
  mndvi.org.kdat.bfast <- read.table(
    file="mndvi.org.kdat.bfast.csv", sep = ",", dec = ".")
}

