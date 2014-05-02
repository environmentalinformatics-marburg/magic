############################################################################################################
#                                             Run classification models
#RScript to train different classification models
############################################################################################################
############################################################################################################
############################################################################################################
ctrl <- trainControl(index=cvSplits,
                     summaryFunction = twoClassSummary,
                     classProbs = TRUE,
                     savePredictions = TRUE)
############################################################################################################
################### DETERMINE TUNING PARAMETERS AND TRAIN WITH BEST PARAMETERS ##########
############################################################################################################
                     

if (any(model=="rf")){
  ptm <- proc.time()
  fit_rf <- train (predictors, 
                   class, 
                   method = "rf", 
                   trControl = ctrl,
                   tuneGrid=expand.grid(.mtry = c(2:length(predictors))),
                   ntree=ntree,
                   preProcess = c("center", "scale"),
                   metric="ROC"
                   )
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"), cat("predictor Variables: "),predictorVariables,print(fit_rf),file=paste(resultpath,"/fit_rf.txt",sep=""))
  save(fit_rf,file=paste(resultpath,"/fit_rf.RData",sep=""))
  rm(fit_rf)
}

if (any(model=="mlp")){
  tuneGrid_MLP <- expand.grid(.size = c(2:length(predictors), 2:length(predictors)), 
                              .decay = c(0, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.075, 0.1))
  ptm <- proc.time()
  fit_mlp <- train (predictors, 
              class, 
              method = "mlpWeightDecay",
              trControl = ctrl, 
#              learnFuncParams=c(0.2,0,0,0),
              tuneGrid=tuneGrid_MLP,
              preProcess = c("center", "scale"),
              metric="ROC")
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"), cat("predictor Variables: "),predictorVariables,print(fit_mlp),file=paste(resultpath,"/fit_mlp.txt",sep=""))
  save(fit_mlp,file=paste(resultpath,"/fit_mlp.RData",sep=""))
  rm(fit_mlp)
}


if (any(model=="nnet")){
  tuneGrid_NNet <- expand.grid(.size = c(2:length(predictors)),
                               .decay = c(0, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.075, 0.1))
  ptm <- proc.time()
  fit_nnet<-train (predictors, 
                   class, 
                   method = "nnet",
                   trControl = ctrl, 
                   tuneGrid=tuneGrid_NNet,
                   preProcess = c("center", "scale"),
                   metric="ROC")
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),cat("predictor Variables: "),predictorVariables,print(fit_nnet),file=paste(resultpath,"/fit_nnet.txt",sep=""))
  save(fit_nnet,file=paste(resultpath,"/fit_nnet.RData",sep=""))
  rm(fit_nnet)
}
  
  
if (any(model=="svm")){
  tuneGrid_SVM <- expand.grid(.sigma =  sigest(as.matrix(predictors))[2],
                              .C=c(0.25, 0.50, 1.00, 2.00, 4.00, 8.00, 16.00, 32.00, 64.00, 128.00))
  ptm <- proc.time()
  fit_svm<-train (predictors, 
                   class, 
                   method = "svmRadial",
                   trControl = ctrl, 
                   tuneGrid=tuneGrid_SVM,
                   preProcess = c("center", "scale"),
                  metric="ROC")
  ptm <- proc.time() - ptm
  capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),cat("predictor Variables: "),predictorVariables,print(fit_svm),file=paste(resultpath,"/fit_svm.txt",sep=""))
  save(fit_svm,file=paste(resultpath,"/fit_svm.RData",sep=""))
  rm(fit_svm)
}

############################################################################################################
############################################################################################################
############################################################################################################
save(predictorVariables,file=paste(resultpath,"/predictorVariables.RData",sep=""))
