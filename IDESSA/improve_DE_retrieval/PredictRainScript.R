### Prediction ################

library(Rainfall)
library(Rsenal)

resultpath<-"/media/hanna/ubt_kdata_0005/improve_DE_retrieval/"
radarpath<-"/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/"
msgpath <- "/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"
datasetTime<-"day"
responseName<-"Rain"

load(paste0(resultpath,"/trainedModel_",datasetTime,"_",responseName,".Rdata"))
load(paste0(resultpath,"rainevents.Rdata"))
rainevents <- rainevents[rainevents$daytime=="day",]

### set global min/max values for each channel
min_x <- c(0.08455839,0.05533640,0.02237568,156.625000,210.00000000,208.75000000,
           209.62500000,213.750000,208.62500000,208.50000000,210.437500,-0.21682912, 
           -67.85000610,-40.55001831,-4.875000,-2.05001831,-64.875000,-70.250000)
names(min_x) <-  c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                   "IR9.7","IR10.8","IR12.0","IR13.4","T0.6_1.6","T6.2_10.8","T7.3_12.0", 
                   "T8.7_10.8","T10.8_12.0", "T3.9_7.3","T3.9_10.8")

max_x <- c(1.3163714,1.4401436,0.9915133,306.2749939,246.6875000,261.3750000, 
           296.0999756,263.0000000,299.1000061,294.6500244,267.5499878,0.8078508, 
           2.812500,12.737503,8.3750000,10.6625061,60.9874878,59.8000183) 
names(max_x) <-  names(min_x)



evaluation=data.frame(matrix(ncol=7))
names(evaluation)=c("ME","ME.se","MAE","MAE.se","RMSE","RMSE.se","Rsq")
for (i in 1:nrow(rainevents)){
  testmonth=rainevents[i,1]
  testday=rainevents[i,2]
  time=rainevents[i,3]
  exacttime=paste0(time,"50")
  reference=raster(paste0(radarpath,"/",testmonth,"/",testday,"/2010",testmonth,testday,exacttime,"_radolan_SGrid.rst"))
  values(reference)[values(reference<0.06)]=NA
  #plot(reference)
  pred<-predictRainfall(model=model, inpath= paste0(msgpath,"/",testmonth,"/",
                                                    testday,"/",time,"/"),
                        rainmask=reference,min_x=min_x,max_x=max_x)
  reference=mask(reference,pred)
  evaluation[i,]=validate(obs=reference,pred=pred)
  print (i)
}

### save evaluation
save(evaluation,file=paste0(resultpath,"/validation_",datasetTime,"_",responseName,".Rdata"))

###direct comparison mit nur kanäle...
