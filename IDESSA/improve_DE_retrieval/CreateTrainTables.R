################################################################################
# Create training tables from MSG and radar data
################################################################################
#script sperates between day,night and twilight scenes,
#calculate spectral derivates of the channnels, texture and geometry parameters

#Author:Hanna, January 2015
################################################################################
rm(list=ls())
#options(warn=2)
################################################################################
#                           USER ADJUSTMENTS
################################################################################


msgpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"
radarpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/"
functionpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/code/functions/"
resultpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results"

referenceimage<-"predVars$glcm_filter$size_3$WV6.2[[1]]"#"IR3.9" #This image will be 
#used together with the radar data to define "no data"

datasetTime<-"day"
includeAllscenes=TRUE
samplesize=0.1 # number of scenes for training


### Define  variables###########################################################

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


lapply(functions, source)
functions<-paste0(functionpath,list.files(functionpath))
################################################################################
###             Define random test scenes (0.25%)
################################################################################
##alle kombination aus k,i,l. davon 25%
pi1=formatC(1:12,flag=0,width=2)
pk=formatC(1:30,flag=0,width=2)
pl=formatC(0:23,flag=0,width=2)

allscenes<-expand.grid(pi1,pk,pl)
set.seed(25)
trainingscenes<-allscenes[sample(nrow(allscenes),samplesize*nrow(allscenes)),]
trainingscenes=apply( trainingscenes , 1 , paste , collapse = "" )


################################################################################
#                           Start calculations
################################################################################
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
      if(!paste0(i,k,l)%in%trainingscenes) next #use only trainingscenes
      print (paste0("month: ", i, " day:", k, " hour: ", l, " in progress.."))
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
      if (meanzenith>=70&datasetTime=="day") next
      if ((meanzenith<70|meanzenith>108)&datasetTime=="inb") next
      if (meanzenith<=108&datasetTime=="night") next
      
### get date and radar information #############################################
      date = substr(scenes[1],1,12)
      radarpathtmp= paste0(radarpath,i,"/",k)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))
      radardata=raster(paste0(radarpathtmp,"/",tmp[substr(tmp,1,12)==date]))
      radardata[values(radardata)==-99]=NA
### only process data if they include at least 2000 rainy pixels (rainy=>0.06mm)
      if (!includeAllscenes){
        if (sum(values(radardata)>0.06,na.rm=TRUE)<2000) next
      }
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

### only process data if the MSG raster include valid data #####################
       if(min(values(is.na(scenerasters)))==1) next
###... or at least 50 cloud pixels (otherwise texture might not work)
       if(sum(!is.na(values((scenerasters))))<50) next

################################################################################
###                 caluclate derivated variables 
################################################################################

### Meikes predictor variables #################################################

      predVars<-calculatePredictors(scenerasters,sunzenith,variables,xderivTexture)


      glcm_3=as.data.frame(lapply(predVars$glcm_filter$size_3,values))
        #names(glcm_3)<-paste0("f3_",names(glcm_3))

reference<-eval(parse(text=paste0(referenceimage)))
noDataIdentifier<-!is.na(values(radardata))&!is.na(values(reference))&!is.na(
  values(predVars$glcmPerPatchRaster$pp_contrast_T8.7_10.8))&!is.na(
    values(predVars$cloud_geometry$CCI2))

      datatable <- rbind(datatable,
                         cbind(rep(date,sum(noDataIdentifier)),
                                coordinates(radardata)[noDataIdentifier,],
                                values(predVars$dayOfYear)[noDataIdentifier],
                               cbind(values(predVars$scenerasters))[noDataIdentifier,],
                               cbind(values(predVars$MeanPerPatch))[noDataIdentifier,],
                               cbind(values(predVars$SdPerPatch))[noDataIdentifier,],
                               cbind(values(predVars$MinPerPatch))[noDataIdentifier,],
                               cbind(values(predVars$MaxPerPatch))[noDataIdentifier,],
                               cbind(values(predVars$glcmPerPatchRaster))[noDataIdentifier,],
                               cbind(values(predVars$cloud_geometry))[noDataIdentifier,-1],
                               glcm_3[noDataIdentifier,],
 #                              glcm_5[noDataIdentifier,],
                               values(radardata)[noDataIdentifier]))
 
      rm(scenerasters,cloud_geometry,glcm_3,
 #        glcm_5,
         glcm_filter,T6.2_10.8,
         T7.3_12.0,T8.7_10.8,T10.8_12.0,T3.9_7.3,T3.9_10.8,sunzenith,radardata,
         scenes,radarpathtmp,tmp,date,reference,MeanPerPatch,SdPerPatch,glcmPerPatchRaster,
         tmpStats,ZonalStats)
      gc()      

### finish the script ##########################################################     
    }
  }
}

names(datatable)[1]="Date"
names(datatable)[2]="X"
names(datatable)[3]="Y"
names(datatable)[4]="JDay"
names(datatable)[ncol(datatable)]="Radar"
save(datatable,file=paste0(resultpath,"/datatable_",datasetTime,".RData"))

