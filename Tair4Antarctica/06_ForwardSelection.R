rm(list=ls())
library(caret)
library(doParallel)
#library(Rsenal)
################################################################################
datapath <-"/media/memory01/casestudies/hmeyer/Antarctica/"
outpath <- "/media/memory01/casestudies/hmeyer/Antarctica/"
#datapath <-"/media/hanna/data/Antarctica/results/ML/"
#outpath <- "/media/hanna/data/Antarctica/results/ML/"
doParallel <- TRUE
################################################################################
source("/home/hmeyer/hmeyer/Antarctica/ffs.R")
load(paste0(datapath,"/trainData.RData"))
load(paste0(datapath,"/testData.RData"))
predictornames <- c("LST",
                    "time",
                    "month",
                    "season",
                    "sensor",
                    "dem",
                    "slope",
                    "aspect",
                    "skyview",
                    "ice")
predictors <- trainData[,predictornames]
cvindices <- list()
acc <- 1
for (i in unique(trainData$station)){
  cvindices[[acc]] <- which(trainData$station!=i)
  acc <- acc+1
}
if(doParallel){
  cl <- makeCluster(detectCores())
  registerDoParallel(cl)
}

ctrl <- trainControl(index=cvindices,
                     method="cv",savePredictions = TRUE)
fullModel <-train(predictors,trainData$statdat,method="cubist",
                  trControl = ctrl,tuneLength=3)
save(fullModel,file=paste0(outpath,"fullModel.RData"))
ffs_best <-ffs(predictors,trainData$statdat,method="cubist",
               trControl = ctrl,runParallel=TRUE,tuneLength=3)
save(ffs_best,file=paste0(outpath,"ffs_best_SD.RData"))


 