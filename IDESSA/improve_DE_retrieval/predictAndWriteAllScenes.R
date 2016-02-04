### predict and Write all raster scenes
library(Rainfall)
library(doParallel)
library(caret)

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

trM<-list.files("/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/trainedModels/",
                pattern="trainedModel",full.names = TRUE)

inpath<-list.dirs("/media/hanna/data/copyFrom183/Improve_DE_retrieval/MSGProj/2010/",
                  recursive=T)
inpath <- inpath[nchar(inpath)>=72]
models<-list()
for (i in 1:length(trM)){
  models[[i]]<-get(load(trM[i]))
}
 for (i in 1:length(models)){ 
  response="RInfo"
  if (grepl("Rain",trM[i])==1){response="Rain"}
  
  daytime<-"night"
  if (grepl("day",trM[i])==1){daytime="day"}
  
  modelT<-"all"
  if (grepl("OnlySpec",trM[i])==1){modelT="OnlySpec"}
  
  for (k in 1:length(inpath)){
    szen <- getSunzenith(inpath[k],type="tif")
#    if(ncell(szen)==length(values(szen)==-99)){next}
    dt<-tryCatch(getDaytime(szen),error = function(e)e)
    if(inherits(dt, "error")) {
    
      next
    }
    
    if(dt=="day"&daytime!="day"){next}
    if(dt=="night"&daytime!="night"){next}
    if(dt=="twilight"&daytime!="night"){next}
    
    pred <- predictRainfall(models[[i]], inpath = inpath[k],
                            scaleparam = models[[i]]$scaleParam, min_x = min_x, max_x = max_x,
                            type = "tif")
    dat <- getDate(inpath[k],type="tif")
    
    outpath<-paste0("/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/predictions/test/",
                    modelT,"/",response,"/",daytime,"/")
    dir.create(outpath)
    writeRaster(pred,paste0(outpath,"pred_",dat,".tif"))
 } 
}