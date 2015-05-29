###analyze overall model performance (not on scene basis)

predpath<-"/run/user/1000/gvfs/sftp:host=192.168.191.183,user=hmeyer/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results/predictions/Rain/"
radarpath<-"/run/user/1000/gvfs/sftp:host=192.168.191.183,user=hmeyer/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval//Radar/2010/"
load("/run/user/1000/gvfs/sftp:host=192.168.191.183,user=hmeyer/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results/trainingscenes.RData")
predictions<-list.files(predpath,pattern=".tif$")
comp_training<-data.frame(matrix(ncol=2))
comp_validation<-data.frame(matrix(ncol=2))
names(comp_training)<-c("pred","obs")
names(comp_validation)<-c("pred","obs")

for (i in 1:length(predictions)){
  pred<-raster(paste0(predpath,"/",predictions[i]))
  tmppath<-paste0(radarpath,"/",substr(predictions[i],20,21),"/",substr(predictions[i],22,23))
  radar<-raster(paste0(tmppath,"/",paste0("2010",substr(predictions[i],20,21),substr(predictions[i],22,23),
                                          substr(predictions[i],24,25),"50_radolan_SGrid.rst")))
  radar[radar<0.06]<-NA
  pred[radar<0.06]<-NA
  radar[is.na(values(pred))]<-NA
  
  #for training scenes:
  if (substr(predictions[[i]],16,25)%in%trainingsc[[1]]) {
    comp_training<-rbind(comp_training,data.frame("pred"=values(pred)[!is.na(values(pred))],"obs"=values(radar)[!is.na(values(radar))]))
  }
  #and non training scenes:
  if (!substr(predictions[[i]],16,25)%in%trainingsc[[1]]) {
    comp_validation<-rbind(comp_validation,data.frame("pred"=values(pred)[!is.na(values(pred))],"obs"=values(radar)[!is.na(values(radar))]))
  }
  print(i)
}
comp_training<-comp_training[-1,]
comp_validation<-comp_validation[-1,]
save(comp_training,file="/run/user/1000/gvfs/sftp:host=192.168.191.183,user=hmeyer/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results/globalComp_training.RData")
save(comp_validation,file="/run/user/1000/gvfs/sftp:host=192.168.191.183,user=hmeyer/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results/globalComp_validation.RData")
model_valid<-lm(comp_validation$obs~comp_validation$pred)
model_training<-lm(comp_training$obs~comp_training$pred)


ddf_valid<-data.frame("pred"=comp_validation$pred,"obs"=comp_validation$obs)
ddf_training<-data.frame("pred"=comp_training$pred,"obs"=comp_training$obs)

pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/globalComp.pdf")

xyplot(pred ~ obs, ddf_valid, grid=T, xlim=c(0,15),ylim=c(0,15),panel=function(...){
  panel.smoothScatter(nbin = 500, cuts = 1000, 
                      colramp = colorRampPalette(c("white","blue","green","yellow","red")), ...)
  panel.lmline(...)
  panel.text(13,14.5,labels=paste0("Rsq= ", round(summary(model_valid)$r.squared,2)),cex=1.5)
})

xyplot(pred ~ obs, ddf_training, grid=T, xlim=c(0,15),ylim=c(0,15),panel=function(...){
  panel.smoothScatter(nbin = 500, cuts = 1000, 
                      colramp = colorRampPalette(c("white","blue","green","yellow","red")), ...)
  panel.lmline(...)
  panel.text(13,14.5,labels=paste0("Rsq= ", round(summary(model_training)$r.squared,2)),cex=1.5)
})
dev.off()



pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/globalComp_detail.pdf")

xyplot(pred ~ obs, ddf_valid, grid=T, xlim=c(0,10),ylim=c(0,10),panel=function(...){
  panel.smoothScatter(nbin = 500, cuts = 1000, 
                      colramp = colorRampPalette(c("white","blue","green","yellow","red")), ...)
  panel.lmline(...)
  panel.text(8,9.5,labels=paste0("Rsq= ", round(summary(model_valid)$r.squared,2)),cex=1.5)
})

xyplot(pred ~ obs, ddf_training, grid=T, xlim=c(0,10),ylim=c(0,10),panel=function(...){
  panel.smoothScatter(nbin = 500, cuts = 1000, 
                      colramp = colorRampPalette(c("white","blue","green","yellow","red")), ...)
  panel.lmline(...)
  panel.text(8,9.5,labels=paste0("Rsq= ", round(summary(model_training)$r.squared,2)),cex=1.5)
})
dev.off()

