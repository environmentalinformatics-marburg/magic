library(raster)
###compare aggregation
daytime="day"
aggLevel=3
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
rsq=list()
for (i in 1:length(model)){
  RMSE[[i]]=vector()
  rsq[[i]]=vector()
  predictpath=paste0("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/",daytime,"/",model[i],"/",aggLevel,"h")
  predicted_dataList=list.files(predictpath,pattern=glob2rx("*.rst"))
  predicted_data[[i]]=stack(paste0(predictpath,"/",predicted_dataList))
  values(predicted_data[[i]])[values(predicted_data[[i]])==0]=NA
  for (k in 1:nlayers(observed_data)){
    if (sum(!is.na(values(predicted_data[[i]][[k]])))==0){
      RMSE[[i]][k]=NA
      rsq[[i]][k]=NA
    }
    if (sum(!is.na(values(predicted_data[[i]][[k]])))!=0){
     RMSE[[i]][k]=rmse(values(observed_data[[k]]),values(predicted_data[[i]][[k]]))
     rsq[[i]][k]=summary(lm(values(observed_data[[k]])~values(predicted_data[[i]][[k]])))$r.squared 
    }
    #ME
    #MAE
  }
}

names(RMSE)=model
names(rsq)=model