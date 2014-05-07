if (any(model=="rf")){
  load(paste(resultpath,"/prediction_rf.RData",sep=""))
}
if (any(model=="mlp")){
  load(paste(resultpath,"/prediction_mlp.RData",sep=""))
}
if (any(model=="nnet")){
  load(paste(resultpath,"/prediction_nnet.RData",sep=""))
}
if (any(model=="svm")){
  load(paste(resultpath,"/prediction_svm.RData",sep=""))
}
load(paste(resultpath,"/predictorVariables.RData",sep=""))
load(paste(resultpath,"/testing.RData",sep=""))

##################################################################################################################
#                                         ROC
##################################################################################################################

if (any(model=="rf")){
  obs=as.character(prediction_rf$observed)
  obs[obs=="rain"]=1
  obs[obs=="norain"]=0
  probRF=prediction_rf$predicted_prob$rain
  rocRF=rocFromTab(probRF,obs,plot=FALSE)
}
if (any(model=="mlp")){
  obs=as.character(prediction_mlp$observed)
  obs[obs=="rain"]=1
  obs[obs=="norain"]=0
  probMLP=prediction_mlp$predicted_prob$rain
  rocMLP=rocFromTab(probMLP,obs,plot=FALSE)
}  
if (any(model=="nnet")){
  obs=as.character(prediction_nnet$observed)
  obs[obs=="rain"]=1
  obs[obs=="norain"]=0
  probNNET=prediction_nnet$predicted_prob$rain
  rocNNET=rocFromTab(probNNET,obs,plot=FALSE)
}
if (any(model=="svm")){
  obs=as.character(prediction_svm$observed)
  obs[obs=="rain"]=1
  obs[obs=="norain"]=0
  probSVM=prediction_svm$predicted_prob$rain
  rocSVM=rocFromTab(probSVM,obs,plot=FALSE)
}

if (length(model)==4) color=c("black","red","blue","green","grey")
if (length(model)==3) color=c("black","red","blue","grey")
if (length(model)==2) color=c("black","red","grey")
if (length(model)==1) color=c("black","grey")

legendnames=c()
for (i in 1:length(model)){
  legendnames=c(legendnames,paste(toupper(model[i]),round(eval(parse(text=paste("roc",toupper(model[i]),sep="")))[[1]],2)))
}
pdf(paste(resultpath,"/prediction_roc.pdf",sep=""))
plot(eval(parse(text=paste("roc",toupper(model[1]),sep="")))[[2]][,2],
     eval(parse(text=paste("roc",toupper(model[1]),sep="")))[[2]][,3],
     type="l",xlab="False positive rate",ylab="True positive rate",xlim=c(0,1),ylim=c(0,1),col=color[1])
  for (i in 2:length(model)){
      lines(eval(parse(text=paste("roc",toupper(model[i]),sep="")))[[2]][,2],
          eval(parse(text=paste("roc",toupper(model[i]),sep="")))[[2]][,3],col=color[i])
  }
  lines(c(0,1),c(0,1),col="grey50")
  legend("bottomright",col=color,lty=c(1),legend=c(legendnames, "Random 0.5"),bty="n")
dev.off()
##################################################################################################################
#                                                 CROSSTABS
##################################################################################################################
if (any(model=="mlp")){
  write.csv(table(prediction_mlp$observed,prediction_mlp$prediction),file=paste(resultpath,"/crosstabMLP.csv",sep=""))
}
if (any(model=="rf")){
  write.csv(table(prediction_rf$observed,prediction_rf$prediction),file=paste(resultpath,"/crosstabRF.csv",sep=""))
}
if (any(model=="nnet")){
  write.csv(table(prediction_nnet$observed,prediction_nnet$prediction),file=paste(resultpath,"/crosstabNNET.csv",sep=""))
}
if (any(model=="svm")){
  write.csv(table(prediction_svm$observed,prediction_svm$prediction),file=paste(resultpath,"/crosstabSVM.csv",sep=""))
}

pdf(paste(resultpath,"/prediction_crosstab.pdf",sep=""))
if (length(model)>2) par(mfrow=c(2,2))
if (any(model=="rf")){
  plot(prediction_rf$observed,prediction_rf$prediction,main="RF",xlab="observed",ylab="predicted")
}
if (any(model=="mlp")){
  plot(prediction_mlp$observed,prediction_mlp$prediction,main="MLP",xlab="observed",ylab="predicted")
}
if (any(model=="nnet")){
  plot(prediction_nnet$observed,prediction_nnet$prediction,main="NNET",xlab="observed",ylab="predicted")
}
if (any(model=="svm")){
  plot(prediction_svm$observed,prediction_svm$prediction,main="SVM",xlab="observed",ylab="predicted")
}
dev.off()

###############################################################################################################
# Boxplot: Rain rate of F alse Negatives and True Positives

pdf(paste(resultpath,"/RainRateOfFalseNegatives.pdf",sep=""))
for(i in 1:length(model)){
  FalseNoRainPrediction<-eval(parse(text=paste("prediction_",model[i],sep="")))$prediction[eval(parse(text=paste("prediction_",model[i],sep="")))$prediction=="norain"&eval(parse(text=paste("prediction_",model[i],sep="")))$observed=="rain"]
  ObsFalseNoRainPrediction<-testing$Rain[eval(parse(text=paste("prediction_",model[i],sep="")))$prediction=="norain"&eval(parse(text=paste("prediction_",model[i],sep="")))$observed=="rain"]

  TrueRainPrediction<-eval(parse(text=paste("prediction_",model[i],sep="")))$prediction[eval(parse(text=paste("prediction_",model[i],sep="")))$prediction=="rain"&eval(parse(text=paste("prediction_",model[i],sep="")))$observed=="rain"]
  ObsTrueRainPrediction<-testing$Rain[eval(parse(text=paste("prediction_",model[i],sep="")))$prediction=="rain"&eval(parse(text=paste("prediction_",model[i],sep="")))$observed=="rain"]

  boxplot(ObsFalseNoRainPrediction,ObsTrueRainPrediction,ylab="Rain Rate",
        names=c(paste("False Negatives (N= ",length(ObsFalseNoRainPrediction),")",sep=""),
                paste("True Positives (N= ",length(ObsTrueRainPrediction),")",sep="")),outline=FALSE,main=model[i])
}
dev.off()


