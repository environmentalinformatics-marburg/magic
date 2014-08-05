######compare RMSE of regression models########################


predictionFiles=paste0(resultpath,"/",Filter(function(x) grepl("RData", x), list.files(resultpath,pattern="prediction")))
for (i in predictionFiles){
  load(i)
}
load(paste(resultpath,"/predictorVariables.RData",sep=""))
load(paste(resultpath,"/testing.RData",sep=""))


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