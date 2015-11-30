#train4RainfallScript
library(Rainfall)
library(Rsenal)

#resultpath="/media/hanna/ubt_kdata_0005/Improve_DE_retrieval/results/"
resultpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/results/"
datasetTime<-c("day","night")
responseName<-c("Rain", "RInfo")

for (i in 1:length(datasetTime)){
  for (k in 1:length(responseName)){
    sampsize=0.05
    if(responseName[k]=="Rain"){
      sampsize=0.25
    }
    ###either one of these
    useTexture=FALSE
    useSpecOnly=FALSE
    useOneSD=TRUE
    
    if(sum(useTexture,useSpecOnly,useOneSD)>1){
      stop("specify only one type of predictors")}
    
    ### load rfe and data.table
    if (useTexture||useOneSD){
      load(paste0(resultpath,"/RFEModels/rfeModel_",datasetTime[i],"_",responseName[k],".Rdata"))
    }
    load(paste0(resultpath,"/datatables/datatable_",datasetTime[i],".RData"))
    
    ### get predictors and response to use for training
    if (useSpecOnly){
      predictors<-datatable[,names(datatable)%in%c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                                                   "IR9.7","IR10.8","IR12.0","IR13.4","T0.6_1.6","T6.2_10.8",
                                                   "T7.3_12.0","T8.7_10.8","T10.8_12.0", "T3.9_7.3",
                                                   "T3.9_10.8")]
    }
    if(useTexture){
      predictors<-datatable[,rfeModel$optVariables]
    }
    if (useOneSD){
      predictors<-datatable[,names(varsRfeCV(rfeModel))]
    }
    #predictors=predictors[,-which(names(predictors)=="jday")]
    #predictors<-datatable[,names(varsRfeCV(rfeModel))]
    #predictors<-datatable[,4:21] #only spectral
    response<-datatable$Radar
    
    rm(datatable)
    gc()
    
    ### train model
    model<- train4rainfall(predictors,response,
                           tuneGrid=list(.size = seq(2,ncol(predictors),2),.decay=seq(0.01,0.1,0.02)),
                           sampsize=sampsize,scaleVars=TRUE,method="nnet",out=responseName[k])
    
    #model<- train4rainfall(predictors,response, nnetSize = 10,
    #                       nnetDecay=0.05,sampsize=1,scaleVars=TRUE)
    
    
    ### save model
    if (useTexture){
      save(model,file=paste0(resultpath,"/trainedModels/trainedModel_",datasetTime[i],"_",responseName[k],".Rdata"))
    }
    if (useSpecOnly){
      save(model,file=paste0(resultpath,"/trainedModels/trainedModel_OnlySpec_",datasetTime[i],"_",responseName[k],".Rdata"))
    }
    if (useOneSD){
      save(model,file=paste0(resultpath,"/trainedModels/trainedModel_oneSD_",datasetTime[i],"_",responseName[k],".Rdata"))
    }
  }
}

