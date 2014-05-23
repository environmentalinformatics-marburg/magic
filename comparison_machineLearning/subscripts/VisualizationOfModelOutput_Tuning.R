
#abb tuning parameters- model
#abb ob RMSE ~ number of trees bei 1000 noch improved

if (any(model=="rf")){
load(paste(resultpath,"/fit_rf.RData",sep=""))
}
if (any(model=="nnet")){
load(paste(resultpath,"/fit_nnet.RData",sep=""))
}
if (any(model=="svm")){
load(paste(resultpath,"/fit_svm.RData",sep=""))
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
dev.off()
####test
pdf(paste(resultpath,"/TuningStudy_b.pdf",sep=""))
if (any(model=="rf")){
  plot(fit_rf$results$mtry[fit_rf$results$threshold==fit_rf$results$threshold[1]],
       fit_rf$results$ROC[fit_rf$results$threshold==fit_rf$results$threshold[1]],
       type="l",xlab="#Randomly Selected Predictors",ylab="AUC",main="RF")
}
if (any(model=="nnet")){
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
if (any(model=="svm")){
  plot(fit_svm$results$C[fit_svm$results$threshold==fit_svm$results$threshold[1]],
       fit_svm$results$ROC[fit_svm$results$threshold==fit_svm$results$threshold[1]],
       type="l",xlab="#Cost",ylab="AUC",main="SVM")
}
dev.off()


###############################################################################################################
#trade off######
###############################################################################################################

  library(reshape2)
pdf(paste(resultpath,"/TuningStudy_Tradeoff_rf.pdf",sep=""))
  if (any(model=="rf")&tuneThreshold){
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
dev.off()
  
pdf(paste(resultpath,"/TuningStudy_Tradeoff_nnet.pdf",sep=""))
  if (any(model=="nnet")&tuneThreshold){
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
dev.off()
pdf(paste(resultpath,"/TuningStudy_Tradeoff_svm.pdf",sep=""))
  if (any(model=="svm")&tuneThreshold){
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
dev.off()


  


