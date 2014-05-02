
#abb tuning parameters- model
#abb ob RMSE ~ number of trees bei 1000 noch improved


load(paste(resultpath,"/fit_rf.RData",sep=""))
load(paste(resultpath,"/fit_nnet.RData",sep=""))
load(paste(resultpath,"/fit_mlp.RData",sep=""))
load(paste(resultpath,"/fit_svm.RData",sep=""))


pdf(paste(resultpath,"/TuningStudy.pdf",sep=""))
plot(fit_rf,main="rf")
plot(fit_mlp,main="mlp")
plot(fit_nnet,main="nnet")
plot(fit_svm,main="svm")
dev.off()