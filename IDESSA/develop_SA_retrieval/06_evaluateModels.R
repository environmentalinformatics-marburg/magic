#evaluate Models
rm(list=ls())
library(Rainfall)
library(Rsenal)
library(caret)
setwd("/media/hanna/data/Rainfall4SA/Results/Model/")
outpath <- "/media/hanna/data/Rainfall4SA/Results/Evaluation/"

for (daytime in c("day","night")){
  acc<-0

  for (responsetype in c("RA","RR")){
    acc <- acc+1
    model <- get(load(paste0(daytime,"_model_",responsetype,".RData")))
    testData <- get(load(paste0("test_dataset_",daytime,".RData")))
    predVars <- scaleByValue(testData[,row.names(model$scaleParam)],model$scaleParam)
    if (responsetype=="RR"){
      tmpnamespred<-paste0(daytime,"_",responsetype,"_pred")
      tmpnamesobs <- paste0(daytime,"_",responsetype,"_obs")
      tmp <- data.frame(testData$P_RT_NRT,predict(model,predVars))
      if (acc==1){
        results <- tmp}else{
      results <- data.frame(results,tmp)
        }
      names(results)[(ncol(results)-1):ncol(results)] <- c(
        tmpnamesobs,tmpnamespred)
      
    }else{
      tmp <- data.frame(testData$RainArea, predict(model,predVars),
                        predict(model,predVars,type="prob")$Rain)
      if (acc==1){
        results <- tmp}else{
          results <- data.frame(results,tmp)
        }
      tmpnamesprob <- paste0(daytime,"_",responsetype,"_prob")
      tmpnamespred <- paste0(daytime,"_",responsetype,"_pred")
      tmpnamesobs <- paste0(daytime,"_",responsetype,"_obs")
      names(results)[(ncol(results)-2):ncol(results)] <- c(
        tmpnamesobs,tmpnamespred,tmpnamesprob)
    }
  }
  save(results,file=paste0(outpath,"evaluationData_",daytime,".RData"))
  }





