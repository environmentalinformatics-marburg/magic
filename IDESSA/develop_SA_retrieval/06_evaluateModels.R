#evaluate Models
library(Rainfall)
library(Rsenal)
library(caret)
setwd("/media/memory01/data/IDESSA/Model")
outpath <- "/media/memory01/data/IDESSA/Model/"

prediction<-list()
obs<-list()
acc <- 0
for (daytime in c("day","night")){
  for (responsetype in c("RA","RR")){
    acc <- acc+1
    model <- get(load(paste0(daytime,"_model_",responsetype,".RData")))
    testData <- get(load(paste0("testData_",daytime,".RData")))
    predVars <- scaleByValue(testData[,row.names(model$scaleParam)],model$scaleParam)
    if (responsetype=="RR"){
      prediction[[acc]] <- predict(model,predVars[testData$P_RT_NRT>0,])
      names(prediction)<-c(names(prediction),paste0(daytime,"_",responsetype))
      obs[[acc]] <- testData$P_RT_NRT[testData$P_RT_NRT>0]
      names(obs) <- c(names(obs),paste0(daytime,"_",responsetype))
    }else{
      prediction[[acc]] <- predict(model,predVars)
      names(prediction)<-c(names(prediction),paste0(daytime,"_",responsetype))
      obs[[acc]] <- testData$YN
      names(obs)<-c(names(obs),paste0(daytime,"_",responsetype))
    }
  }
}
save(prediction,file=paste0(outpath,"predictions.RData"))
save(obs,file=paste0(outpath,"obs.RData"))




