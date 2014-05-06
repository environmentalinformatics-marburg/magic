

load(paste(resultpath,"/testing.RData",sep=""))
if (any(model=="rf")){
  load(paste(resultpath,"/fit_rf.RData",sep=""))
}
if (any(model=="mlp")){
  load(paste(resultpath,"/fit_mlp.RData",sep=""))
}
if (any(model=="nnet")){
  load(paste(resultpath,"/fit_nnet.RData",sep=""))
}
if (any(model=="svm")){
  load(paste(resultpath,"/fit_svm.RData",sep=""))
}
load(paste(resultpath,"/predictorVariables.RData",sep=""))


####################################### PREDICT #######################################
testing_predictors <-testing[,names(testing) %in%  predictorVariables]
testing_observed<-eval(parse(text=paste("testing$",response,sep="")))
if (any(model=="rf")){
  prediction_rf=data.frame("prediction"=predict (fit_rf,testing_predictors))
  prediction_rf$predicted_prob <- predict (fit_rf,testing_predictors,type="prob")
  prediction_rf$observed=testing_observed
  save(prediction_rf,file=paste(resultpath,"/prediction_rf.RData",sep=""))
  rm(prediction_rf)
}
if (any(model=="mlp")){
  prediction_mlp=data.frame("prediction"=predict (fit_mlp,testing_predictors))
  prediction_mlp$predicted_prob <- predict (fit_mlp,testing_predictors,type="prob")
  prediction_mlp$observed=testing_observed
  save(prediction_mlp,file=paste(resultpath,"/prediction_mlp.RData",sep=""))
  rm(prediction_mlp)
}
if (any(model=="nnet")){
  prediction_nnet=data.frame("prediction"=predict (fit_nnet,testing_predictors))
  prediction_nnet$predicted_prob <- predict (fit_nnet,testing_predictors,type="prob")
  prediction_nnet$observed=testing_observed
  save(prediction_nnet,file=paste(resultpath,"/prediction_nnet.RData",sep=""))
  rm(prediction_nnet)
}
if (any(model=="svm")){
  prediction_svm=data.frame("prediction"=predict (fit_svm,testing_predictors))
  prediction_svm$predicted_prob <- predict (fit_svm,testing_predictors,type="prob")
  prediction_svm$observed=testing_observed
  save(prediction_svm,file=paste(resultpath,"/prediction_svm.RData",sep=""))
  rm(prediction_svm)
}
####################################### VALIDATE #######################################

#wo unterschätzt er? da wo regenrate <??
