rm(list=ls())
msgpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/MSG/2010/"
radarpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/Radar/2010/"
resultpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results"

library(Rainfall)

datasetTime<-"day"
samplesize=0.1 # number of scenes for training




### Definde variables ##########################################################
scenes<-list.dirs(msgpath,recursive=TRUE)
trainingscenes<-randomScenes(sampsize=samplesize,seed=50)

if (datasetTime=="day"){
  spectral <- c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
  "IR9.7","IR10.8","IR12.0","IR13.4","T0.6_1.6","T6.2_10.8","T7.3_12.0", 
  "T8.7_10.8","T10.8_12.0", "T3.9_7.3","T3.9_10.8")
  texture<- expand.grid(spectral,c("mean", "variance", "homogeneity", 
                                       "contrast", "dissimilarity", 
                                       "entropy","second_moment"),c(3,5))
  filterstat<-expand.grid(spectral,c("mean", "sd", "min", "max"),c(3,5))
  pptext=NULL
  shape=c("distEdges")
  zonstat=NULL
  further=c("sunzenith","jday")
  
}

datatable=data.frame()
setwd(msgpath)

y<-2010
months=list.files()
for (i in months){
  setwd(paste0(msgpath,i)) 
  days=list.files()
  for (k in days){
    setwd(paste0(msgpath,i,"/",k))
    hours=list.files()
    for (l in hours){
      if(!paste0(y,i,k,l)%in%trainingscenes) next #use only trainingscenes
      print (paste0("month: ", i, " day:", k, " hour: ", l, " in progress.."))
      setwd(paste0(msgpath,i,"/",k,"/",l))
      date=getDate(getwd())
      ### get sunzenith  #######################################################
      sunzenith<-tryCatch(getSunzenith(getwd()),error = function(e)e)
      if(inherits(sunzenith, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed"))
        next
      }
      if(getDaytime(sunzenith)!=datasetTime) next
      ### get radar ###########################################################
      radarpathtmp= paste0(radarpath,i,"/",k)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))
      radardata=raster(paste0(radarpathtmp,"/",tmp[substr(tmp,1,12)==date]))
      radardata[values(radardata)==-99]=NA
      ### get MSG ###########################################################
      scenerasters <- tryCatch(getChannels(getwd()),error = function(e)e)
      if(inherits(scenerasters, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed"))
        next
      }

      ### only process data if the MSG raster include valid data #####################
      if(min(values(is.na(scenerasters)))==1) next
      ###... or at least 50 cloud pixels (otherwise texture might not work)
      if(sum(!is.na(values((scenerasters))))<50) next
      
      ### calculate predictors #################################################
      pred<-calculatePredictors(scenerasters,sunzenith=sunzenith,spectral=spectral,texture=texture,
                          shape=shape,further=further,pptext=pptext,zonstat=zonstat,
                          date=date)
      pred<-stack(pred,radardata)
      names(pred)[nlayers(pred)]="Radar"
      dt <- cbind(rep(date,ncell(pred)),coordinates(pred),as.data.frame(pred))
      rm(list=c("pred","scenerasters","radardata","sunzenith","tmp","date","radarpathtmp"))
      gc()
      dt<-dt[complete.cases(dt),]
      datatable <- rbind(datatable,dt)
      rm("dt")
      gc()
    }
  }
}

names(datatable)[1]="Date"
names(datatable)[2]="X"
names(datatable)[3]="Y"

print(warnings())

save(datatable,file=paste0(resultpath,"/datatableV2_",datasetTime,".RData"))
                
      
      
      