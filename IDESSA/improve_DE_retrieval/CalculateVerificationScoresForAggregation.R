rm(list=ls())
usedPackages=c("caret","kernlab","ROCR","raster","latticeExtra","fields","reshape2",
               "grid","maps","mapdata","sp","rgdal","RColorBrewer","lattice","doParallel","hydroGOF","corrplot")
lapply(usedPackages, library, character.only=T)
###compare aggregation
daytime="day"
aggLevel=24
model=c("all","onlySpectral")

###load observed data
rmse=function(observed,predicted){sqrt(mean((observed - predicted)^2, na.rm = TRUE))}
observedpath=paste0("/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/predictions/radolan_24h/")
observed_dataList=list.files(observedpath,pattern=".tif$")


#for each model ,load prediction
predicted_data=list()


valid<-list()
for (i in 1:length(model)){
  predictpath=paste0("/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/predictions/",model[i],"/",daytime,"_Rain/",aggLevel,"h/")
  predicted_dataList=list.files(predictpath,pattern=".tif$")
  observed_dataList<-observed_dataList[observed_dataList%in%predicted_dataList]
  observed_data=stack(paste0(observedpath,"/",observed_dataList))
  values(observed_data)[values(observed_data)==0]=NA
  predicted_data[[i]]=stack(paste0(predictpath,"/",observed_dataList))
  values(predicted_data[[i]])[values(predicted_data[[i]])<=0]=NA
  valid[[i]]<-data.frame()
  for (k in 1:nlayers(observed_data)){
    observed_data[[k]]=mask(observed_data[[k]],predicted_data[[i]][[k]])
    valid[[i]]<-rbind(valid[[i]],
                      Rainfall::validate(observed_data[[k]],predicted_data[[i]][[k]]))
  }
}
