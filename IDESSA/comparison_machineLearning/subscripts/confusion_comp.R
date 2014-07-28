#Comparison of Confusion metrics
dir.create (paste(resultpath,"/Confusion_comp",sep=""))

if (any(model=="rf")){
  load(paste(resultpath,"/prediction_rf.RData",sep=""))
}
if (any(model=="nnet")){
  load(paste(resultpath,"/prediction_nnet.RData",sep=""))
}
if (any(model=="svm")){
  load(paste(resultpath,"/prediction_svm.RData",sep=""))
}

#calculate confusion metrices per scene

confusion=list()
for (scene in 1:length(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))))){
  confusion[[scene]]=list()
  for (i in 1:length(model)){
    modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))
    confusion[[scene]][[i]]=confusionMetrics(modeldata$prediction[modeldata$chDate==unique(modeldata$chDate)[scene]],
                                             modeldata$observed[modeldata$chDate==unique(modeldata$chDate)[scene]])
  }
}
#restructure confusion metrices
tmp=as.matrix(confusion,ncol=length(confusion))
confusiondata=list()
for (i in 1:length(model)){
  confusiondata[[i]]=matrix(nrow=length(confusion),ncol=length(confusion[[1]][[1]]))
  for (scene in 1:length(confusion)){
    confusiondata[[i]][scene,]=unlist(tmp[scene,][[1]][[i]])
  }
}
scorenames=names(confusion[[1]][[1]])
for (score in 1:ncol(confusiondata[[1]])){
  scoredata=confusiondata[[1]][,score]
  for (i in 2:length(model)){
    scoredata=cbind(scoredata,confusiondata[[i]][,score])
  }
  names=c()
  for (i in 1:length(model)){
    names=c(names,rep(model[i],nrow(confusiondata[[1]])))
  }
####Plot
  scoredata=as.vector(scoredata)
  pdf(paste(resultpath,"/Confusion_comp/comparison_",scorenames[score],".pdf",sep=""))
    print(bwplot(as.vector(scoredata)~names,ylab=scorenames[score]))
  dev.off()
}

