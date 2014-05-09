###Spatial
if (any(model=="rf")){
  load(paste(resultpath,"/prediction_rf.RData",sep=""))
}
if (any(model=="mlp")){
  load(paste(resultpath,"/prediction_mlp.RData",sep=""))
}
if (any(model=="nnet")){
  load(paste(resultpath,"/prediction_nnet.RData",sep=""))
}
if (any(model=="svm")){
  load(paste(resultpath,"/prediction_svm.RData",sep=""))
}

library(raster)

pdf(paste(resultpath,"/SpatialComparison.pdf",sep=""),width=30,height=3)
for(scene in 1: length (unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))))){
  
  obs=as.character(eval(parse(text=paste("prediction_",model[1],"$observed",sep=""))),sep="")
  obs[obs=="rain"]=1
  obs[obs=="norain"]=0
  
  obsRaster=rasterFromXYZ(data.frame(
    eval(parse(text=paste("prediction_",model[1],"$x",sep="")))[eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))==
                                                                  unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene]],
    eval(parse(text=paste("prediction_",model[1],"$y",sep="")))[eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))==
                                                                  unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene]],
    obs[eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))==unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene]]))
  
  time=paste(substr(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],0,4),"-",
             substr(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],5,6),"-",
             substr(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],7,8)," ", 
             substr(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],9,10),":",
             substr(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],11,12),sep="")
  par(mfrow=c(1,length(model)+1),mar=c(0,0,3,0))
  plot(obsRaster,main=paste(time,", observed,", sep=""),legend=FALSE,axes=FALSE)
  
  for (i in 1:length(model)){
    modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))

    pred=as.character(modeldata$prediction,sep="")
    pred[pred=="rain"]=1
    pred[pred=="norain"]=0

    predRaster=rasterFromXYZ(data.frame(modeldata$x[modeldata$chDate==unique(modeldata$chDate)[scene]],
                                   modeldata$y[modeldata$chDate==unique(modeldata$chDate)[scene]],
                                   pred[modeldata$chDate==unique(modeldata$chDate)[scene]]))

    
    plot(predRaster,main=paste(time,", predicted, model=",model[i],sep=""),legend=FALSE,axes=FALSE)
  }
}
dev.off()