#09_evaluateModel


#07 run ffs
rm(list=ls())
library(caret)
library(raster)
library(rgdal)
library(Rsenal)
library(viridis)
#mainpath <- "/mnt/sd19007/users/hmeyer/Antarctica/ReModel2017/"
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")
modelpath <- paste0(datapath, "/modeldat/")
predpath <- paste0(datapath, "/predictions/")
MODISpath <- paste0(mainpath,"/MODISLST/")
vispath <- datapath <- paste0(mainpath,"/visualizations/")

tmppath <- paste0(mainpath,"/tmp/")
rasterOptions(tmpdir = tmppath)
model <- get(load(paste0(modelpath,"model_final.RData")))
testdat <- get(load(paste0(modelpath,"testingDat.RData")))


testdat$prediction <- predict(model,testdat)

dat <- testdat[,names(testdat)%in%c("Temperature","prediction")]

pdf(paste0(vispath,"/externalvalidation.pdf"),width=6,height=5)
ggplot(testdat, aes(Temperature,prediction)) + 
  stat_binhex(bins=100)+
  xlim(min(dat),max(dat))+ylim(min(dat),max(dat))+
  xlab("Measured Tair (°C)")+
  ylab("Predicted Tair (°C)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:3),colors=viridis(10))
dev.off()

regressionStats()