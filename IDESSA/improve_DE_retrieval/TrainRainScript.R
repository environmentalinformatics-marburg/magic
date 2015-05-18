#train4RainfallScript
library(Rainfall)
library(Rsenal)

resultpath="/media/hanna/ubt_kdata_0005/improve_DE_retrieval/"
datasetTime<-"day"
responseName<-"Rain"
sampsize=0.05
if(responseName=="Rain"){
  sampsize=1
}

### load rfe and data.table
load(paste0(resultpath,"/rfeModel_",datasetTime,"_",responseName,".Rdata"))
load(paste0(resultpath,"/datatable_",datasetTime,".RData"))

### get predictors and response to use for training
predictors<-datatable[,rfeModel$optVariables]
#predictors<-datatable[,names(varsRfeCV(rfeModel))]
#predictors<-datatable[,4:21] #only spectral
response<-datatable$Radar

rm(datatable)
gc()

### train model
  model<- train4rainfall(predictors,response, nnetSize = seq(2,ncol(predictors),2),
                     nnetDecay=seq(0.01,0.1,0.02),sampsize=sampsize,scaleVars=TRUE)


### save model
save(model,file=paste0(resultpath,"/trainedModel_",datasetTime,"_",responseName,".Rdata"))



