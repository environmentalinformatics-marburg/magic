library(gtools)
library(raster)
#library(Rsenal)


##1) Unterteilen in Gruppen: a) Da wo alle Besser, b) da wo Nur Spektral besser
#nach R²
predpath <- "/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/results/predictions/"
referencepath <- "/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/RadarProj/2010/"
source("/home/hmeyer/hmeyer/Improve_DE_retrieval/functionsFromRsenal/classificationStats.R")
source("/home/hmeyer/hmeyer/Improve_DE_retrieval/functionsFromRsenal/regressionStats.R")
source("/home/hmeyer/hmeyer/Improve_DE_retrieval/functionsFromRsenal/se.R")

models <- c("all","onlySpectral")
submodels <- c("day_Rain","day_RInfo","night_Rain","night_RInfo")

references <- list.files(referencepath,pattern=".tif$",recursive=T)
#head(references)


results <- data.frame()
for (i in 1:length(models)){
  setwd(predpath)
  setwd(models[i])
  for(k in 1:length(submodels)){
    type="Regression"
    if(grepl("RInfo",submodels[k])){
      type="Classification"
    }
    daytime <- "Night"
    if(grepl("day",submodels[k])){
      daytime="Day"
    }
    predictions <- list.files(submodels[k],pattern=".tif$")
    predictions <- predictions[grepl("pred",predictions)]
    
    for (l in 1:length(predictions)){
      datestring <- substr(predictions[l],nchar(predictions[l])-13,
                           nchar(predictions[l])-4)
      prediction <- tryCatch(raster(paste0(submodels[k],"/",predictions[l])), 
                             error = function(e)e)
      reference <- tryCatch(raster(paste0(referencepath,"/",
                                          references[grepl(datestring,references)])),
                            error = function(e)e)
      if(inherits(reference, "error")||inherits(prediction, "error")) {
        print ("skipped file")
        next
      }
      reference <- mask(reference,prediction)
      rainstat <- data.frame("rain_mean"=mean(values(reference),na.rm=T),
                             "rain_sd"=sd(values(reference),na.rm=T),
                             "rain_pixels"=sum(values(reference)>=0.06,na.rm=T),
                             "cloud_pixels"=sum(!is.na(values(reference))),
                             "rain_cloud_ratio"=sum(!is.na(values(reference)))/
                               sum(values(reference)>=0.06,na.rm=T))
      
      if(type=="Classification"){
        reference[reference>=0.06]=1
        reference[reference<0.06]=2
        perf<-tryCatch(classificationStats(values(prediction),values(reference)),error = function(e)e)
        if(inherits(perf, "error")) {
          print ("skipped file")
          next
        }}
      if(type=="Regression"){
        perf<-tryCatch(regressionStats(values(prediction),values(reference)),error = function(e)e)
        if(inherits(perf, "error")) {
          print ("skipped file")
          next
        }
      }
      results <- smartbind(results,data.frame(models[i],type,daytime,datestring,rainstat,perf))
    }
    print(k)
  }
}
save(results,file="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/results/GroupComp.RData")




###statistik aus Radolan über regenfläche und regenmenge tag uhrzeit






