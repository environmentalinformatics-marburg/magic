
#abb tuning parameters- model
#abb ob RMSE ~ number of trees bei 1000 noch improved

if (any(model=="rf")){
load(paste(resultpath,"/fit_rf.RData",sep=""))
}
if (any(model=="nnet")){
load(paste(resultpath,"/fit_nnet.RData",sep=""))
}
if (any(model=="mlp")){
load(paste(resultpath,"/fit_mlp.RData",sep=""))
}
if (any(model=="svm")){
load(paste(resultpath,"/fit_svm.RData",sep=""))
}

pdf(paste(resultpath,"/TuningStudy.pdf",sep=""))
if (any(model=="rf")){
  plot(fit_rf,main="rf")
}
if (any(model=="mlp")){
  plot(fit_mlp,main="mlp")
}
if (any(model=="nnet")){
  plot(fit_nnet,main="nnet")
}
if (any(model=="svm")){
  plot(fit_svm,main="svm")
}
dev.off()



##########################
if (tuneThreshold) {
pdf(paste(resultpath,"/TuningStudy_Cutoff.pdf",sep=""))
if (any(model=="rf")){
  cutoffplot(fit_rf)
}
if (any(model=="mlp")){
  cutoffplot(fit_mlp)
}
if (any(model=="nnet")){
  cutoffplot(fit_nnet)
}
if (any(model=="svm")){
  cutoffplot(fit_svm)
}
dev.off()
}

