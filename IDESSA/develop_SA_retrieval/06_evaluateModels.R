#evaluate Models
rm(list=ls())
library(Rainfall)
library(Rsenal)
library(caret)
setwd("/media/memory01/data/IDESSA/Results/Model/")
outpath <- "/media/memory01/data/IDESSA/Results/Evaluation/"

for (daytime in c("day","night")){
  testData <- get(load(paste0("test_dataset_",daytime,".RData")))
  results <- data.frame("Date"=testData$date,"Station"=testData$Station)
  for (responsetype in c("RA","RR")){
    model <- get(load(paste0(daytime,"_model_",responsetype,".RData")))
    predVars <- scaleByValue(testData[,row.names(model$scaleParam)],model$scaleParam)
    if (responsetype=="RR"){
      tmpnamespred<-paste0(responsetype,"_pred")
      tmpnamesobs <- paste0(responsetype,"_obs")
      tmp <- data.frame(testData$P_RT_NRT,predict(model,predVars))
      results <- data.frame(results,tmp)
      names(results)[(ncol(results)-1):ncol(results)] <- c(
        tmpnamesobs,tmpnamespred)
      
    }else{
      tmp <- data.frame(testData$RainArea, predict(model,predVars),
                        predict(model,predVars,type="prob")$Rain)

          results <- data.frame(results,tmp)
      tmpnamesprob <- paste0(responsetype,"_prob")
      tmpnamespred <- paste0(responsetype,"_pred")
      tmpnamesobs <- paste0(responsetype,"_obs")
      names(results)[(ncol(results)-2):ncol(results)] <- c(
        tmpnamesobs,tmpnamespred,tmpnamesprob)
    }
  }
  results$RR_pred[results$RA_pred=="NoRain"]=0
  if(daytime=="night"){
    results_all <- rbind(resultstmp,results)
  }
  if(daytime=="day"){
    resultstmp <- results
  }
  save(results,file=paste0(outpath,"evaluationData_",daytime,".RData"))
}
save(results_all,file=paste0(outpath,"evaluationData_all.RData"))

