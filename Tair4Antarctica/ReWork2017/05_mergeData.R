#05 merge with measurements
rm(list=ls())
library(raster)
library(lubridate)
mainpath <- "/media/memory02/users/hmeyer/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")
modelpath <- paste0(datapath, "/modeldat/")

extracted <- list.files(paste0(rdatapath,"extracted/"),full.names = TRUE,pattern="extract")
extracted_VIS <- list.files(paste0(rdatapath,"extracted_VIS/"),full.names = TRUE,pattern="extract")
dailydat <- get(load(paste0(rdatapath,"stationdat_daily.RData")))

###aggregate LST data

results <- vector("list", length(extracted))
for (i in 1:length(extracted)){
  extr <- get(load(extracted[i]))
  extr <- extr[complete.cases(extr$LST),]
  extr_agg <- aggregate(extr$LST,FUN=mean,na.rm=T,by=list(extr$Date,extr$Station,extr$daynight))
  names(extr_agg) <- c("Date","Station","daynight","LST")
  day<-extr_agg[extr_agg$daynight=="Day",]
  night<-extr_agg[extr_agg$daynight=="Night",]
  extr_agg <- merge(day,night,by.x=c("Date","Station"),by.y=c("Date","Station"))
  extr_agg <- extr_agg[,c(1:2,4,6)]
  names(extr_agg) <- c("Date","Station","LST_day","LST_night")
  results[[i]] <- extr_agg
}
###merge with measurements
results <- do.call("rbind",results)
results$Date <- as.Date(as.numeric(substr(results$Date,5,7)), 
                         origin=as.Date(paste0(as.numeric(substr(results$Date,1,4))-1,"-12-31")))
results_merged <- merge(results,dailydat,by.x=c("Date","Station"),by.y=c("Date","Name"))
results_merged <- results_merged[complete.cases(results_merged),]

###merge with VIS

results <- list()
for (i in 1:length(extracted_VIS)){
  extr <- get(load(extracted_VIS[i]))
  results[[i]] <- extr
}
results <- do.call("rbind",results)
results$Date <- as.Date(as.numeric(substr(results$Date,5,7)), 
                        origin=as.Date(paste0(as.numeric(substr(results$Date,1,4))-1,"-12-31"))) 
results_merged <- merge(results_merged,results,by.x=c("Date","Station"),by.y=c("Date","Station"))



###add auxiliary infos
aux <- get(load(paste0(rdatapath,"aux_extr.RData")))
results_merged$DOY <- yday(results_merged$Date)
results_merged <- merge(results_merged,aux,by.x=c("DOY","Station"),by.y=c("Doy","Station"))

results_merged<-results_merged[complete.cases(results_merged),]
###save results
save(results_merged, file =paste0(modelpath,"full_dataset.RData"))
