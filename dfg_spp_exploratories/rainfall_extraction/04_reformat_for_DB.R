#format for database

rm(list=ls())
mainpath <- "/home/hanna/Documents/Projects/Exploratories/Radolan/"
outpath <- paste0(mainpath, "/data_extracted/")
load(paste0(mainpath,"/radolan_melt.RData"))

names(radolan) <- c("datetime","plotID","precipitation_radolan")
radolan$plotID <- paste0(substr(radolan$plotID,1,3),sprintf("%02d", as.numeric(substr(radolan$plotID,4,5))))
radolan$datetime <- format(as.POSIXlt(radolan$datetime), "%Y-%m-%dT%H:%M")

for (i in unique(radolan$plotID)){
  subs <- radolan[radolan$plotID==i,c(1,3)]
  write.csv(subs,paste0(outpath,i,".csv"),row.names=FALSE)
}

