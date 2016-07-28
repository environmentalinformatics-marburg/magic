rm(list=ls())
library(caret)
library(Rsenal)
library(hexbin)
library(grid)
library(viridis)



load("/media/hanna/data/Antarctica/results/MLFINAL//testData_comparison.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL//dataset.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL//model_GBM.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL//model_LIN.RData")
dataset$gbmMod <- predict(model_GBM,data.frame("LST"=dataset$LST,"month"=dataset$month))
dataset$linMod <- predict(model_LIN,data.frame("LST"=dataset$LST))


pdf(paste0("/media/hanna/data/Antarctica/visualizations/GBM_timeseries_full_V3.pdf"),
    width=11,height=8) 
par(mfrow=c(2,2),mar=c(4,4,2,2))
dataset_sub<-dataset[dataset$station%in%c("Henry","brownworth_met","BullPass"),]
acc <- 0
regstat_lin <- c()
regstat_ML <- c()
regstat_LST <- c()
acc <- 0
for (i in unique(dataset_sub$station)){
  acc <- acc+1
  dat_sort <- dataset_sub[dataset_sub$station==i,]
  dat_sort <- dat_sort[order(dat_sort$doy),]
  dat_sort <- dat_sort[complete.cases(dat_sort),]
  if (nrow(dat_sort)<10){next}
  obs <- smooth.spline(dat_sort$doy,dat_sort$statdat, spar=0.25)
  pred <- smooth.spline(dat_sort$doy,dat_sort$LST, spar=0.25)
  pred_ML <- smooth.spline(dat_sort$doy,dat_sort$gbmMod, spar=0.25)
  pred_lin <- smooth.spline(dat_sort$doy,dat_sort$lin, spar=0.25)
  regstat_lin <- rbind(regstat_lin,regressionStats(dat_sort$lin,dat_sort$statdat))
  regstat_ML <- rbind(regstat_ML,regressionStats(dat_sort$gbmMod,dat_sort$statdat))
  regstat_LST <- rbind(regstat_LST,regressionStats(dat_sort$LST,dat_sort$statdat))
  lim <- c(min(pred_lin$data$y,obs$data$y,na.rm=T),max(pred_lin$data$y,obs$data$y,na.rm=T))
  plot(obs,type="l",xlab="Day of Year",ylab="Air Temperature (°C)",
       main="",ylim=lim)

  lines(pred,col="black",lty=2)
  lines(pred_lin,col="blue",lty=1)
  lines(pred_ML,col="dark orange",lty=1)
  legend("top",legend=c("Stations","MODIS LST",
                        paste0("GBM (R^2= ",round(regstat_ML$Rsq[acc],2),", RMSE= ",
                               round(regstat_ML$RMSE[acc],2),")"),
                        paste0("Linear Model (R^2= ",round(regstat_lin$Rsq[acc],2),", RMSE= ",
                               round(regstat_lin$RMSE[acc],2),")")),
         col=c("black","black","dark orange","blue"),lty=c(1,2,1,1),lwd=1,bty="n",cex=0.9)
}

dat_sort <- dataset[order(dataset$doy),] 
dat_sort <- dat_sort[complete.cases(dat_sort),] 
dat_sort <- aggregate(x = data.frame(dat_sort$statdat,dat_sort$LST,dat_sort$gbmMod,
                                     dat_sort$linMod),
                      by = list(dat_sort$doy), FUN = "mean")
obs <- smooth.spline(1:365,dat_sort$dat_sort.statdat, spar=0.25)
pred <- smooth.spline(1:365,dat_sort$dat_sort.LST, spar=0.25)
pred_ML <- smooth.spline(1:365,dat_sort$dat_sort.gbmMod, spar=0.25)
pred_lin <- smooth.spline(1:365,dat_sort$dat_sort.linMod, spar=0.25)

regstat_lin <- rbind(regstat_lin,regressionStats(dat_sort$dat_sort.linMod,dat_sort$dat_sort.statdat))
regstat_ML <- rbind(regstat_ML,regressionStats(dat_sort$dat_sort.gbmMod,dat_sort$dat_sort.statdat))
regstat_LST <- rbind(regstat_LST,regressionStats(dat_sort$dat_sort.LST,dat_sort$dat_sort.statdat))

lim <- c(min(dat_sort$dat_sort.statdat,dat_sort$dat_sort.LST,dat_sort$dat_sort.gbmMod,na.rm=T),
         max(dat_sort$dat_sort.statdat,dat_sort$dat_sort.LST,dat_sort$dat_sort.gbmMod,na.rm=T))
plot(obs,type="l",xlab="Day of Year",ylab="Air Temperature (°C)",
     main="",ylim=lim)
lines(pred,col="black",lty=2)
lines(pred_lin,col="blue",lty=1)
lines(pred_ML,col="dark orange",lty=1)
legend("top",legend=c("Stations","MODIS LST",
                      paste0("GBM (R^2= ",round(regstat_ML$Rsq[4],2),", RMSE= ",
                             round(regstat_ML$RMSE[4],2),")"),
                      paste0("Linear Model (R^2= ",round(regstat_lin$Rsq[4],2),", RMSE= ",
                             round(regstat_lin$RMSE[4],2),")")),
       col=c("black","black","dark orange","blue"),lty=c(1,2,1,1),lwd=1,bty="n",cex=0.9)
dev.off()