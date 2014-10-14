######compare RMSE of regression models########################


predictionFiles=paste0(resultpath,"/",Filter(function(x) grepl("RData", x), list.files(resultpath,pattern="prediction")))
for (i in predictionFiles){
  load(i)
}
load(paste(resultpath,"/predictorVariables.RData",sep=""))
load(paste(resultpath,"/testing.RData",sep=""))


#########density plots
predictionlist=list()
for (i in 1:length(model)){
  predictionlist[[i]]=eval(parse(text=paste("prediction_",model[i],sep="")))
}
pdf(paste(resultpath,"/density.pdf",sep=""))
  plotDensity(predictionlist)
dev.off()

####pro szene RMSE
RMSE=list()
for (i in 1:length(model)){
  modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))
  RMSE[[i]]=rmsePerScene(modeldata,dateField)
}


######BOXPLOTS#################################################
RMSE_all=RMSE[[1]][,2]
for (i in 2:length(model)){
  RMSE_all=cbind(RMSE_all,RMSE[[i]][,2])
}
names=c()
for (i in 1:length(model)){
  names=c(names,rep(model[i],nrow(RMSE_all)))
}
names=factor( names, levels=c("rf","nnet","svm","avNNet"))
pdf(paste(resultpath,"/prediction_RMSE.pdf",sep=""))
#  boxplot(RMSE_all,names=model,ylab="RMSE")
  bwplot(as.vector(RMSE_all)~names,ylab="RMSE")
dev.off()

combis <- combn(length(model), 2)
pvals <- numeric(ncol(combis))
pvalstab=matrix(ncol=3,nrow=length(pvals))
for (i in 1:ncol(combis)){
  pvals[i] <- wilcox.test(RMSE_all[,combis[1,i]], RMSE_all[,combis[2,i]]
                                        ,paired=T)$p.value
  pvalstab[i,]=cbind(rbind(model[combis[,i]]),pvals[i])

}
colnames(pvalstab)=c("model1","model2","p-value")
write.csv(pvalstab,file=paste(resultpath,"/RMSE_comp.csv",sep=""))


#######################r SQUARED

####pro szene
Rsquared=list()
for (i in 1:length(model)){
  modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))
  Rsquared[[i]]=rsquaredPerScene(modeldata,dateField)
}
Rsquared_all=Rsquared[[1]][,2]
for (i in 2:length(model)){
  Rsquared_all=cbind(Rsquared_all,Rsquared[[i]][,2])
}
names=c()
for (i in 1:length(model)){
  names=c(names,rep(model[i],nrow(Rsquared_all)))
}
names=factor( names, levels=c("rf","nnet","svm","avNNet"))
pdf(paste(resultpath,"/prediction_Rsquared.pdf",sep=""))
bwplot(as.vector(Rsquared_all)~names,ylab="Rsquared")
dev.off()


#######################ME

####pro szene
ME=list()
for (i in 1:length(model)){
  modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))
  ME[[i]]=MEPerScene(modeldata,dateField)
}
ME_all=ME[[1]][,2]
for (i in 2:length(model)){
  ME_all=cbind(ME_all,ME[[i]][,2])
}
names=c()
for (i in 1:length(model)){
  names=c(names,rep(model[i],nrow(ME_all)))
}
names=factor( names, levels=c("rf","nnet","svm","avNNet"))
pdf(paste(resultpath,"/prediction_ME.pdf",sep=""))
bwplot(as.vector(ME_all)~names,ylab="ME")
dev.off()

#######################MAE

####pro szene
MAE=list()
for (i in 1:length(model)){
  modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))
  MAE[[i]]=MAEPerScene(modeldata,dateField)
}
MAE_all=MAE[[1]][,2]
for (i in 2:length(model)){
  MAE_all=cbind(MAE_all,MAE[[i]][,2])
}
names=c()
for (i in 1:length(model)){
  names=c(names,rep(model[i],nrow(MAE_all)))
}
names=factor( names, levels=c("rf","nnet","svm","avNNet"))
pdf(paste(resultpath,"/prediction_MAE.pdf",sep=""))
bwplot(as.vector(MAE_all)~names,ylab="MAE")
dev.off()

#######################Significant differences

#######################Write all scores to table
for (i in 1:length(RMSE)){
  VerificationScores=data.frame("RMSE"=RMSE[[i]][,2],"ME"=ME[[i]][,2],"MAE"=MAE[[i]][,2],"RSQ"=Rsquared[[i]][,2])
  write.csv(VerificationScores,file=paste(resultpath,"/VerificationScores_",model[i],".csv",sep=""),row.names=FALSE)
}

#######################Means and SD's

meanRMSE=apply(RMSE_all,2,mean)
sdRMSE=apply(RMSE_all,2,sd)
RMSEMeanSD=paste(round(meanRMSE,2),"+/-",round(sdRMSE,2),sep="")

meanRsquared=apply(Rsquared_all,2,mean)
sdRsquared=apply(Rsquared_all,2,sd)
RsquaredMeanSD=paste(round(meanRsquared,2),"+/-",round(sdRsquared,2),sep="")

meanME=apply(ME_all,2,mean)
sdME=apply(ME_all,2,sd)
MEMeanSD=paste(round(meanME,2),"+/-",round(sdME,2),sep="")

meanMAE=apply(MAE_all,2,mean)
sdMAE=apply(MAE_all,2,sd)
MAEMeanSD=paste(round(meanMAE,2),"+/-",round(sdMAE,2),sep="")

performanceMeanSD=rbind(RMSEMeanSD,RsquaredMeanSD,MEMeanSD,MAEMeanSD)
row.names(performanceMeanSD)=c("RMSE","RSQ","ME","MAE")
colnames(performanceMeanSD)=model

write.csv(performanceMeanSD,file=paste(resultpath,"/PerformanceMeanAndSD.csv",sep=""))

