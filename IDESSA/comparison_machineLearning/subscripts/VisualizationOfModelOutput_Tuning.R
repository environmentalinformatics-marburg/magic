
#abb tuning parameters- model
#abb ob RMSE ~ number of trees bei 1000 noch improved

predictionFiles=paste0(resultpath,"/",Filter(function(x) grepl("RData", x), list.files(resultpath,pattern="fit_")))
for (i in predictionFiles){
  load(i)
}


pdf(paste(resultpath,"/TuningStudy.pdf",sep=""))
if (any(model=="rf")){
  plot(fit_rf,main="rf")
}
if (any(model=="nnet")){
  plot(fit_nnet,main="nnet")
}
if (any(model=="svm")){
  plot(fit_svm,main="svm")
}
if (any(model=="avNNet")){
  plot(fit_avNNet,main="avNNet")
}
dev.off()
####Tuning study b
if (tuneThreshold){
  pdf(paste(resultpath,"/TuningStudy_b.pdf",sep=""))
  if (any(model=="rf")&tuneThreshold){
    plot(fit_rf$results$mtry[fit_rf$results$threshold==fit_rf$results$threshold[1]],
         fit_rf$results$ROC[fit_rf$results$threshold==fit_rf$results$threshold[1]],
         type="l",xlab="#Randomly Selected Predictors",ylab="AUC",main="RF")
  }
  if (any(model=="nnet")&tuneThreshold){
    col=gray.colors(length(unique(fit_nnet$results$decay)),start = 0, end = 0.8)
    k=1
    i=unique(fit_nnet$results$decay)[1]
    plot(fit_nnet$results$size[fit_nnet$results$threshold==fit_nnet$results$threshold[1]&fit_nnet$results$decay==i],
         fit_nnet$results$ROC[fit_nnet$results$threshold==fit_nnet$results$threshold[1]&fit_nnet$results$decay==i],
         type="l",xlab="#Hidden Units",ylab="AUC",main="NNET",col=col[k],
         ylim=c(min(fit_nnet$results$ROC)-0.01,max(fit_nnet$results$ROC)))
    for (i in unique(fit_nnet$results$decay)[-1]){
      k=k+1
      lines(fit_nnet$results$size[fit_nnet$results$threshold==fit_nnet$results$threshold[1]&fit_nnet$results$decay==i],
            fit_nnet$results$ROC[fit_nnet$results$threshold==fit_nnet$results$threshold[1]&fit_nnet$results$decay==i],col=col[k])
    }
    legend("bottomright",legend=unique(fit_nnet$results$decay),col=col,lty=1,cex=0.8,ncol=2)
  }
  if (any(model=="svm")&tuneThreshold){
    plot(fit_svm$results$C[fit_svm$results$threshold==fit_svm$results$threshold[1]],
         fit_svm$results$ROC[fit_svm$results$threshold==fit_svm$results$threshold[1]],
         type="l",xlab="#Cost",ylab="AUC",main="SVM")
  }
  
  
  if (any(model=="avNNet")&tuneThreshold){
    col=gray.colors(length(unique(fit_avNNet$results$decay)),start = 0, end = 0.8)
    k=1
    i=unique(fit_avNNet$results$decay)[1]
    plot(fit_avNNet$results$size[fit_avNNet$results$threshold==fit_avNNet$results$threshold[1]&fit_avNNet$results$decay==i],
         fit_avNNet$results$ROC[fit_avNNet$results$threshold==fit_avNNet$results$threshold[1]&fit_avNNet$results$decay==i],
         type="l",xlab="#Hidden Units",ylab="AUC",main="avNNet",col=col[k],
         ylim=c(min(fit_avNNet$results$ROC)-0.01,max(fit_avNNet$results$ROC)))
    for (i in unique(fit_avNNet$results$decay)[-1]){
      k=k+1
      lines(fit_avNNet$results$size[fit_avNNet$results$threshold==fit_avNNet$results$threshold[1]&fit_avNNet$results$decay==i],
            fit_avNNet$results$ROC[fit_avNNet$results$threshold==fit_avNNet$results$threshold[1]&fit_avNNet$results$decay==i],col=col[k])
    }
    legend("bottomright",legend=unique(fit_avNNet$results$decay),col=col,lty=1,cex=0.8,ncol=2)
  }
  
  dev.off()
}

###############################################################################################################
#trade off######
###############################################################################################################

if (any(model=="rf")&tuneThreshold){
  pdf(paste(resultpath,"/TuningStudy_Tradeoff_rf.pdf",sep=""))
  t_mtry=unlist(fit_rf$finalModel$tuneValue[1])
  metrics <- fit_rf$results[fit_rf$results$mtry==t_mtry, c(2, 4:6)]
  metrics <- melt(metrics, id.vars = "threshold",
                  variable.name = "Resampled",
                  value.name = "Data")
  ggplot(metrics, aes(x = threshold, y = Data, color = Resampled)) +
    geom_line() +
    ylab("") + xlab("Probability Cutoff") +
    theme(legend.position = "top") 
}
if (any(model=="rf")&tuneThreshold){
  dev.off()
}

if (any(model=="nnet")&tuneThreshold){
  pdf(paste(resultpath,"/TuningStudy_Tradeoff_nnet.pdf",sep=""))
  t_size=unlist(fit_nnet$finalModel$tuneValue[1])
  t_decay=unlist(fit_nnet$finalModel$tuneValue[2])
  metrics <- fit_nnet$results[fit_nnet$results$size==t_size&fit_nnet$results$decay==t_decay, c(3, 5:7)]
  metrics <- melt(metrics, id.vars = "threshold",
                  variable.name = "Resampled",
                  value.name = "Data")
  ggplot(metrics, aes(x = threshold, y = Data, color = Resampled)) +
    geom_line() +
    ylab("") + xlab("Probability Cutoff") +
    theme(legend.position = "top")

 
  
}
if (any(model=="nnet")&tuneThreshold){
  dev.off()
}

if (any(model=="svm")&tuneThreshold){
  pdf(paste(resultpath,"/TuningStudy_Tradeoff_svm.pdf",sep=""))
  t_sigma=unlist(fit_svm$finalModel@kernelf@kpar$sigma)
  t_C=unlist(fit_svm$finalModel@param[1])
  metrics <- fit_svm$results[fit_svm$results$sigma==t_sigma&fit_svm$results$C==t_C, c(3, 5:7)]
  metrics <- melt(metrics, id.vars = "threshold",
                  variable.name = "Resampled",
                  value.name = "Data")
  ggplot(metrics, aes(x = threshold, y = Data, color = Resampled)) +
    geom_line() +
    ylab("") + xlab("Probability Cutoff") +
    theme(legend.position = "top")
}
if (any(model=="svm")&tuneThreshold){
  dev.off()
}


if (any(model=="avNNet")&tuneThreshold){
  pdf(paste(resultpath,"/TuningStudy_Tradeoff_avNNet.pdf",sep=""))
  t_size=unlist(fit_avNNet$finalModel$tuneValue[1])
  t_decay=unlist(fit_avNNet$finalModel$tuneValue[2])
  metrics <- fit_avNNet$results[fit_avNNet$results$size==t_size&fit_avNNet$results$decay==t_decay, c(4, 6:8)]
  metrics <- melt(metrics, id.vars = "threshold",
                  variable.name = "Resampled",
                  value.name = "Data")
  ggplot(metrics, aes(x = threshold, y = Data, color = Resampled)) +
    geom_line() +
    ylab("") + xlab("Probability Cutoff") +
    theme(legend.position = "top")
}
if (any(model=="avNNet")&tuneThreshold){
  dev.off()
}
