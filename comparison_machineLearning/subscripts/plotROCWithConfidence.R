

ctrl <- trainControl(index=cvSplits,
                     method="cv",
                     summaryFunction = eval(parse(text=summaryFunction)),
                     classProbs = classProbs,
                     savePredictions=TRUE)


##########################################################
# Plot ROC with confidence intervals
##########################################################
library(ROCR)
if (response=="RInfo"){
  pdf(paste(resultpath,"/ROC_training.pdf",sep=""))
  if (any(model=="rf")){
    ###fit single random forest with saved predictions
    load(paste(resultpath,"/fit_rf.RData",sep=""))
    if(useSeeds) set.seed(20)
    fit_rf_single <- train (predictors, 
                            class, 
                            method = "rf", 
                            trControl = ctrl,
                            tuneGrid=expand.grid(.mtry =fit_rf$bestTune$mtry),
                            ntree=ntree,
                            metric=metric,
                            maximize=maximize
    )
    
    obs=as.numeric(fit_rf_single$pred$obs)
    obs[as.character(fit_rf_single$pred$obs)=="norain"]=0
    obs[as.character(fit_rf_single$pred$obs)=="rain"]=1
    
    predframe=list()
    for (i in 1:length(fit_rf_single$control$indexOut)){
      predframe[[i]]=fit_rf_single$pred$rain[fit_rf_single$control$indexOut[[i]]]
    }
    
    obsframe=list()
    for (i in 1:length(fit_rf_single$control$indexOut)){
      obsframe[[i]]=obs[fit_rf_single$control$indexOut[[i]]]
    }
    
    pred <- prediction(predframe,obsframe)
    perf_rf <- performance(pred, "tpr", "fpr") 
    auc_rf=mean(unlist(performance(pred, measure="auc")@y.values))
    save(perf_rf,file=paste(resultpath,"/perf_rf.RData",sep=""))
    plot(perf_rf,avg="vertical",spread.estimate="stderror",col="black",spread.scale=2)
  }
  ###fit single nnet with saved predictions
  if (any(model=="nnet")){
  load(paste(resultpath,"/fit_nnet.RData",sep=""))
  if(useSeeds) set.seed(20)
  fit_nnet_single <- train (predictors, 
                          class, 
                          method = "nnet", 
                          trControl = ctrl,
                          tuneGrid=expand.grid(.size =fit_nnet$bestTune$size,.decay =fit_nnet$bestTune$decay),
                          ntree=ntree,
                          metric=metric,
                          maximize=maximize
  )
  
  obs=as.numeric(fit_nnet_single$pred$obs)
  obs[as.character(fit_nnet_single$pred$obs)=="norain"]=0
  obs[as.character(fit_nnet_single$pred$obs)=="rain"]=1
  
  predframe=list()
  for (i in 1:length(fit_nnet_single$control$indexOut)){
    predframe[[i]]=fit_nnet_single$pred$rain[fit_nnet_single$control$indexOut[[i]]]
  }
  
  obsframe=list()
  for (i in 1:length(fit_nnet_single$control$indexOut)){
    obsframe[[i]]=obs[fit_nnet_single$control$indexOut[[i]]]
  }
  
  pred <- prediction(predframe,obsframe)
  perf_nnet <- performance(pred, "tpr", "fpr") 
  auc_nnet=mean(unlist(performance(pred, measure="auc")@y.values))
  save(perf_nnet,file=paste(resultpath,"/perf_nnet.RData",sep=""))
  plot(perf_nnet,avg="vertical",spread.estimate="stderror",add=TRUE,col="red",spread.scale=2)
}

###fit single svm with saved predictions
if (any(model=="svm")){
  load(paste(resultpath,"/fit_svm.RData",sep=""))
  if(useSeeds) set.seed(20)
    fit_svm_single <- train (predictors, 
                          class, 
                          method = "svmRadial", 
                          trControl = ctrl,
                          tuneGrid=expand.grid(.sigma =fit_svm$bestTune$sigma,.C =fit_svm$bestTune$C),
                          ntree=ntree,
                          metric=metric,
                          maximize=maximize
    )

  obs=as.numeric(fit_svm_single$pred$obs)
  obs[as.character(fit_svm_single$pred$obs)=="norain"]=0
  obs[as.character(fit_svm_single$pred$obs)=="rain"]=1

  predframe=list()
  for (i in 1:length(fit_svm_single$control$indexOut)){
    predframe[[i]]=fit_svm_single$pred$rain[fit_svm_single$control$indexOut[[i]]]
  }

  obsframe=list()
  for (i in 1:length(fit_svm_single$control$indexOut)){
    obsframe[[i]]=obs[fit_svm_single$control$indexOut[[i]]]
  }

  pred <- prediction(predframe,obsframe)
  perf_svm <- performance(pred, "tpr", "fpr") 
  auc_svm=mean(unlist(performance(pred, measure="auc")@y.values))
  save(perf_svm,file=paste(resultpath,"/perf_svm.RData",sep=""))
  plot(perf_svm,avg="vertical",spread.estimate="stderror",add=TRUE,col="blue",spread.scale=2)
  }  
}
if (response=="RInfo"){ 
  lines(c(0,1),c(0,1),col="grey50")
  legendnames=c()
  for (i in 1:length(model)){
    legendnames=c(legendnames,paste(toupper(model[i]),round(eval(parse(text=paste("auc_",model[i],sep=""))),2)))
  }
  legend("bottomright",col=c("black","red","blue","grey50"),lty=c(1),legend=c(legendnames, "Random 0.5"),bty="n")
  
  dev.off()
}