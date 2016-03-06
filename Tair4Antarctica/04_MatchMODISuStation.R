rm(list=ls())
year <- 2013

stationdat <- get(load("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/Stationdat.RData"))
timeExtrs <- get(load(paste0("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/time_extracted_",
year,".RData")))
LSTExtrs <- get(load(paste0("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/data_extracted_",
year,".RData")))
StationMeta <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationDataAnt.shp","StationDataAnt")
StationMeta@data$Name <- gsub("([.])", "",StationMeta@data$Name)
StationMeta@data$Name <- gsub("([ ])", "", StationMeta@data$Name)


#correct for time zone
#UNIVW time-13h
adaptTime<- StationMeta@data[
  StationMeta@data$Name%in%names(stationdat),]
adaptTime<-adaptTime[adaptTime$Type=="Univ_Wisconsin",]
adaptTime_dat <- stationdat[names(stationdat)%in%adaptTime$Name]


for (i in 1:length(adaptTime_dat)){
  adaptTime_dat[[i]]$time <- adaptTime_dat[[i]]$time-13
  adaptTime_dat[[i]]$doy[adaptTime_dat[[i]]$time<0] <- adaptTime_dat[[i]]$doy[adaptTime_dat[[i]]$time<0]-1
  adaptTime_dat[[i]]$time[adaptTime_dat[[i]]$time<0] <- 24+adaptTime_dat[[i]]$time[adaptTime_dat[[i]]$time<0]
  adaptTime_dat[[i]] <- adaptTime_dat[[i]][adaptTime_dat[[i]]$doy>0,]
  stationdat[which(names(stationdat)==names(adaptTime_dat)[i])]<-adaptTime_dat[i]
}

for (sensor in names(timeExtrs)){
  timeExtr <-eval(parse(text=paste("timeExtrs$",sensor)))
  timeExtr<-timeExtr[2:length(timeExtr)]
  LSTExtr <-eval(parse(text=paste("LSTExtrs$",sensor)))
  dates <- LSTExtr$date
  LSTExtr<-LSTExtr[2:length(LSTExtr)]
  timeExtr <- round(timeExtr)
  names(LSTExtr) <- gsub("([.])", "", names(LSTExtr))
  names(LSTExtr) <- gsub("([ ])", "", names(LSTExtr))
  names(timeExtr) <- gsub("([.])", "", names(timeExtr))
  names(timeExtr) <- gsub("([ ])", "", names(timeExtr))
  
  
  LSTExtr <- LSTExtr[names(LSTExtr)%in%names(stationdat)]
  timeExtr <- timeExtr[names(timeExtr)%in%names(stationdat)]

  ###overflight times???
  stationdat<-stationdat[order(names(stationdat))]
  LSTExtr <- LSTExtr[order(names(LSTExtr))]
  timeExtr <- timeExtr[order(names(timeExtr))]
  
  
  #for every column (=Station) and every MODIS record in LSTExtr: 
  #look for corresponding stationdat
  matched_data <- list()
  namevector <- c()
  acc<-0
  for (station in 1:ncol(LSTExtr)){
    if(!any(names(stationdat)==names(LSTExtr)[station])){ print("names doesn't match") 
      next}
    acc<-acc+1
    namevector <- c(namevector, names(LSTExtr)[station])
    statdat <- stationdat[[which(names(stationdat)==names(LSTExtr)[station])]]
    doy <- as.numeric(substr(dates,nchar(dates)-2,nchar(dates)))
    date <- timeExtr[,station]
    LSTdata <- LSTExtr[,station]
    matched_data[[acc]] <- data.frame()
    for (i in 1:length(doy)){
      if (is.na(date[i])){next}
      if(length(statdat$airT[statdat$doy==doy[i]&statdat$time==date[i]])==0){next}
      matched_data[[acc]] <- rbind(matched_data[[acc]],
                                   data.frame("doy"=doy[i],
                                              "time"=date[i],
                                              "statdat"=statdat$airT[statdat$doy==doy[i]&statdat$time==date[i]],
                                              "LST"=LSTdata[i]))
    }
  }
  
  names(matched_data)<-namevector
  matched_data <- matched_data[which(lapply(matched_data,length)!=0)]
  save(matched_data,file=paste0("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/ComparisonTable_",
                                sensor,".RData"))
}

