################################################################################
# Create training tables from MSG and radar data
################################################################################
#script sperates between day,night and twilight scenes,
#calculate spectral derivates of the channnels, texture and geometry parameters

#Author:Hanna, January 2015
################################################################################
rm(list=ls())

################################################################################
#                           USER ADJUSTMENTS
################################################################################



msgpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"
radarpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/"
functionpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/functions/"

referenceimage<- "glcm_filter$size_5$IR3.9[[1]]"#"IR3.9" #This image will be used together with the radar data to define "no data"

datasetTime<-"day"

################################################################################
#                           Load libraries
################################################################################

library(raster)
setwd(msgpath)
datatable=data.frame()

source(paste0(functionpath,"geometryParameters.R"))
source(paste0(functionpath,"TextureParameters.R"))

################################################################################
#                           Start calculations
################################################################################

### Go through all months, days, hours and scenes ##############################
months=list.files()
for (i in months){
  setwd(paste0(msgpath,i)) 
  days=list.files()
  for (k in days){
    setwd(paste0(msgpath,i,"/",k))
    hours=list.files()
    for (l in hours){
      print (paste0("month: ", i, " day:", k, " hour: ", l, " in progress.."))
      setwd(paste0(msgpath,i,"/",k,"/",l))
      ### decide to which dataset it belongs (day,night, twilight)####################
      scenes=Sys.glob("*.rst")
      if (length(scenes)<12) {next} #if the folder contains not all necessary data
      
      sunzenith <- tryCatch(
        raster(scenes[substr(scenes,20,23) =="ma11"]), 
        error = function(e)e)
      
      if(inherits(sunzenith, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, " could not be processed"))
        next
      }
      
      meanzenith=mean(values(sunzenith))
      if (meanzenith>=70&datasetTime=="day") next
      if ((meanzenith<70|meanzenith>108)&datasetTime=="inb") next
      if (meanzenith<=108&datasetTime=="night") next
      
      ### get date and radar information ######################################################
      date = substr(scenes[1],1,12)
      radarpathtmp= paste0(radarpath,i,"/",k)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))
      radardata=raster(paste0(radarpathtmp,"/",tmp[substr(tmp,1,12)==date]))
      radardata[values(radardata)==-99]=NA
      ### only process data if they include at least 2000 rainy pixels (rainy=>0.06mm)
      if (sum(values(radardata)>0.06,na.rm=TRUE)<2000) next
      ### Load MSG data ##############################################################
      x=c("ca02p0001","ca02p0002","ca02p0003","ct01dk004","ct01dk005","ct01dk006",
          "ct01dk007","ct01dk008","ct01dk009","ct01dk010","ct01dk011")
      
      scenerasters <- tryCatch(
        stack(scenes[substr(scenes,20,28)%in%x]), 
        error = function(e) e)
      
      if(inherits(scenerasters, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, " could not be processed"))
        next
      }
      
      scenerasters=reclassify(scenerasters, cbind(-99,NA))
      names(scenerasters)<-c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                             "IR9.7","IR10.8","IR12.0","IR13.4")
      ### only process data if the MSG raster include valid data #####################
      #      if (sum(values(scenerasters),na.rm=TRUE)==0) next
      
      ################################################################################
      ###                 caluclate derivated variables 
      ################################################################################
      
      ### Meikes predictor variables #################################################
      T6.2_10.8 <- scenerasters$WV6.2-scenerasters$IR10.8
      T7.3_12.0 <- scenerasters$WV7.3-scenerasters$IR12.0
      T8.7_10.8 <- scenerasters$IR8.7-scenerasters$IR10.8
      T10.8_12.0 <- scenerasters$IR10.8-scenerasters$IR12.0
      T3.9_7.3 <- scenerasters$IR3.9-scenerasters$WV7.3
      T3.9_10.8 <- scenerasters$IR3.9-scenerasters$IR10.8
      scenerasters<-stack(scenerasters,T6.2_10.8,T7.3_12.0,T8.7_10.8,T10.8_12.0,T3.9_7.3,T3.9_10.8,sunzenith)
      names(scenerasters)<-c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                             "IR9.7","IR10.8","IR12.0","IR13.4","T6.2_10.8",
                             "T7.3_12.0","T8.7_10.8","T10.8_12.0","T3.9_7.3","T3.9_10.8","SunZenith")
      
      ### Texture parameters #########################################################
      glcm_filter <- texture.variables (x=scenerasters[[1:length(x)]],
                                        filter=c(3,5),var=c("mean", "variance", "homogeneity", 
                                                            "contrast", "dissimilarity", 
                                                            "entropy","second_moment"))
      ### Geometry parameters #########################################################
      cloud_geometry <- geometry.variables (x=scenerasters[[4]])
      ################################################################################
      ###             Compile data table
      ################################################################################
      
      glcm_3=as.data.frame(lapply(glcm_filter$size_3,values))
      names(glcm_3)<-paste0("f3_",names(glcm_3))
      
      glcm_5=as.data.frame(lapply(glcm_filter$size_5,values))
      names(glcm_5)<-paste0("f5_",names(glcm_5))
      
      #      reference<-eval(parse(text=paste0("scenerasters$",referenceimage)))
      reference<-eval(parse(text=paste0(referenceimage)))
      noDataIdentifier<-!is.na(values(radardata))&!is.na(values(reference))
      
      
      datatable <- rbind(datatable,cbind(rep(date,nrow(glcm_3[noDataIdentifier,])),
                                         coordinates(radardata)[noDataIdentifier,],
                                         cbind(values(scenerasters))[noDataIdentifier,],
                                         cbind(values(cloud_geometry))[noDataIdentifier,],
                                         glcm_3[noDataIdentifier,],glcm_5[noDataIdentifier,],
                                         values(radardata)[noDataIdentifier]))
      
      rm(scenerasters,cloud_geometry,glcm_3,glcm_5,glcm_filter,T6.2_10.8,T7.3_12.0,
         T8.7_10.8,T10.8_12.0,T3.9_7.3,T3.9_10.8,sunzenith,radardata,scenes,
         radarpathtmp,tmp,date)
      gc()      
      
      ### finish the script ##########################################################     
    }
  }
}

names(datatable)[1]="Date"
names(datatable)[2]="X"
names(datatable)[3]="Y"
names(datatable)[ncol(datatable)]="Radar"
save(datatable,file=paste0("/media/hanna/ubt_kdata_0005/improve_DE_retrieval/datatable_",datasetTime,".RData"))
