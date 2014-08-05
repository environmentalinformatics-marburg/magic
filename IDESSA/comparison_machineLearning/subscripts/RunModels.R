############################################################################################################
#                                             Run classification models
#RScript to train different classification models
############################################################################################################
############################################################################################################
############################################################################################################
if (tuneThreshold) summaryFunction = "fourStats"
if (!tuneThreshold) summaryFunction = "twoClassSummary"
if (type=="regression")summaryFunction ="defaultSummary"
classProbs=FALSE
if (type=="classification") classProbs=TRUE
if (adaptiveResampling){
  ctrl <- trainControl(index=cvSplits,
                       method="adaptive_cv",
                       summaryFunction = eval(parse(text=summaryFunction)),
                       classProbs = classProbs,
                       adaptive = list(min = 5,
                                       alpha = 0.05,
                                       method = "gls",
                                       complete = TRUE))
}

if (!adaptiveResampling) {
  ctrl <- trainControl(index=cvSplits,
                       method="cv",
                       summaryFunction = eval(parse(text=summaryFunction)),
                       classProbs = classProbs)
}


if (tuneThreshold){
  metric="Dist" #wenn nicht _thres dann "ROC
  maximize = FALSE #when dist is used, then min value is important
}

if (!tuneThreshold & type=="classification"){
  metric="ROC" #wenn nicht _thres dann "ROC
  maximize = TRUE #when dist is used, then min value is important
}

if (type=="regression"){
  metric="RMSE"
  maximize=FALSE
  #metric="Rsquared"
  #maximize=TRUE
}


############################################################################################################
################### DETERMINE TUNING PARAMETERS AND TRAIN WITH BEST PARAMETERS ##########
############################################################################################################
                     
if (any(model=="rf")){
  if (tuneThreshold) {
    method = rf_thres
    tuneGridRF=expand.grid(.mtry = rf_mtry,.threshold=thresholds)
  }
  if (!tuneThreshold) {
    method = "rf"
    tuneGridRF=expand.grid(.mtry =rf_mtry)
  }
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_rf <- train (predictors, 
                   class, 
                   method = method, 
                   trControl = ctrl,
                   tuneGrid=tuneGridRF,
                   ntree=ntree,
                   metric=metric,
                   maximize = maximize #when dist is used, then min value is important
                   )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"), cat("predictor Variables: "),
                 predictorVariables,print(fit_rf),file=paste(resultpath,"/fit_rf.txt",sep=""))
  save(fit_rf,file=paste(resultpath,"/fit_rf.RData",sep=""))
  rm(fit_rf)
  gc()
}



if (any(model=="nnet")){
  
  if (tuneThreshold) {
    method = nnet_thres
    tuneGrid_NNet <- expand.grid(.size = nnet_size,
                                .decay = nnet_decay,.threshold=thresholds)
  }
  if (!tuneThreshold) {
    method = "nnet"
    tuneGrid_NNet <- expand.grid(.size = nnet_size,
                                 .decay = nnet_decay)
  }
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_nnet<-train (predictors, 
                   class, 
                   method = method,
#                   linout = TRUE, 
                   trace = FALSE,
                   trControl = ctrl, 
                   tuneGrid=tuneGrid_NNet,
                   metric=metric,
                   maximize = maximize #when dist is used, then min value is important
                   )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),cat("predictor Variables: "),
                 predictorVariables,print(fit_nnet),file=paste(resultpath,"/fit_nnet.txt",sep=""))
  save(fit_nnet,file=paste(resultpath,"/fit_nnet.RData",sep=""))
  rm(fit_nnet)
  gc()
}
  
if (any(model=="avNNet")){  
  if (tuneThreshold) {
    method = avNNet_thres
    tuneGrid_NNet <- expand.grid(.size = nnet_size,
                                 .decay = nnet_decay,
                                 .bag=FALSE,
                                 .threshold=thresholds)
  }
  if (!tuneThreshold) {
    method = "avNNet"
    tuneGrid_NNet <- expand.grid(.size = nnet_size,
                                 .decay = nnet_decay,
                                 .bag=FALSE)
  }
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_avNNet<-train (predictors, 
                   class, 
                   method = method,
#                   linout = TRUE, 
                   trace = FALSE,
                   trControl = ctrl, 
                   tuneGrid=tuneGrid_NNet,
                   metric=metric,
                   repeats=5,
                   maximize = maximize #when dist is used, then min value is important
  )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),cat("predictor Variables: "),
                 predictorVariables,print(fit_avNNet),file=paste(resultpath,"/fit_avNNet.txt",sep=""))
  save(fit_avNNet,file=paste(resultpath,"/fit_avNNet.RData",sep=""))
  rm(fit_avNNet)
  gc()
}







if (any(model=="svm")){
  
  if (tuneThreshold) {
    method = svm_thres
    tuneGrid_SVM <- expand.grid(.sigma =  eval(parse(text=svm_sigma)),
                                .C=svm_cost,.threshold=thresholds)
  }
  if (!tuneThreshold) {
    method = "svmRadial"
    tuneGrid_SVM <- expand.grid(.sigma =  eval(parse(text=svm_sigma)),
                                .C=svm_cost)
  }
  
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_svm<-train (predictors, 
                   class, 
                   method = method,
                   trControl = c(ctrl), 
                   tuneGrid=tuneGrid_SVM,
                  metric=metric,
                  maximize =maximize #when dist is used, then min value is important
                  )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),cat("predictor Variables: "),
                 predictorVariables,print(fit_svm),file=paste(resultpath,"/fit_svm.txt",sep=""))
  save(fit_svm,file=paste(resultpath,"/fit_svm.RData",sep=""))
  rm(fit_svm)
  gc()
}

############################################################################################################
############################################################################################################
############################################################################################################
save(predictorVariables,file=paste(resultpath,"/predictorVariables.RData",sep=""))
