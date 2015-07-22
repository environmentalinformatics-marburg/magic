rm(list=ls())
library(Rainfall)
library(raster)
msgpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/MSGProj/2010/"
radarpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/RadarProj/2010/"
resultpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/results"




rainevents=data.frame(matrix(ncol = 4, nrow = 1))
names(rainevents)=c("month","day","hour","daytime")
setwd(msgpath)

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
      date=getDate(getwd(),type=".tif")
      
      sunzenith<-tryCatch(getSunzenith(getwd(),type=".tif"),error = function(e)e)
      if(inherits(sunzenith, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed. Sunzenith not valid."))
        next
      }
      act_daytime <- tryCatch(getDaytime(sunzenith),error = function(e)e)
      if(inherits(act_daytime, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed. daytime not valid"))
        next
      }
      
      #radarpathtmp= paste0(radarpath,i,"/",k)
      #tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))
      radarpathtmp= paste0(radarpath,i,"/",k,"/",l)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.tif"))
      radardata=tryCatch(raster(paste0(radarpathtmp,"/",tmp)),error = function(e)e)
      #radardata=tryCatch(raster(paste0(radarpathtmp,"/",tmp[substr(tmp,1,12)==date])),error = function(e)e)
      if(inherits(radardata, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed. radardata not valid."))
        next
      }
      radardata[values(radardata)==-99]=NA
      rainpixels <- sum(values(radardata)>0.06,na.rm=T)
      if (rainpixels > 2500){
        rainevents=rbind(rainevents,c(i,k,l,act_daytime) )       
      }
    }
  }
}
rainevents<-rainevents[-1,]
save(rainevents, file=paste0(resultpath,"/datatables/rainevents.RData"))
