#Aggregate to 1h
year= 2010

setwd("/media/memory01/data/IDESSA/")
outpath<-"/media/memory01/data/IDESSA/"

MSG_extract<- get(load(paste0("ExtractedData_",year,".RData")))



hours<-substr(MSG_extract$date,1,10)
uniquehours<-unique(hours)
results<-data.frame()
for (i in 1:length(uniquehours)){
  subset <- MSG_extract[hours==uniquehours[i],]
  uniquestations <- unique(subset$as.character.stations.data.Name.)
  for (k in 1:length(uniquestations)){
    subset2 <- subset[subset$as.character.stations.data.Name.==uniquestations[k],]
    if (nrow(subset2)<4){next}

    agg<-aggregate(subset2[,3:ncol(subset2)],by=list(subset2$as.character.stations.data.Name.),FUN="median")
    agg <- data.frame("date"=uniquehours[i],agg)
    results<-rbind(results,agg)
    print(paste0("Station ",k, " of Date ",uniquehours[i]))
  }
}

results <- results[complete.cases(results[3:ncol(results)]),]
save(results,file=paste0(outpath,"ExtractedData_agg_",year,".RData"))