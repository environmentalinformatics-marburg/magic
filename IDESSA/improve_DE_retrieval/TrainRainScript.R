#train4RainfallScript
library(Rainfall)
library(Rsenal)

#resultpath="/media/hanna/ubt_kdata_0005/Improve_DE_retrieval/results/"
resultpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/results/"
datasetTime<-"day"
responseName<-"RInfo"
sampsize=0.05
if(responseName=="Rain"){
  sampsize=0.25
}

### load rfe and data.table
load(paste0(resultpath,"/RFEModels/rfeModel_",datasetTime,"_",responseName,".Rdata"))
load(paste0(resultpath,"/datatables/datatable_",datasetTime,".RData"))

### get predictors and response to use for training
predictors<-datatable[,rfeModel$optVariables]
#predictors=predictors[,-which(names(predictors)=="jday")]
#predictors<-datatable[,names(varsRfeCV(rfeModel))]
#predictors<-datatable[,4:21] #only spectral
response<-datatable$Radar

rm(datatable)
gc()

### train model
  model<- train4rainfall(predictors,response,
                         tuneGrid=list(.size = seq(2,ncol(predictors),2),.decay=seq(0.01,0.1,0.02)),
                        sampsize=sampsize,scaleVars=TRUE,method="nnet",out=responseName)

#model<- train4rainfall(predictors,response, nnetSize = 10,
#                       nnetDecay=0.05,sampsize=1,scaleVars=TRUE)


### save model
save(model,file=paste0(resultpath,"/trainedModels/trainedModel_",datasetTime,"_",responseName,".Rdata"))

#model<- train4rainfall(predictors,response,
#                       tuneGrid=list(.mtry = c(2,4,6,8,10)),
#                       sampsize=sampsize,scaleVars=TRUE,method="rf")
#save(model,file=paste0(resultpath,"/trainedModel_rf_",datasetTime,"_",responseName,".Rdata"))


