
load(paste(resultpath,"/prediction_rf.RData",sep=""))
load(paste(resultpath,"/prediction_mlp.RData",sep=""))
load(paste(resultpath,"/prediction_nnet.RData",sep=""))
load(paste(resultpath,"/prediction_svm.RData",sep=""))
load(paste(resultpath,"/predictorVariables.RData",sep=""))

##################################################################################################################
#                                         ROC
##################################################################################################################
obs=as.character(prediction_svm$observed)
obs[obs=="rain"]=1
obs[obs=="norain"]=0

probRF=prediction_rf$predicted_prob$rain
probMLP=prediction_mlp$predicted_prob$rain
probNNET=prediction_nnet$predicted_prob$rain
probSVM=prediction_svm$predicted_prob$rain

rocRF=rocFromTab(probRF,obs,plot=FALSE)
rocMLP=rocFromTab(probMLP,obs,plot=FALSE)
rocNNET=rocFromTab(probNNET,obs,plot=FALSE)
rocSVM=rocFromTab(probSVM,obs,plot=FALSE)

pdf(paste(resultpath,"/prediction_roc.pdf",sep=""))
plot(rocRF[[2]][,2],rocRF[[2]][,3],type="l",xlab="False positive rate",ylab="True positive rate",xlim=c(0,1),ylim=c(0,1))
lines(rocMLP[[2]][,2],rocMLP[[2]][,3],col="red")
lines(rocNNET[[2]][,2],rocNNET[[2]][,3],col="blue")
lines(rocSVM[[2]][,2],rocSVM[[2]][,3],col="green")
lines(c(0,1),c(0,1),col="grey50")
legend("bottomright",col=c("black","red","blue","green","grey"),lty=c(1),
       legend=c(paste("RF",round(rocRF[[1]],2)),paste("MLP",round(rocMLP[[1]],2)),
                                                     paste("NNET",round(rocNNET[[1]],2)),paste("SVM",round(rocSVM[[1]],2)),
                "Random 0.5"),bty="n")
dev.off()
##################################################################################################################
#                                                 CROSSTABS
##################################################################################################################
write.csv(table(prediction_mlp$observed,prediction_mlp$prediction),file=paste(resultpath,"/crosstabMLP.csv",sep=""))
write.csv(table(prediction_rf$observed,prediction_rf$prediction),file=paste(resultpath,"/crosstabRF.csv",sep=""))
write.csv(table(prediction_nnet$observed,prediction_nnet$prediction),file=paste(resultpath,"/crosstabNNET.csv",sep=""))
write.csv(table(prediction_svm$observed,prediction_svm$prediction),file=paste(resultpath,"/crosstabSVM.csv",sep=""))

pdf(paste(resultpath,"/prediction_crosstab.pdf",sep=""))
par(mfrow=c(2,2))
plot(prediction_rf$observed,prediction_rf$prediction,main="RF",xlab="observed",ylab="predicted")
plot(prediction_mlp$observed,prediction_mlp$prediction,main="MLP",xlab="observed",ylab="predicted")
plot(prediction_nnet$observed,prediction_nnet$prediction,main="NNET",xlab="observed",ylab="predicted")
plot(prediction_svm$observed,prediction_svm$prediction,main="SVM",xlab="observed",ylab="predicted")
dev.off()

#plotObsVsPred or plotClassProbs ??
