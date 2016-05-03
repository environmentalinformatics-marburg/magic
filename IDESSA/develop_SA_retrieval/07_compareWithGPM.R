rm(list=ls())
library(Rsenal)
library(caret)
library(Rainfall)

setwd("/media/memory01/data/IDESSA/Model/")
##load model (RA,RR,day,night):
model <- get(load("day_model_RA.RData"))
################################################################################
#load msg, claculate predictors
################################################################################
msg <- getChannels(paste0(msgpath,"/cal"))
msg <- stack(msg,getSunzenith(paste0(msgpath,"/meta")))
msg_add <- calculatePredictors(msg,spectral=c("T6.2_10.8","T7.3_12.0", 
                                              "T8.7_10.8","T10.8_12.0", "T3.9_7.3",
                                              "T3.9_10.8"),further=NULL)
msg<-stack(msg,msg_add)
extent(msg)<-c(1408689.286,2908890.869, -3493969.487,-2293808.22)
proj4string(msg)<-CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs")


################################################################################
# apply cloud mask
################################################################################


## predict auf msg mit predict4Rainfall (scale var)

###lade passendes gpm with rasterizeIMERG
#crop(imerg,msgpred)
###aggregiere imerg auf stunde. aggregiere msgProdukt auf 10km
###compare both with stations

imergData <- list.files("/media/memory01/data/data01/RainfallProducts/IMERG_GPM_2014/",recursive = TRUE)

date <- substr(imergData,nchar(imergData)-38,nchar(imergData)-31)
time <- substr(imergData,nchar(imergData)-28,nchar(imergData)-25)

