
library(Rainfall)
library(doParallel)
library(caret)
################################################################################
### User adjustments ###########################################################
resultpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results"
datasetTime<-"day"
responseName<-"Rain"
sampsize=1#0.05 for rinfo, 1 for rain


################################################################################
load(paste0(resultpath,"/datatable_",datasetTime,".RData"))

predictors<-datatable[,4:(ncol(datatable)-1)]
response<-datatable$Radar
#if (responseName=="RInfo"){
#response[datatable$Radar<=0.06]="NoRain"
#response[datatable$Radar>0.06]="Rain"
#}


rfeModel<-rfe4rainfall(predictors=predictors,response=response,
                       sampsize=sampsize,out=responseName,
                       nnetSize=c(seq(2,10,2),seq(20,ncol(predictors),20)),
                       varSize=c(1:5,seq(10,ncol(predictors),5)))



save(rfeModel,file=paste0(resultpath,"/rfeModel_",datasetTime,"_",responseName,".Rdata"))
