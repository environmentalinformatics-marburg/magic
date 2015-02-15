library(caret)
library(doParallel)


responseName="Rain"#,RInfo"
time="day"#"inb" "night"
sampsize=0.1#,0.05

datapath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results"
functionpath="home/hmeyer/Improve_DE_retrieval/functions/trainFuctions"


################################################################################
load(paste0(datapath,"/datatable_",time,".RData"))


cl <- makeCluster(detectCores())
registerDoParallel(cl)

for (i in list.files(functionpath)){
  source(paste(functionpath,"/",i,sep=""))
}
nnetFuncs <- caretFuncs #Default caret functions

################################################################################
### Rainfall area
################################################################################
if (responseName=="RInfo"){
  #select 5% of pixels for feature selection
  #Backwards Feature Selection
  
  response<- datatable$Radar
  response[response>0.06]="Rain"
  response[response<=0.06]="NoRain"  
  
  set.seed(20)
  samples<-createDataPartition(response,
                               p = sampsize,list=FALSE)
  
  response=response[samples]
  response=as.factor(response)
  response=factor(response,levels=c("Rain","NoRain"))
  predictors <- datatable[samples,4:(ncol(datatable)-1)]
  rm(datatable)
  gc()
  predictors=scale(predictors)
  set.seed(20)
  cvSplits <- createFolds(response, k = 10,returnTrain=TRUE)
  
  ### Training Settings ##########################################################
  

  
  nnetFuncs$summary <- twoClassSummary
  
  
  tctrl <- trainControl(
    method="cv",
    classProbs =TRUE)
  
  rctrl <- rfeControl(index=cvSplits,
                      functions = nnetFuncs,
                      method="cv",
                      returnResamp = "all")
  
  ### Feature selection ##########################################################
  rfeModel <- rfe(predictors,
                  response,
                  sizes = c(1:5,seq(10,ncol(predictors),10)),
                  method = "nnet",
                  rfeControl = rctrl,
                  trControl=tctrl,
                  #tuneLength=2,
                  tuneGrid=expand.grid(.size = c(2,8,20,40,80),
                                       .decay = 0.05),
                  metric="ROC",
                  maximize=TRUE)
  
  save(rfeModel,file=paste0(datapath,"/rfe_",time,"_",responseName,".RData"))
}


################################################################################
### Rainfall rate
################################################################################
if (responseName=="Rain"){
  #select 10% of raining pixels for feature selection
  
  
  datatable<-datatable[datatable$Radar>0.06,]
  response<- datatable$Radar
  
  
  set.seed(20)
  samples<-createDataPartition(response,
                               p = sampsize,list=FALSE)
  predictors=datatable[samples,4:(ncol(datatable)-1)]
  response=response[samples]
  rm(datatable)
  gc()
  predictors=scale(predictors)
  
  set.seed(20)
  cvSplits <- createFolds(response, k = 10,returnTrain=TRUE)
  
  ### Training Settings ##########################################################
  nnetFuncs <- caretFuncs #Default caret functions
  tctrl <- trainControl(method="cv")
  rctrl <- rfeControl(index=cvSplits,
                      functions = nnetFuncs,
                      method="cv",
                      returnResamp = "all")
  
  ### Feature selection ##########################################################
  
  rfeModel <- rfe(predictors,
                  response,
                  sizes = c(1:5,seq(10,ncol(predictors),10)),
                  method = "nnet",
                  rfeControl = rctrl,
                  trControl=tctrl,
                  tuneGrid=expand.grid(.size = c(2,8,20,40,80),
                                       .decay = 0.05),
                  metric="RMSE",
                  maximize=FALSE)
  
  
  save(rfeModel,file=paste0(datapath,"/rfe_",time,"_",responseName,".RData"))
}

#######

stopCluster(cl)
