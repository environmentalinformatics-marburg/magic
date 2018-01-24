# this script validates RADOLAN
#against climate station records of the Exploratories
#Author: Hanna Meyer
#Date: 17.01.2018

rm(list=ls())
mainpath <- "/home/hanna/Documents/Projects/Exploratories/"
library(Rsenal)
library(reshape2)
library(ggplot2)
library(viridis)




stationdat <- read.csv(paste0(mainpath,"/RainfallExtraction/validationData/a0aa48545720a699/plots.csv"))
stationdat$datetime <- strptime(stationdat$datetime,format="%Y-%m-%dT%H")
stationdat$datetime <- format(round(stationdat$datetime, units="hours"), format="%Y-%m-%d %H:%M")
stationdat <- stationdat[,which(names(stationdat)%in%c("plotID","datetime","P_RT_NRT"))]

###match radolan and stationdat
load(paste0(mainpath,"/Radolan/radolan_melt.RData"))
radolan$variable <- paste0(substr(radolan$variable,1,3),sprintf("%02d", as.numeric(substr(radolan$variable,4,5))))
radolan <- radolan[radolan$variable%in%unique(stationdat$plotID),]
radolan$Date <-  format(round(radolan$Date, units="hours"), format="%Y-%m-%d %H:%M")
radolan <- radolan[radolan$Date%in%unique(stationdat$datetime),]
compDat <- merge(stationdat,radolan,by.y=c("Date","variable"),by.x=c("datetime","plotID"))

names(compDat)[3] <- "Reference"
names(compDat)[4] <- "RADOLAN"
################################################################################
# Hourly
################################################################################
regressionStats(compDat$Reference,compDat$RADOLAN)
pdf(paste0(mainpath,"/validation.pdf"),width=6,height=5)
ggplot(compDat, aes(Reference,RADOLAN)) + 
  stat_binhex(bins=100)+
  xlim(min(compDat[,3:4]),max(compDat[,3:4]))+ylim(min(compDat[,3:4]),max(compDat[,3:4]))+
  xlab("Measured Rainfall (mm/h)")+
  ylab("RADOLAN-based Rainfall (mm/h)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:6),colors=viridis(10))
dev.off()

pdf(paste0(mainpath,"/validation_detail.pdf"),width=6,height=5)
ggplot(compDat, aes(Reference,RADOLAN)) + 
  stat_binhex(bins=100)+
  xlim(0,15)+ylim(0,15)+
  xlab("Measured Rainfall (mm/h)")+
  ylab("RADOLAN-based Rainfall (mm/h)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:5),colors=viridis(10))
dev.off()

################################################################################
# Daily
################################################################################

compDat_day <- aggregate(compDat[,3:4],by=data.frame("Date"=substr(compDat$datetime,1,10)),FUN=sum,na.rm=T)
regressionStats(compDat_day$Reference,compDat_day$RADOLAN)

pdf(paste0(mainpath,"/validation_day.pdf"),width=6,height=5)
ggplot(compDat_day, aes(Reference,RADOLAN)) + 
  stat_binhex(bins=100)+
  xlim(min(compDat_day[,2:3]),max(compDat_day[,2:3]))+ylim(min(compDat_day[,2:3]),max(compDat_day[,2:3]))+
  xlab("Measured Rainfall (mm/h)")+
  ylab("RADOLAN-based Rainfall (mm/h)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:4),colors=viridis(10))
dev.off()

pdf(paste0(mainpath,"/validation_day_detail.pdf"),width=6,height=5)
ggplot(compDat_day, aes(Reference,RADOLAN)) + 
  stat_binhex(bins=100)+
  xlim(0,200)+ylim(0,200)+
  xlab("Measured Rainfall (mm/h)")+
  ylab("RADOLAN-based Rainfall (mm/h)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:3),colors=viridis(10))
dev.off()

