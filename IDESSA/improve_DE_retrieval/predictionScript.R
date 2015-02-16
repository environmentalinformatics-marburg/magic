
################################################################################
rm(list=ls())
################################################################################
#                           USER ADJUSTMENTS
################################################################################

msgpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"
radarpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/"
functionpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/code/functions/"
resultpath="/media/hanna/ubt_kdata_0005/improve_DE_retrieval/predictions/"

referenceimage<-"predVars$glcm_filter$size_3$WV6.2[[1]]"#"IR3.9" #This image will be 
#used together with the radar data to define "no data"

datasetTime<-"day"
response="Rain"


### Define  variables###########################################################

if (datasetTime=="day"&response=="Rain"){
  model=get(load("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/rfe_day_Rain.RData"))
}


if (datasetTime=="day"){
  variables<-c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
               "IR9.7","IR10.8","IR12.0","IR13.4")
  derivVariables=c("T0.6_1.6","T6.2_10.8","T7.3_12.0","T8.7_10.8","T10.8_12.0",
                   "T3.9_7.3","T3.9_10.8","sunzenith")
  xderivTexture=c(variables,derivVariables[-length(derivVariables)])
}
if (datasetTime=="inb"){
  variables<-c("IR3.9","WV6.2","WV7.3","IR8.7",
               "IR9.7","IR10.8","IR12.0","IR13.4")
  derivVariables=c("T6.2_10.8","T7.3_12.0","T8.7_10.8","T10.8_12.0","T3.9_7.3",
                   "T3.9_10.8","sunzenith")
  xderivTexture=c(variables,derivVariables[-length(derivVariables)])
}
if (datasetTime=="night"){
  variables<-c("IR3.9","WV6.2","WV7.3","IR8.7",
               "IR9.7","IR10.8","IR12.0","IR13.4")
  derivVariables=c("T6.2_10.8","T7.3_12.0","T8.7_10.8","T10.8_12.0","T3.9_7.3",
                   "T3.9_10.8")
  xderivTexture=c(variables,derivVariables)
}


################################################################################
#                           Load libraries
################################################################################

library(raster)
setwd(msgpath)
datatable=data.frame()

functions<-paste0(functionpath,list.files(functionpath))

lapply(functions, source)

x=c("ca02p0001","ca02p0002","ca02p0003","ct01dk004","ct01dk005","ct01dk006",
    "ct01dk007","ct01dk008","ct01dk009","ct01dk010","ct01dk011")
### Go through all months, days, hours and scenes ##############################
months=list.files()
for (i in months){
  setwd(paste0(msgpath,i)) 
  days=list.files()
  for (k in days){
    setwd(paste0(msgpath,i,"/",k))
    hours=list.files()
    for (l in hours){
      setwd(paste0(msgpath,i,"/",k,"/",l))
      ### decide to which dataset it belongs (day,night, twilight)####################
      scenes=Sys.glob("*.rst")
      if (length(scenes)<12) {next} #if the folder contains not all necessary data
      
      sunzenith <- tryCatch(
        raster(scenes[substr(scenes,20,23) =="ma11"]), 
        error = function(e)e)
      
      if(inherits(sunzenith, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed"))
        next
      }
      meanzenith=mean(values(sunzenith))
      if ((meanzenith==-99|meanzenith>=70)&datasetTime=="day") next
      if ((meanzenith<70|meanzenith>108)&datasetTime=="inb") next
      if (meanzenith<=108&datasetTime=="night") next
      
      ### get date and radar information #############################################
      date = substr(scenes[1],1,12)
      radarpathtmp= paste0(radarpath,i,"/",k)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))
      radardata=raster(paste0(radarpathtmp,"/",tmp[substr(tmp,1,12)==date]))
      radardata[values(radardata)==-99]=NA
      ### Load MSG data ##############################################################
      scenerasters <- tryCatch(
        stack(scenes[substr(scenes,20,28)%in%x]), 
        error = function(e) e)
      
      if(inherits(scenerasters, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed"))
        next
      }
      
      scenerasters=reclassify(scenerasters, cbind(-99,NA))
      names(scenerasters)<-c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3",
                             "IR8.7","IR9.7","IR10.8","IR12.0","IR13.4")
      
      if (response=="Rain"){
        rainmask=radardata
        values(rainmask)[values(rainmask)<0.06]=NA
      }
      
      rf<-predictRainfall (model$fit$finalModel, sunzenith, msg=scenerasters, variables, xderivTexture, rainmask)
      
      writeRaster(rf,paste0(resultpath,"/prediction_",date,".tiff"),overwrite=TRUE)
    }
  }
}
      