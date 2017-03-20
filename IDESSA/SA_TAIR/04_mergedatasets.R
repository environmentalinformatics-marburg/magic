rm(list=ls())
setwd("/media/hanna/data/IDESSA_TAIR/extracted/")
dats <- list.files(,pattern="StationMatch")

dataset <- data.frame()
for (i in 1:length(dats)){
  dat <- get(load(dats[i]))
  dat <- dat[complete.cases(dat),]
  dataset <- rbind(dataset,dat)
}

names(dataset)[names(dataset)=="rainfall"]<-"Tair"
save(dataset,file="Tair_dataset.RData")
