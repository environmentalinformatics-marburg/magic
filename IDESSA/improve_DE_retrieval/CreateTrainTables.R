rm(list=ls())
msgpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/MSG/2010/"
radarpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/Radar/2010/"
resultpath="/media/memory18201/casestudies/hmeyer/Improve_DE_retrieval/results"
samplesize=0.1 # number of scenes for training
y<-2010 # year
daytime <- c("day","twilight","night")

library(Rainfall)


load(paste0(resultpath,"/rainevents.RData"))
trsc=1
trainingsc<-list()
for (dayt in daytime) {
  
  ### Definde training scenes ##################################################
#  scenes<-list.dirs(msgpath,recursive=TRUE)
#  trainingscenes<-randomScenes(sampsize=samplesize,seed=50)
  
  ###neu:
  ts <- rainevents[rainevents$daytime==dayt,]
  set.seed(20)
  ts <- ts[sample(nrow(ts),samplesize*nrow(ts)),]
  trainingscenes <- as.vector(paste0(y,ts[,1],ts[,2],ts[,3]))
  print (paste0("trainingscenes for ", dayt,": "))
  print (trainingscenes)
  trainingsc[[trsc]]<-trainingscenes
  trsc=trsc+1

  ### set global min/max values for each channel
  min_x <- c(0.08455839,0.05533640,0.02237568,156.625000,210.00000000,
             208.75000000,209.62500000,213.750000,208.62500000,208.50000000,
             210.437500,-0.21682912,-67.85000610,-40.55001831,-4.875000,
             -2.05001831,-64.875000,-70.250000)
  names(min_x) <-  c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                     "IR9.7","IR10.8","IR12.0","IR13.4","T0.6_1.6","T6.2_10.8",
                     "T7.3_12.0","T8.7_10.8","T10.8_12.0", "T3.9_7.3",
                     "T3.9_10.8")
  
  max_x <- c(1.3163714,1.4401436,0.9915133,306.2749939,246.6875000,261.3750000, 
             296.0999756,263.0000000,299.1000061,294.6500244,267.5499878,
             0.8078508,2.812500,12.737503,8.3750000,10.6625061,60.9874878,
             59.8000183) 
  names(max_x) <-  names(min_x)
### define variables ###########################################################  
#  if (dayt=="twilight"||dayt=="night"){
#    min_x=min_x[4:length(min_x)]
#    max_x=max_x[4:length(max_x)]
#  }
  
  if (dayt=="day"){
    spectral <- c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                  "IR9.7","IR10.8","IR12.0","IR13.4","T0.6_1.6","T6.2_10.8",
                  "T7.3_12.0", "T8.7_10.8","T10.8_12.0", "T3.9_7.3","T3.9_10.8")
    further <- c("sunzenith","jday")
  }
  
  if (dayt=="twilight"){
    spectral <- c("IR3.9","WV6.2","WV7.3","IR8.7",
                  "IR9.7","IR10.8","IR12.0","IR13.4","T6.2_10.8","T7.3_12.0", 
                  "T8.7_10.8","T10.8_12.0", "T3.9_7.3","T3.9_10.8")
    further <- c("sunzenith","jday")
  }
  if (dayt=="night"){
    spectral <- c("IR3.9","WV6.2","WV7.3","IR8.7",
                  "IR9.7","IR10.8","IR12.0","IR13.4","T6.2_10.8","T7.3_12.0", 
                  "T8.7_10.8","T10.8_12.0", "T3.9_7.3","T3.9_10.8")
    further <- c("jday")
  }
  
  
  texture<- expand.grid(spectral,c("mean", "variance", "homogeneity", 
                                   "contrast", "dissimilarity", 
                                   "entropy","second_moment"),c(3,5))
  filterstat<-expand.grid(spectral,c("mean", "sd", "min", "max"),c(3,5))
  pptext=NULL
  shape=NULL
  zonstat=NULL
  
### Calculate variables ########################################################  
  
  datatable=data.frame()
  setwd(msgpath)
  
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
        ### get sunzenith  #####################################################
        sunzenith<-tryCatch(getSunzenith(getwd()),error = function(e)e)
        if(inherits(sunzenith, "error")) {
          print (paste0("month ", i, " day ", k, " scene ", l, 
                        " could not be processed"))
          next
        }
#        if(getDaytime(sunzenith)!=dayt) next
        ### get radar ##########################################################
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
        
        ### only process data if the MSG raster include valid data #############
        if(min(values(is.na(scenerasters)))==1) next
        ###... or at least 50 cloud pixels (otherwise texture might not work)
        if(sum(!is.na(values((scenerasters))))<50) next
        
        ### calculate predictors ###############################################
        pred<-calculatePredictors(scenerasters,sunzenith=sunzenith,
                                  spectral=spectral,texture=texture,
                                  shape=shape,further=further,pptext=pptext,
                                  zonstat=zonstat,filterstat=filterstat,
                                  date=date,min_x=min_x,max_x=max_x)
        pred<-stack(pred,radardata)
        names(pred)[nlayers(pred)]="Radar"
        dt <- cbind(rep(date,ncell(pred)),coordinates(pred),as.data.frame(pred))
        rm(list=c("pred","scenerasters","radardata","sunzenith","tmp",
                  "date","radarpathtmp"))
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
  
  save(datatable,file=paste0(resultpath,"/datatable_",dayt,".RData"))
}            

save(trainingsc,file=paste0(resultpath,"/trainingscenes.RData"))
