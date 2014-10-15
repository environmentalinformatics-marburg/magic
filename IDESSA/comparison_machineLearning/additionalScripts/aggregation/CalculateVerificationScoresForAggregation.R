usedPackages=c("caret","kernlab","ROCR","raster","latticeExtra","fields","reshape2",
               "grid","maps","mapdata","sp","rgdal","RColorBrewer","lattice","doParallel","hydroGOF","corrplot")
lapply(usedPackages, library, character.only=T)
###compare aggregation
daytime="day"
aggLevel=24
model=c("rf","nnet","avNNet","svm")

###load observed data
rmse=function(observed,predicted){sqrt(mean((observed - predicted)^2, na.rm = TRUE))}
observedpath=paste0("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/",daytime,"/","radolan","/",aggLevel,"h")
observed_dataList=list.files(observedpath,pattern=glob2rx("*.rst"))
observed_data=stack(paste0(observedpath,"/",observed_dataList))
values(observed_data)[values(observed_data)==0]=NA

#for each model ,load prediction
predicted_data=list()
RMSE=list()
RSQ=list()
ME=list()
MAE=list()

for (i in 1:length(model)){
  RMSE[[i]]=vector()
  RSQ[[i]]=vector()
  ME[[i]]=vector()
  MAE[[i]]=vector()
  predictpath=paste0("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/",daytime,"/",model[i],"/",aggLevel,"h")
  predicted_dataList=list.files(predictpath,pattern=glob2rx("*.rst"))
  predicted_data[[i]]=stack(paste0(predictpath,"/",observed_dataList))
  values(predicted_data[[i]])[values(predicted_data[[i]])==0]=NA
  for (k in 1:nlayers(observed_data)){
    if (sum(!is.na(values(predicted_data[[i]][[k]])))==0){
      RMSE[[i]][k]=NA
      RSQ[[i]][k]=NA
      ME[[i]][k]=NA
      MAE[[i]][k]=NA
    }
    if (sum(!is.na(values(predicted_data[[i]][[k]])))!=0){
     RMSE[[i]][k]=rmse(values(observed_data[[k]]),values(predicted_data[[i]][[k]]))
     RSQ[[i]][k]=summary(lm(values(observed_data[[k]])~values(predicted_data[[i]][[k]])))$r.squared 
     ME[[i]][k]=me(values(predicted_data[[i]][[k]]),values(observed_data[[k]]))
     MAE[[i]][k]=mae(values(predicted_data[[i]][[k]]),values(observed_data[[k]]))
    }
  }
}

names(RMSE)=model
names(RSQ)=model
names(ME)=model
names(MAE)=model

save(RMSE,file=paste0("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/RMSE_",daytime,"_",aggLevel,".Rdata"))
save(RSQ,file=paste0("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/RSQ_",daytime,"_",aggLevel,".Rdata"))
save(ME,file=paste0("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/ME_",daytime,"_",aggLevel,".Rdata"))
save(MAE,file=paste0("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/MAE_",daytime,"_",aggLevel,".Rdata"))



