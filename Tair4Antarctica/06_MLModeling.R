rm(list=ls())
library(caret)
#load("/media/hanna/data/Antarctica/results/ExactTimeEvaluation/validationDat.RData")
load("/media/hanna/data/Antarctica/results/ML/trainData.RData")
load("/media/hanna/data/Antarctica/results/ML/testData.RData")
predictors <- trainData[,c("LST","time","month","sensor",
                           "dem","slope","aspect","skyview",
                           "ice")]
cvindices <- list()
acc <- 1
for (i in unique(trainData$station)){
  cvindices[[acc]] <- which(trainData$station!=i)
  acc <- acc+1
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
save(model_LIN,file="/media/hanna/data/Antarctica/results/ML/model_LIN.RData")
save(testData,file="/media/hanna/data/Antarctica/results/ML/testData.RData")
load("/media/hanna/data/Antarctica/results/ML/testData.RData")
################################################################################
tgrid <- expand.grid(mtry=2:ncol(predictors))
set.seed(100)
model_RF<-train(predictors,trainData$statdat,method="rf",trControl=ctrl,tuneGrid=tgrid,
                importance=TRUE,ntree=1000)
rfMod <- predict(model_RF,testData)
testData$rfMod <- rfMod
save(model_RF,file="/media/hanna/data/Antarctica/results/ML/model_RF.RData")
save(testData,file="/media/hanna/data/Antarctica/results/ML/testData.RData")
load("/media/hanna/data/Antarctica/results/ML/testData.RData")
################################################################################
tgrid <- expand.grid(n.trees=c(25,50, seq(100,500,100)),
                     interaction.depth=seq(1,ncol(predictors),2),
                     shrinkage= c(0.01, 0.1),
                     n.minobsinnode=10)
set.seed(100)
model_GBM <- train(predictors,trainData$statdat,trControl=ctrl,
                   method = "gbm",tuneGrid = tgrid)
gbmMod <- predict(model_GBM,testData)
testData$gbmMod <- gbmMod
save(model_RF,file="/media/hanna/data/Antarctica/results/ML/model_GBM.RData")
save(testData,file="/media/hanna/data/Antarctica/results/ML/testData.RData")
load("/media/hanna/data/Antarctica/results/ML/testData.RData")
################################################################################
tgrid <- expand.grid(committees=seq(20,80,20), neighbors=seq(3,9,3))
set.seed(100)
model_CUB <- train(predictors,trainData$statdat,trControl=ctrl,
                   method = "cubist",tuneGrid=tgrid)
cubMod <- predict(model_CUB,testData)
testData$cubMod <- cubMod
save(model_RF,file="/media/hanna/data/Antarctica/results/ML/model_CUB.RData")
################################################################################
save(testData,file="/media/hanna/data/Antarctica/results/ML/testData.RData")
