rm(list=ls())
library(Rainfall)
library(doParallel)
library(caret)
################################################################################
### User adjustments ###########################################################
resultpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/results"


#for (dt in c("day","night")){
for (dt in c("night")){
  datasetTime<-dt
# for (rn in c("Rain","RInfo")){    
  for (rn in c("Rain","RInfo")){  
    responseName<-rn
    sampsize=0.05
    if(responseName=="Rain"){
      sampsize=0.25#0.25
    }
    
    ############################################################################
    load(paste0(resultpath,"/datatables/datatable_",datasetTime,".RData"))
    
    predictors<-datatable[,4:(ncol(datatable)-1)]
    if (any(names(predictors)=="jday")){
      predictors=predictors[,-which(names(predictors)=="jday")]
    }
    if (any(names(predictors)=="sunzenith")){
      predictors=predictors[,-which(names(predictors)=="sunzenith")]
    }
    response<-datatable$Radar
    
    rfeModel<-rfe4rainfall(predictors=predictors,response=response,
                           sampsize=sampsize,out=responseName,
                           method="nnet",
                          tuneGrid = list(.size = c(seq(2,10,2),seq(15,30,5),seq(40,80,10),
                                                    seq(100,ncol(predictors),50)), .decay =0.05),
                           varSize=c(1:10,seq(12,30,2),
                                     seq(35,50,5),seq(60,150,10),
                                     seq(200,ncol(predictors),50)))
    
    save(rfeModel,file=paste0(resultpath,"/RFEModels/rfeModel_",
                              datasetTime,"_",responseName,".Rdata"))
    
    rm(rfeModel,predictors,response)
  }
}