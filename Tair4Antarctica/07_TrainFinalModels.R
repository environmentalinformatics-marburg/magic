rm(list=ls())
library(caret)
library(doParallel)
################################################################################
#datapath <-"/media/memory01/casestudies/hmeyer/Antarctica/"
#outpath <- "/media/memory01/casestudies/hmeyer/Antarctica/"
datapath <-"/media/hanna/data/Antarctica/results/MLFINAL//"
outpath <- "/media/hanna/data/Antarctica/results/MLFINAL//"
doParallel <- FALSE
################################################################################

load(paste0(datapath,"/trainData.RData"))
load(paste0(datapath,"/testData.RData"))
load(paste0(datapath,"/ffs_best_SD.RData"))
predictors <- trainData[,ffs_best$final$xNames]
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
################################################################################
#Models
################################################################################
ctrl <- trainControl(index=cvindices,
                     method="cv", returnResamp="all")
################################################################################
model_LIN<-train(data.frame("LST"=predictors$LST),trainData$statdat,
                 method="lm",trControl=ctrl)
linMod <- predict(model_LIN,testData)
testData$linMod <- linMod
save(model_LIN,file=paste0(outpath,"model_LIN.RData"))
save(testData,file=paste0(outpath,"testData.RData"))
load(paste0(outpath,"testData.RData"))
################################################################################
tgrid <- expand.grid(mtry=seq(2,ncol(predictors),2))
set.seed(100)
model_RF<-train(predictors,trainData$statdat,method="rf",trControl=ctrl,tuneGrid=tgrid,
                importance=TRUE,ntree=1000)
rfMod <- predict(model_RF,testData)
testData$rfMod <- rfMod
save(model_RF,file=paste0(outpath,"model_RF.RData"))
save(testData,file=paste0(outpath,"testData.RData"))
load(paste0(outpath,"testData.RData"))
################################################################################
tgrid <- expand.grid(n.trees=c(25,50, seq(100,500,1000)),
                     interaction.depth=seq(1,ncol(predictors),2),
                     shrinkage= c(0.01, 0.1),
                     n.minobsinnode=10)
set.seed(100)
model_GBM <- train(predictors,trainData$statdat,trControl=ctrl,
                   method = "gbm",tuneGrid = tgrid)
gbmMod <- predict(model_GBM,testData[,ffs_best$final$xNames])
testData$gbmMod <- gbmMod
save(model_GBM,file=paste0(outpath,"model_GBM.RData"))
save(testData,file=paste0(outpath,"testData.RData"))
load(paste0(outpath,"testData.RData"))
################################################################################
tgrid <- expand.grid(committees=seq(20,80,20), neighbors=seq(3,9,3))
set.seed(100)
model_CUB <- train(predictors,trainData$statdat,trControl=ctrl,
                   method = "cubist",tuneGrid=tgrid)
cubMod <- predict(model_CUB,testData)
testData$cubMod <- cubMod
save(model_CUB,file=paste0(outpath,"model_CUB.RData"))
################################################################################
save(testData,file=paste0(outpath,"testData.RData"))
