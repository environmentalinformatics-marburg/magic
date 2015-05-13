rm(list=ls())
library(Rainfall)
msgpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/MSG/2010/"
radarpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/Radar/2010/"
resultpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results"




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
      date=getDate(getwd())
      
      sunzenith<-tryCatch(getSunzenith(getwd()),error = function(e)e)
      if(inherits(sunzenith, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed"))
        next
      }
      act_daytime <- getDaytime(sunzenith)
      
      radarpathtmp= paste0(radarpath,i,"/",k)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))

      radardata=tryCatch(raster(paste0(radarpathtmp,"/",tmp[substr(tmp,1,12)==date])),error = function(e)e)
      if(inherits(radardata, "error")) {
        print (paste0("month ", i, " day ", k, " scene ", l, 
                      " could not be processed"))
        next
      }
      radardata[values(radardata)==-99]=NA
      rainpixels <- sum(values(radardata)>0.06,na.rm=T)
      if (rainpixels > 2000){
        rainevents=rbind(rainevents,c(i,k,l,act_daytime) )       
      }
    }
  }
}
rainevents<-rainevents[-1,]
save(rainevents, file=paste0(resultpath,"/rainevents.RData"))