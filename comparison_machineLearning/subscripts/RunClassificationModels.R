############################################################################################################
#                                             Run classification models
#RScript to train different classification models
############################################################################################################
############################################################################################################
############################################################################################################
if (tuneThreshold) summaryFunction = "fourStats"
if (!tuneThreshold) summaryFunction = "twoClassSummary"
ctrl <- trainControl(index=cvSplits,
                     summaryFunction = eval(parse(text=summaryFunction)),
                     classProbs = TRUE,
                     savePredictions = TRUE)

if (tuneThreshold){
  metric="Dist" #wenn nicht _thres dann "ROC
  maximize = FALSE #when dist is used, then min value is important
}

if (!tuneThreshold){
  metric="ROC" #wenn nicht _thres dann "ROC
  maximize = TRUE #when dist is used, then min value is important
}

if(!balance) factorprint="no balancing"
if(balance) factorprint=paste("Balancing= #MinClassPixel * ", factor)




############################################################################################################
################### DETERMINE TUNING PARAMETERS AND TRAIN WITH BEST PARAMETERS ##########
############################################################################################################
                     
if (any(model=="rf")){
  if (tuneThreshold) {
    method = rf_thres
    tuneGridRF=expand.grid(.mtry = c(2:length(predictors)),.threshold=seq(.1, .99, 0.1))
  }
  if (!tuneThreshold) {
    method = "rf"
    tuneGridRF=expand.grid(.mtry = c(2:length(predictors)))
  }
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_rf <- train (predictors, 
                   class, 
                   method = method, 
                   trControl = ctrl,
                   tuneGrid=tuneGridRF,
                   ntree=ntree,
                   metric=metric, #wenn nicht _thres dann "ROC
                   maximize = maximize #when dist is used, then min value is important
                   )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"), factorprint, cat("predictor Variables: "),predictorVariables,print(fit_rf),file=paste(resultpath,"/fit_rf.txt",sep=""))
  save(fit_rf,file=paste(resultpath,"/fit_rf.RData",sep=""))
  rm(fit_rf)
}

if (any(model=="mlp")){
  
  if (tuneThreshold) {
    method = mlp_thres
    tuneGridMLP=expand.grid(.size = c(2:length(predictors), 2:length(predictors)), 
                            .decay = c(0, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.075, 0.1),.threshold=seq(.1, .99, 0.1))
  }
  if (!tuneThreshold) {
    method = "mlpWeightDecay"
    tuneGrid_MLP <- expand.grid(.size = c(2:length(predictors), 2:length(predictors)), 
                                .decay = c(0, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.075, 0.1))
  }
  
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_mlp <- train (predictors, 
              class, 
              method = method,
              trControl = ctrl, 
#              learnFuncParams=c(0.2,0,0,0),
              tuneGrid=tuneGrid_MLP,
              metric=metric,
              maximize = maximize #when dist is used, then min value is important
)
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"), factorprint,cat("predictor Variables: "),predictorVariables,print(fit_mlp),file=paste(resultpath,"/fit_mlp.txt",sep=""))
  save(fit_mlp,file=paste(resultpath,"/fit_mlp.RData",sep=""))
  rm(fit_mlp)
}


if (any(model=="nnet")){
  
  if (tuneThreshold) {
    method = nnet_thres
    tuneGrid_NNet <- expand.grid(.size = c(2:length(predictors)),
                                .decay = c(0, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.075, 0.1),.threshold=seq(.1, .99, 0.075))
  }
  if (!tuneThreshold) {
    method = "nnet"
    tuneGrid_NNet <- expand.grid(.size = c(2:length(predictors)),
                                 .decay = c(0, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.075, 0.1))
  }
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_nnet<-train (predictors, 
                   class, 
                   method = method,
                   trControl = ctrl, 
                   tuneGrid=tuneGrid_NNet,
                   metric=metric,
                   maximize = maximize #when dist is used, then min value is important
                   )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),factorprint,cat("predictor Variables: "),predictorVariables,print(fit_nnet),file=paste(resultpath,"/fit_nnet.txt",sep=""))
  save(fit_nnet,file=paste(resultpath,"/fit_nnet.RData",sep=""))
  rm(fit_nnet)
}
  
  
if (any(model=="svm")){
  
  if (tuneThreshold) {
    method = svm_thres
    tuneGrid_SVM <- expand.grid(.sigma =  sigest(as.matrix(predictors))[2],
                                .C=c(0.25, 0.50, 1.00, 2.00, 4.00, 8.00, 16.00, 32.00, 64.00, 128.00),.threshold=seq(.1, .99, 0.1))
  }
  if (!tuneThreshold) {
    method = "svmRadial"
    tuneGrid_SVM <- expand.grid(.sigma =  sigest(as.matrix(predictors))[2],
                                .C=c(0.25, 0.50, 1.00, 2.00, 4.00, 8.00, 16.00, 32.00, 64.00, 128.00))
  }
  
  
  
  ptm <- proc.time()
  if(useSeeds) set.seed(20)
  fit_svm<-train (predictors, 
                   class, 
                   method = method,
                   trControl = c(ctrl, 
                                 allowParallel = FALSE), 
                   tuneGrid=tuneGrid_SVM,
                  metric=metric,
                  maximize =maximize #when dist is used, then min value is important
                  )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),factorprint,cat("predictor Variables: "),predictorVariables,print(fit_svm),file=paste(resultpath,"/fit_svm.txt",sep=""))
  save(fit_svm,file=paste(resultpath,"/fit_svm.RData",sep=""))
  rm(fit_svm)
}

############################################################################################################
############################################################################################################
############################################################################################################
save(predictorVariables,file=paste(resultpath,"/predictorVariables.RData",sep=""))
