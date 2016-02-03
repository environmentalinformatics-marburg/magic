year= 2010

setwd("/media/memory01/data/IDESSA/")
outpath<-"/media/memory01/data/IDESSA/"

files<- list.files(path="statdat",pattern=".csv")
filenames<- substr(files,1,nchar(files)-4)
MSG_extract<- get(load(paste0("ExtractedData_agg_",year,".RData")))
names(MSG_extract)[2]="Station"
MSG_extract=MSG_extract[order(MSG_extract$Station, MSG_extract$date),]
MSG_extract$Station<-as.character(MSG_extract$Station)

#für jede zeile in extracted data...
rainfall<-data.frame()
for (i in 1:length(unique(MSG_extract$Station))){
  statdatsub <- MSG_extract[MSG_extract$Station==unique(MSG_extract$Station)[i],]
  statdatsub$date <- as.character(statdatsub$date)
  statdat <- read.csv(paste0("statdat/",files[which(filenames==MSG_extract$Station[i])]))
  statdat$datetime <- as.character(statdat$datetime)
  statdat$datetime<- gsub("-", "",statdat$datetime)
  statdat$datetime<-gsub("T", "",statdat$datetime)
  statdat$datetime<-gsub(":", "",statdat$datetime)
  
  for (k in 1:nrow(statdatsub)){
    if (any(statdatsub$date[k]==statdat$datetime)==FALSE){next}
    if(sum(is.na(data.frame(statdatsub[k,],
                            statdat[statdatsub$date[k]==statdat$datetime,4:5])[3:13]))==11){next}
    rainfall <- rbind(rainfall,data.frame(statdatsub[k,],
                                          statdat[statdatsub$date[k]==statdat$datetime,4:5]))
  }
  print(paste0(i, "von ", length(unique(MSG_extract$Station))))
}


save(rainfall,file=paste0(outpath,"StationMatch_",year,".RData"))