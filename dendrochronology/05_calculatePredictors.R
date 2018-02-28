#05_calculate predictors
#Script calculates climatic predictors from temperature and rainfall
rm(list=ls())
library(reshape2)
library(lubridate)
mainpath <- "/home/hanna/Documents/Projects/Dendrodaten/"
targetdatpath <- paste0(mainpath, "/data/Dendrodaten/")
predpath <- paste0(mainpath, "/data/T_Prec_basedata/")

source("/home/hanna/Documents/Release/environmentalinformatics-marburg/magic/dendrochronology/functions.R")

prec <- read.csv(paste0(predpath,"/rainfall_combined.csv"))
tmean <- read.csv(paste0(predpath,"/DailyMeans_interpolated.csv"))
tnight <- read.csv(paste0(predpath,"/Means_Night_interpolated.csv"))
tday <- read.csv(paste0(predpath,"/Means_Day_interpolated.csv"))
#reshape
tmean <- melt(tmean)
names(tmean) <- c("Date","Plot","tmean")
tnight <- melt(tnight)
names(tnight) <- c("Date","Plot","tnight")
tday <- melt(tday)
names(tday) <- c("Date","Plot","tday")
prec <- melt(prec)
names(prec) <- c("Date","Plot","prec")
#combine base data
predictors_all <- merge(tmean,prec,by=c("Date","Plot"))
predictors_all <- merge(predictors_all,tday,by=c("Date","Plot"))
predictors_all <- merge(predictors_all,tnight,by=c("Date","Plot"))


predictors_all$Plot <- gsub("_", "", predictors_all$Plot)
predictors_all <- predictors_all[year(predictors_all$Date)>=2003,]
#################################

################################################################################
# Initialize Target predictors_all: for each year and each tree the corresponding 
# predictors
################################################################################

targetdat <- expand.grid("Plot"=unique(predictors_all$Plot),
                         "Year"=unique(year(predictors_all$Date)))
ecotemp <- calculateEcoClimate(dat=predictors_all, plotID="Plot",
                               tday="tday",tnight="tnight")

targetdat <- data.frame(targetdat,ecotemp)
save(targetdat,file=paste0(predpath,"predictors.RData"))

##################################
