#05_calculate predictors
#Script calculates climatic predictors from temperature and rainfall
rm(list=ls())
library(reshape2)
library(lubridate)
library(metTools)
library(dplyr)
mainpath <- "/home/hanna/Documents/Projects/Dendrodaten/"
targetdatpath <- paste0(mainpath, "/data/Dendrodaten/")
predpath <- paste0(mainpath, "/data/T_Prec_basedata/")

################################################################################
# read and re-format climate data
################################################################################

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
#remove all data before year 2013 (because Aqua only started 2013)
predictors_all <- predictors_all[year(predictors_all$Date)>=2003,]

################################################################################
# Calculate Ecopredictors
################################################################################

predictors_all$GDD <- GDD(predictors_all$tday,predictors_all$tnight)
Gdd_agg <- aggregateClimate(predictors_all,dts="Date",plotID="Plot",
                            variable="GDD",fun="sum",agg = "month")

predictors_all$Gsum <- Gsum(predictors_all$tmean)

ecodat <- data.frame(aggregateClimate(predictors_all,dts="Date",plotID="Plot",
                                      variable="Gsum",fun="sum",agg = "month"),
                     aggregateClimate(predictors_all,dts="Date",plotID="Plot",
                                      variable="GDD",fun="sum",agg = "month")[,-(1:2)],
                     aggregateClimate(predictors_all,dts="Date",plotID="Plot",
                                      variable="tmean",fun="mean",agg = "month")[,-(1:2)],
                     aggregateClimate(predictors_all,dts="Date",plotID="Plot"
                                      ,variable="prec",fun="sum",agg = "month")[,-(1:2)],
                     "prec_year"=aggregateClimate(predictors_all,dts="Date",plotID="Plot"
                                                  ,variable="prec",fun="sum",agg = "year")[,-(1:2)],
                     "tmean_year"=aggregateClimate(predictors_all,dts="Date",plotID="Plot"
                                                   ,variable="tmean",fun="mean",agg = "year")[,-(1:2)]
)

################################################################################
# Shift yearly Prec and Temp one year forward
################################################################################

ecodat$tmean_lag1 <- NA
for (i in 1:length(unique(ecodat$Plot))){
  ecodat$tmean_lag1[ecodat$Plot==unique(ecodat$Plot)[i]] <- transform(
    ecodat[ecodat$Plot==unique(ecodat$Plot)[i],], 
    tmean_lag1 = lag(ecodat$tmean_year[ecodat$Plot==unique(ecodat$Plot)[i]]))$tmean_lag1
}
ecodat$prec_lag1 <- NA
for (i in 1:length(unique(ecodat$Plot))){
  ecodat$prec_lag1[ecodat$Plot==unique(ecodat$Plot)[i]] <- transform(
    ecodat[ecodat$Plot==unique(ecodat$Plot)[i],], 
    prec_lag1 = lag(ecodat$prec_year[ecodat$Plot==unique(ecodat$Plot)[i]]))$prec_lag1
}

save(ecodat,file=paste0(predpath,"predictors.RData"))

