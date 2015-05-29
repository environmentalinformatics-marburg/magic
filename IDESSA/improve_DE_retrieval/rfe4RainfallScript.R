
library(Rainfall)
library(doParallel)
library(caret)
################################################################################
### User adjustments ###########################################################
resultpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results"


for (dt in c("day","twilight","night")){
  datasetTime<-dt
  for (rn in c("Rain","RInfo")){    
  #for (rn in c("RInfo")){  
    responseName<-rn
    sampsize=0.05
    if(responseName=="Rain"){
      sampsize=0.5
    }
    
    ############################################################################
    load(paste0(resultpath,"/datatable_",datasetTime,".RData"))
    
    predictors<-datatable[,4:(ncol(datatable)-1)]
    response<-datatable$Radar
    
    rfeModel<-rfe4rainfall(predictors=predictors,response=response,
                           sampsize=sampsize,out=responseName,
                           nnetSize=c(seq(2,10,2),seq(15,30,5),seq(40,80,10),
                                      seq(100,ncol(predictors),50)),
                           varSize=c(1:10,seq(12,30,2),
                                     seq(35,50,5),seq(60,150,10),
                                     seq(200,ncol(predictors),50)))
    
    save(rfeModel,file=paste0(resultpath,"/rfeModel_",
                              datasetTime,"_",responseName,".Rdata"))
    
    rm(rfeModel,predictors,response)
  }
}