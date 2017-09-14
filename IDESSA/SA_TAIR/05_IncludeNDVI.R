rm(list=ls())
setwd("/home/hanna/Documents/Projects/IDESSA/airT/")
ndvi <- read.csv("/home/hanna/Documents/Projects/IDESSA/airT/ndvi/WeaterStationsNDVI.csv")
load("extracted/Tair_dataset.RData")
dataset$date <- strptime(dataset$date,format="%Y%m%d%H%M")
dataset$dateYD <- as.Date(dataset$date)
datendvi <- as.Date(substr(names(ndvi),10,16),format="%Y%j")

dataset$ndvi <- NA
for (i in 1:length(unique(dataset$dateYD))){
  print(i)
  subs <- which(dataset$dateYD==unique(dataset$dateYD)[i])
  ndvi_subs <- ndvi[,c(1,2,which(abs(difftime(unique(dataset$dateYD)[i], datendvi))==
                                   min(abs(difftime(unique(dataset$dateYD)[i], 
                                                    datendvi)),na.rm = TRUE)))]
  dat_subs <- dataset[subs,]
  tmp <- merge(dat_subs,ndvi_subs,by.x="Station",by.y="plot",all.x=TRUE)
  dataset$ndvi[subs] <- tmp[,ncol(tmp)]
}
save(dataset,file="dataset_withNDVI.RData")
