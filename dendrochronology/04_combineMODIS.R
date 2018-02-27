#04_combineMODIS
rm(list=ls())
library(raster)
mainpath <- "/mnt/sd19006/data/processing_data/modis_europe/"
datapath <- paste0(mainpath,"/MODIS/mcd11a1-europe/")
shppath <- paste0(mainpath,"/vector/")
outpath <- paste0(mainpath,"/MODIS_extracted/")
tmppath <- paste0(mainpath,"/tmp/")
rasterOptions(tmpdir = tmppath)
################################################################################
#read Data
################################################################################
files <- list.files(outpath,pattern="LST_",full.names = TRUE)
dats <- lapply(files, function(x) get(load(x)))
dats <- do.call("rbind", dats)
################################################################################
#calculate degrees C:
################################################################################

dats[,2:(ncol(dats)-2)] <- round(dats[,2:(ncol(dats)-2)]*0.02-273.15,3)

################################################################################
#calculate day and night averages:
################################################################################
#reliability <- aggregate(dats[,2:(ncol(dats)-2)],by=list("DOY"=dats$DOY),FUN=function(x){sum(!is.na(x))})

meansDayNight <- aggregate(dats[,2:(ncol(dats)-2)],by=list(dats$DOY,dats$Daytime),FUN=mean, na.rm=TRUE)
names(meansDayNight)[1] <- "Date"
meansDayNight$Date <- as.Date(as.numeric(substr(meansDayNight$Date,5,7)), 
                              origin = paste0(substr(meansDayNight$Date,1,4),"-01-01"))
meansDayNight <- meansDayNight[meansDayNight$Date>="2002-07-05",] #restrict to Aqua availability
Means_Day <- meansDayNight[meansDayNight$Group.2=="DAY",c(1,3:ncol(meansDayNight))]
Means_Night <- meansDayNight[meansDayNight$Group.2=="NIGHT",c(1,3:ncol(meansDayNight))]
################################################################################
#write as csv:
################################################################################
write.csv(Means_Day,paste0(outpath,"Means_Day.csv"),row.names=FALSE)
write.csv(Means_Night,paste0(outpath,"Means_Night.csv"),row.names=FALSE)

################################################################################
#Simple interpolations:
################################################################################
splnInterNight <- data.frame("Date"=Means_Night$Date,
                             round(apply(Means_Night[,2:ncol(Means_Night)],2,
                                   function(x){
                                     spln <- splinefun(1:length(x),x)
                                     pred_spln <- spln(1:length(x))
                                     }
                                   ),2)
                             )
splnInterDay <- data.frame("Date"=Means_Day$Date,
                           round(apply(Means_Day[,2:ncol(Means_Day)],2,
                                 function(x){
                                   spln <- splinefun(1:length(x),x)
                                   pred_spln <- spln(1:length(x))
                                   }
                                 ),2)
                           )
splnInterDaily <- data.frame("Date"=splnInterDay$Date,
                             (splnInterDay[,2:ncol(splnInterDay)]+
                                   splnInterNight[,2:ncol(splnInterNight)])/2)
write.csv(splnInterDay,paste0(outpath,"Means_Day_interpolated.csv"),row.names=FALSE)
write.csv(splnInterNight,paste0(outpath,"Means_Night_interpolated.csv"),row.names=FALSE)
write.csv(splnInterDaily,paste0(outpath,"DailyMeans_interpolated.csv"),row.names=FALSE)
