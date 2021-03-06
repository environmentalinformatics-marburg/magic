#Comparison of Confusion metrics
dir.create (paste(resultpath,"/Confusion_comp",sep=""))

predictionFiles=paste0(resultpath,"/",Filter(function(x) grepl("RData", x), list.files(resultpath,pattern="prediction")))
for (i in predictionFiles){
  load(i)
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

###write whole confusion data.set
confusiondataOut=confusiondata
for (i in 1:length(confusiondataOut)){
  colnames(confusiondataOut[[i]])=scorenames
  write.csv(confusiondataOut[[i]],file=paste(resultpath,"/Confusion_comp/confusiondata_",model[i],".csv",sep=""),row.names=FALSE)
}


###write confusion means
confusionmeans=lapply(confusiondata,colMeans)
confusionsd=lapply(confusiondata,function(x){apply(x, 2, sd)})
confusionmeansMatrix=matrix(ncol=length(scorenames),nrow=length(model))
confusionsdMatrix=matrix(ncol=length(scorenames),nrow=length(model))
for (i in 1:length(confusionmeans)){
  confusionmeansMatrix[i,]=confusionmeans[[i]]
  confusionsdMatrix[i,]=confusionsd[[i]]
}

confusionMeanAndSD=paste(round(confusionmeansMatrix,2),"+/-",round(confusionsdMatrix,2))
confusionMeanAndSD=matrix(confusionMeanAndSD,ncol=length(scorenames),nrow=length(model),byrow=FALSE)

colnames(confusionMeanAndSD)=scorenames
colnames(confusionmeansMatrix)=scorenames
colnames(confusionmeansMatrix)=scorenames
rownames(confusionMeanAndSD)=model
rownames(confusionmeansMatrix)=model
rownames(confusionmeansMatrix)=model

confusionmeansMatrix=t(confusionmeansMatrix)
confusionmeansMatrix=t(confusionmeansMatrix)
confusionMeanAndSD=t(confusionMeanAndSD)

write.csv(confusionmeansMatrix,file=paste(resultpath,"/Confusion_comp/confusionmeans.csv",sep=""))
write.csv(confusionsdMatrix,file=paste(resultpath,"/Confusion_comp/confusionsd.csv",sep=""))
write.csv(confusionMeanAndSD,file=paste(resultpath,"/Confusion_comp/confusionMeanAndSD.csv",sep=""))
##########

for (score in 1:ncol(confusiondata[[1]])){
  scoredata=confusiondata[[1]][,score]
  for (i in 2:length(model)){
    scoredata=cbind(scoredata,confusiondata[[i]][,score])
  }
  names=c()
  for (i in 1:length(model)){
    names=c(names,rep(model[i],nrow(confusiondata[[1]])))
  }
  names=factor( names, levels=model)
####Plot
  scoredata=as.vector(scoredata)
  pdf(paste(resultpath,"/Confusion_comp/comparison_",scorenames[score],".pdf",sep=""))
    print(bwplot(as.vector(scoredata)~names,ylab=scorenames[score]))
  dev.off()
}

##########significant differences??
wilcoxresultsPaired=list()
for (j in 1:length(scorenames)){
  wilcoxresultsPaired[[j]]=matrix(ncol=length(model),nrow=length(model))
  for (i in 1:(length(model)-1)){
    for(k in (i+1):length(model)){
    wilcoxresultsPaired[[j]][i,k]=wilcox.test(confusiondata[[i]][,j],confusiondata[[k]][,j],paired=T)$p.value
    }
  }
}
for (i in 1:length(wilcoxresultsPaired)){
  colnames(wilcoxresultsPaired[[i]])=model
  rownames(wilcoxresultsPaired[[i]])=model
  write.csv(wilcoxresultsPaired[[i]],file=paste(resultpath,"/Confusion_comp/wilcox_Paired_Conf_",scorenames[i],".csv",sep=""))
}
