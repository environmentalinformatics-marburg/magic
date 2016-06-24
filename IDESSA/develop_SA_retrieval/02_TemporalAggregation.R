
#Aggregate to 1h
library(lubridate)
years= c(2014)

setwd("/media/memory01/data/IDESSA/")
outpath<-"/media/memory01/data/IDESSA/Results/ExtractedData/"

for(year in years){
  MSG_extract<- get(load(paste0("ExtractedData_",year,".RData")))
  hours <- substr(MSG_extract$date,1,10)
  results <- aggregate(MSG_extract[,c("VIS0.6","VIS0.8","NIR1.6","IR3.9",
                                      "WV6.2","WV7.3","IR8.7","IR9.7","IR10.8",
                                      "IR12.0","IR13.4","sunzenith")],
                       by=list(hours,MSG_extract$as.character.stations.data.Name.),
                       FUN="median",na.rm=T)
  
  
  results <- results[complete.cases(results[6:ncol(results)]),] #vis und nir nicht bei nacht deshalb ab 6
  names(results)[1:2]<-c("date","Name")
  results$date <- strptime(results$date,format="%Y%m%d%H") + hours(1) 
  tmp <- gsub(":00:00","",as.character(results$date))
  tmp <- gsub(" ","",gsub("-","",tmp))
  results$date <- tmp
  save(results,file=paste0(outpath,"ExtractedData_agg_",year,".RData"))
  print(paste0(year," done..."))
}
