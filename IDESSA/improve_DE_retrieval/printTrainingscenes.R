#script prints the trainingscenes
rm(list=ls())
resultpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results"
samplesize=0.1 # number of scenes for training
y<-2010 # year
daytimes <- c("day","twilight","night")

library(Rainfall)

load(paste0(resultpath,"/rainevents.RData"))
trainingsc<-list()
i=1
for (dayt in daytimes) {
  
  ### Definde training scenes ##################################################
  #  scenes<-list.dirs(msgpath,recursive=TRUE)
  #  trainingscenes<-randomScenes(sampsize=samplesize,seed=50)
  
  ###neu:
  ts <- rainevents[rainevents$daytime==dayt,]
  set.seed(20)
  ts <- ts[sample(nrow(ts),samplesize*nrow(ts)),]
  trainingscenes <- as.vector(paste0(y,ts[,1],ts[,2],ts[,3]))
  trainingsc[[i]]<-trainingscenes
  i=i+1
}

save(trainingsc,file="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results/trainingscenes.RData")