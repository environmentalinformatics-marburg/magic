################################################################################
# Create training tables from MSG and radar data
################################################################################
#script sperates between day,night and twilight scenes,
#calculate spectral derivates of the channnels, texture and geometry parameters

#Author:Hanna, January 2015
################################################################################
rm(list=ls())
options(warn=2)
################################################################################
#                           USER ADJUSTMENTS
################################################################################


msgpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"
radarpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/"
functionpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/code/functions/"
resultpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results"

referenceimage<-"glcm_filter$size_3$WV6.2[[1]]"#"IR3.9" #This image will be 
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
  
#  xderivTexture=c("IR13.4","IR9.7","T8.7_10.8","T0.6_1.6","NIR1.6","WV6.2")
  xderivTexture=c(variables,derivVariables[-length(derivVariables)])
}

if (datasetTime=="inb"){
  
  variables<-c("IR3.9","WV6.2","WV7.3","IR8.7",
               "IR9.7","IR10.8","IR12.0","IR13.4")
  
  derivVariables=c("T6.2_10.8","T7.3_12.0","T8.7_10.8","T10.8_12.0","T3.9_7.3",
                   "T3.9_10.8","sunzenith")
  
#  xderivTexture=c("IR9.7","IR13.4","T8.7_10.8","T7.3_12.0","WV6.2")
  xderivTexture=c(variables,derivVariables[-length(derivVariables)])
}

if (datasetTime=="night"){
  
  variables<-c("IR3.9","WV6.2","WV7.3","IR8.7",
               "IR9.7","IR10.8","IR12.0","IR13.4")
  
  derivVariables=c("T6.2_10.8","T7.3_12.0","T8.7_10.8","T10.8_12.0","T3.9_7.3",
                   "T3.9_10.8")
  
#  xderivTexture=c("IR13.4","WV6.2","IR9.7","T8.7_10.8","T7.3_12.0")
  xderivTexture=c(variables,derivVariables[-length(derivVariables)])
}


################################################################################
#                           Load libraries
################################################################################

library(raster)
setwd(msgpath)
datatable=data.frame()

source(paste0(functionpath,"geometryParameters.R"))
source(paste0(functionpath,"TextureParameters.R"))
source(paste0(functionpath,"glcmPerPatch.R"))


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

      T0.6_1.6 <- scenerasters$VIS0.6-scenerasters$NIR1.6
      T6.2_10.8 <- scenerasters$WV6.2-scenerasters$IR10.8
      T7.3_12.0 <- scenerasters$WV7.3-scenerasters$IR12.0
      T8.7_10.8 <- scenerasters$IR8.7-scenerasters$IR10.8
      T10.8_12.0 <- scenerasters$IR10.8-scenerasters$IR12.0
      T3.9_7.3 <- scenerasters$IR3.9-scenerasters$WV7.3
      T3.9_10.8 <- scenerasters$IR3.9-scenerasters$IR10.8
      scenerasters<-stack(scenerasters,T0.6_1.6,T6.2_10.8,T7.3_12.0,T8.7_10.8,
                          T10.8_12.0,T3.9_7.3,T3.9_10.8,sunzenith)
      names(scenerasters)=c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3",
                            "IR8.7","IR9.7","IR10.8","IR12.0","IR13.4",
                            "T0.6_1.6","T6.2_10.8","T7.3_12.0","T8.7_10.8",
                            "T10.8_12.0","T3.9_7.3","T3.9_10.8","sunzenith")
      scenerasters<-scenerasters[[c(variables,derivVariables)]]
      names(scenerasters)<- c(variables,derivVariables)
    
### Texture parameters #########################################################
      glcm_filter <- texture.variables (x=scenerasters[[xderivTexture]],
                                        n_grey = 32,filter=c(3),    
                                        var=c("mean", "variance", "homogeneity", 
                                                      "contrast", "dissimilarity", 
                                                      "entropy","second_moment"))


### Geometry parameters #########################################################
      cloud_geometry <- geometry.variables (x=scenerasters[[4]])

### Texture per Patch ##########################################################
      glcmPatches<-glcmPerPatch(x=scenerasters[[xderivTexture]],cloud_geometry$cloudPatches)
      glcmPerPatchRaster<-foreach(i=2:ncol(glcmPatches),.combine=stack,
          .packages=c("raster","doParallel"))%dopar%{
            reclassify(cloud_geometry$cloudPatches,matrix(c(
              glcmPatches[,1],glcmPatches[,i]),ncol=2))}
      reclasstable=cbind(1:max(values(cloud_geometry$cloudPatches),na.rm=TRUE),
                         1:max(values(cloud_geometry$cloudPatches),
                               na.rm=TRUE)%in%glcmPatches[,1])
      reclasstable[reclasstable[,2]==0,2]=NA
      reclasstable[!is.na(reclasstable[,2]),2]=reclasstable[!is.na(reclasstable[,2]),1]
      reclasstable=reclasstable[is.na(reclasstable[,2]),]
      if (nrow(glcmPatches)==1){
        glcmPerPatchRaster=reclassify(glcmPerPatchRaster,matrix(reclasstable,ncol=2))
      } else{
        glcmPerPatchRaster=reclassify(glcmPerPatchRaster,reclasstable)
      }
      names(glcmPerPatchRaster)<-colnames(glcmPatches)[-1]
      names(glcmPerPatchRaster)=paste0("pp_",names(glcmPerPatchRaster))
### zonal stat: Mean,sd,min,max per Pacth ######################################
      ZonalStats=cloud_geometry$cloudPatches
###mean
      tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
                     cloud_geometry$cloudPatches,fun="mean")
        MeanPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                             .packages=c("raster","doParallel"))%dopar%{
                               reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 
      names(MeanPerPatch)=paste0("mean_",names(scenerasters)[
        1:(nlayers(scenerasters)-1)])
###sd
      tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
                     cloud_geometry$cloudPatches,fun="sd")
      SdPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                         .packages=c("raster","doParallel"))%dopar%{
                           reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 

      names(SdPerPatch)=paste0("sd_",names(scenerasters)[
        1:(nlayers(scenerasters)-1)])
###min
      tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
               cloud_geometry$cloudPatches,fun="min")
      MinPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                   .packages=c("raster","doParallel"))%dopar%{
                     reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 
      names(MinPerPatch)=paste0("min_",names(scenerasters)[
        1:(nlayers(scenerasters)-1)])
###max
      tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
               cloud_geometry$cloudPatches,fun="max")
      MaxPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                    .packages=c("raster","doParallel"))%dopar%{
                      reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 
      names(MaxPerPatch)=paste0("max_",names(scenerasters)[
        1:(nlayers(scenerasters)-1)])

################################################################################
###             Compile data table
################################################################################
    
      glcm_3=as.data.frame(lapply(glcm_filter$size_3,values))
      names(glcm_3)<-paste0("f3_",names(glcm_3))

 
#      glcm_5=as.data.frame(lapply(glcm_filter$size_5,values))
#      names(glcm_5)<-paste0("f5_",names(glcm_5))

      reference<-eval(parse(text=paste0(referenceimage)))
      noDataIdentifier<-!is.na(values(radardata))&!is.na(values(reference))&!is.na(
        values(glcmPerPatchRaster$pp_contrast_T8.7_10.8))
      
      dayOfYear<-strptime(date, "%Y%m%d")$yday+1

      datatable <- rbind(datatable,
                         cbind(rep(date,sum(noDataIdentifier)),
                                coordinates(radardata)[noDataIdentifier,],
                                rep(dayOfYear,sum(noDataIdentifier)),
                               cbind(values(scenerasters))[noDataIdentifier,],
                               cbind(values(MeanPerPatch))[noDataIdentifier,],
                               cbind(values(SdPerPatch))[noDataIdentifier,],
                               cbind(values(MinPerPatch))[noDataIdentifier,],
                               cbind(values(MaxPerPatch))[noDataIdentifier,],
                               cbind(values(glcmPerPatchRaster))[noDataIdentifier,],
                               cbind(values(cloud_geometry))[noDataIdentifier,-1],
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

