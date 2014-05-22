
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


  


