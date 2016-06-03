#Aggregate to 1h
years= c(2010:2014)

setwd("/media/memory01/data/IDESSA/")
outpath<-"/media/memory01/data/IDESSA/"

for(year in years){
  MSG_extract<- get(load(paste0("ExtractedData_",year,".RData")))
  
  
  #tmp<-MSG_extract
  #MSG_extract<-MSG_extract[complete.cases(MSG_extract[,6:8]),]
  hours <- substr(MSG_extract$date,1,10)
  results <- aggregate(MSG_extract[,c("VIS0.6","VIS0.8","NIR1.6","IR3.9",
                                      "WV6.2","WV7.3","IR8.7","IR9.7","IR10.8",
                                      "IR12.0","IR13.4","sunzenith")],
                       by=list(hours,MSG_extract$as.character.stations.data.Name.),
                       FUN="median",na.rm=T)
  
  
  # hours<-substr(MSG_extract$date,1,10)
  # uniquehours<-unique(hours)
  # results<-data.frame()
  # for (i in 1:length(uniquehours)-1){
  #   subset <- MSG_extract[hours==uniquehours[i],]
  #   uniquestations <- unique(subset$as.character.stations.data.Name.)
  #   for (k in 1:length(uniquestations)){
  #     subset2 <- subset[subset$as.character.stations.data.Name.==uniquestations[k],]
  #     if (nrow(subset2)<4){next}
  # 
  #     agg<-aggregate(subset2[,3:ncol(subset2)],by=list(subset2$as.character.stations.data.Name.),FUN="median")
  #     agg <- data.frame("date"=uniquehours[i+1],agg)
  #     results<-rbind(results,agg)
  #     
  #   }
  #   print(paste0(uniquehours[i]," done"))
  # }
  
  results <- results[complete.cases(results[3:ncol(results)]),]
  names(results)[1:2]<-c("date","Name")
  save(results,file=paste0(outpath,"ExtractedData_agg_",year,".RData"))
}