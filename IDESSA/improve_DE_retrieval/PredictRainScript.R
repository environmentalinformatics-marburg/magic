### Prediction ################
rm(list=ls())

library(raster)
library(caret)
library(Rainfall)
library(Rsenal)
datasetTime<-"day"
responseName<-"Rain"
pc="hanna"

if (pc=="hanna"){
  resultpath<-"/media/hanna/ubt_kdata_0005/improve_DE_retrieval/"
  radarpath<-"/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/"
  msgpath <- "/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"
  rasterpathout <- "/media/hanna/ubt_kdata_0005/improve_DE_retrieval/predictions/Rain"
}
if (pc=="ui183"){
  resultpath<-  "/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results/"
  radarpath<-  "/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/Radar/2010/"
  msgpath<-  "/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/MSG/2010/"
  rasterpathout <- "/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results/predictions/Rain"
}


################################################################################
load(paste0(resultpath,"/trainedModel_",datasetTime,"_",responseName,".Rdata"))
load(paste0(resultpath,"/rainevents.RData"))
rainevents <- rainevents[rainevents$daytime==datasetTime,]
load(paste0(resultpath,"trainingscenes.RData"))

### set global min/max values for each channel
min_x <- c(0.08455839,0.05533640,0.02237568,156.625000,210.00000000,208.75000000,
           209.62500000,213.750000,208.62500000,208.50000000,210.437500,-0.21682912, 
           -67.85000610,-40.55001831,-4.875000,-2.05001831,-64.875000,-70.250000)
names(min_x) <-  c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                   "IR9.7","IR10.8","IR12.0","IR13.4","T0.6_1.6","T6.2_10.8",
                   "T7.3_12.0", "T8.7_10.8","T10.8_12.0", "T3.9_7.3",
                   "T3.9_10.8")

max_x <- c(1.3163714,1.4401436,0.9915133,306.2749939,246.6875000,261.3750000, 
           296.0999756,263.0000000,299.1000061,294.6500244,267.5499878,0.8078508, 
           2.812500,12.737503,8.3750000,10.6625061,60.9874878,59.8000183) 
names(max_x) <-  names(min_x)



evaluation_validation=data.frame(matrix(ncol=8))
evaluation_training=data.frame(matrix(ncol=8))
names(evaluation_validation)=c("scene","ME","ME.se","MAE","MAE.se","RMSE","RMSE.se","Rsq")
names(evaluation_training)=c("scene","ME","ME.se","MAE","MAE.se","RMSE","RMSE.se","Rsq")
comp_training<-data.frame(matrix(ncol=2))
comp_validation<-data.frame(matrix(ncol=2))
names(comp_training)<-c("pred","obs")
names(comp_validation)<-c("pred","obs")
for (i in 1:nrow(rainevents)){
  month=rainevents[i,1]
  day=rainevents[i,2]
  time=rainevents[i,3]
  exacttime=paste0(time,"50")
  
  reference=raster(paste0(radarpath,"/",month,"/",day,"/2010",
                          month,day,exacttime,"_radolan_SGrid.rst"))
  values(reference)[values(reference<0.06)]=NA
  
  #plot(reference)
  pred<-predictRainfall(model=model, inpath= paste0(msgpath,"/",month,"/",
                                                    day,"/",time,"/"),
                        rainmask=reference,min_x=min_x,max_x=max_x)
  
  ###test:only mean:
#  pred<-reference
#  values(pred)<-1.633273
#  pred<-mask(pred,reference)
  ###
  
  reference[reference<0.06]<-NA
  pred[reference<0.06]<-NA
  reference=mask(reference,pred)
  
  #  writeRaster(pred, filename=paste0(rasterpathout,"/prediction_",
  #                                          responseName,"2010",month,
  #                                          day,time,".tif"), 
  #                    datatype='GTiff', overwrite=TRUE)
  
  
  
  
  
  #for training scenes:
  if (paste0("2010",month,day,time)%in%trainingsc[[1]]) {
    evaluation_training=rbind(evaluation_training,cbind("scene"=paste0("2010",month,day,time),validate(obs=reference,pred=pred)))
    comp_training<-rbind(comp_training,data.frame("pred"=values(pred)[
      !is.na(values(pred))],"obs"=values(reference)[!is.na(values(reference))]))
  }
  #and non training scenes:
  if (!paste0("2010",month,day,time)%in%trainingsc[[1]]) {
    evaluation_validation=rbind(evaluation_validation,cbind("scene"=paste0("2010",month,day,time),validate(obs=reference,pred=pred)))
    comp_validation<-rbind(comp_validation,data.frame("pred"=values(pred)[
      !is.na(values(pred))],"obs"=values(reference)[!is.na(values(reference))]))
  }
  print(i)
}

evaluation_validation<-evaluation_validation[-1,]
evaluation_training<-evaluation_training[-1,]
comp_training<-comp_training[-1,]
comp_validation<-comp_validation[-1,]

### save evaluation
save(evaluation_validation,file=paste0(resultpath,"/evaluation_validation_20_",datasetTime,
                                       "_",responseName,".Rdata"))
save(evaluation_training,file=paste0(resultpath,"/evaluation_training_20_",datasetTime,
                                     "_",responseName,".Rdata"))

save(comp_training,file=paste0(resultpath,"/globalComp_training20.RData"))
save(comp_validation,file=paste0(resultpath,"globalComp_validation20.RData"))

