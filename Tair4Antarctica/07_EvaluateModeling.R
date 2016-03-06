rm(list=ls())
library(caret)
library(Rsenal)
library(hexbin)

load("/media/hanna/data/Antarctica/results/ML/testData.RData")
modeldats <- testData[,substr(names(testData),nchar(names(testData))-2,
                              nchar(names(testData)))=="Mod"]


for (i in 1:ncol(modeldats)){
  modeldat <-modeldats[,i]
  modelname<- substr(names(modeldats)[i],1,3)
  regstat <- regressionStats(modeldat,testData$statdat)
  
  ################################################################################
  ################################################################################
  pdf(paste0("/media/hanna/data/Antarctica/visualizations/evaluation_",
             modelname,"_hexbin.pdf"))
  ptxt<-paste0("R^2= ",sprintf("%.2f", round(regstat$Rsq,2)),
               "\nME = ",sprintf("%.2f", round(regstat$ME,2)),
               "\nMAE = ",sprintf("%.2f", round(regstat$MAE,2)),
               "\nRMSE = ",sprintf("%.2f", round(regstat$RMSE,2)))
  hbp <- hexbinplot(testData$statdat~modeldat,
                    xlim=c(min(testData$statdat,modeldat,na.rm=T),
                           max(testData$statdat,modeldat,na.rm=T)),
                    ylim=c(min(testData$statdat,modeldat,na.rm=T),
                           max(testData$statdat,modeldat,na.rm=T)),
                    ylab="Measured Air temperature (°C)", 
                    xlab="predicted derived Air temperature(°C)",
                    colramp=colorRampPalette(rev(terrain.colors(10))),
                    panel = function(...) {
                      panel.hexbinplot(...)
                      panel.abline(a=0,b=1,lwd=2)
                      panel.abline(lm(testData$statdat~modeldat),lwd=2,lty=2)
                      grid.text(ptxt, unit(0.10, 'npc'), unit(0.88, 'npc'))
                      
                    })
  print(hbp)
  dev.off()
}
#dazu noch die leave one station out cross validation ergebnisse

################################################################################
################################################################################

pdf(paste0("/media/hanna/data/Antarctica/visualizations/exactTimeEval_",modelname,"_timeseries.pdf"),
    width=8,height=7)

for (i in unique(testData$station)){
  dat_sort <- testData[testData$station==i,]
  dat_sort <- dat_sort[order(dat_sort$doy),]
  dat_sort <- dat_sort[complete.cases(dat_sort),]
  if (nrow(dat_sort)<10){next}
  obs <- smooth.spline(dat_sort$doy,dat_sort$statdat, spar=0.25)
  pred <- smooth.spline(dat_sort$doy,dat_sort$LST, spar=0.25)
  pred_ML <- smooth.spline(dat_sort$doy,dat_sort$MLPred, spar=0.25)
  pred_bc <- smooth.spline(dat_sort$doy,dat_sort$biascorr, spar=0.25)
  lim <- c(min(dat_sort$statdat,dat_sort$LST,na.rm=T),max(dat_sort$statdat,dat_sort$LST,na.rm=T))
  plot(obs,type="l",xlab="doy",ylab="Air Temperature (°C)",
       main=i,ylim=lim)
  lines(pred,col="black",lty=2)
  lines(pred_bc,col="red",lty=2)
  lines(pred_ML,col="red",lty=1)
  legend("bottomleft",legend=c("Stations","MODIS LST","Random Forests","Linear Model"),
         col=c("black","black","red","red"),lty=c(1,2,1,2),lwd=1,bty="n")
}

dat_sort <- testData[order(testData$doy),]
dat_sort <- dat_sort[complete.cases(dat_sort),]
dat_sort <- aggregate(x = data.frame(dat_sort$statdat,dat_sort$LST,dat_sort$MLPred,
                                     dat_sort$biascorr),
                      by = list(dat_sort$doy), FUN = "mean")
obs <- smooth.spline(1:365,dat_sort$dat_sort.statdat, spar=0.25)
pred <- smooth.spline(1:365,dat_sort$dat_sort.LST, spar=0.25)
pred_ML <- smooth.spline(1:365,dat_sort$dat_sort.MLPred, spar=0.25)
pred_bc <- smooth.spline(1:365,dat_sort$dat_sort.biascorr, spar=0.25)
lim <- c(min(dat_sort$dat_sort.statdat,dat_sort$dat_sort.LST,dat_sort$dat_sort.MLPred,na.rm=T),
         max(dat_sort$dat_sort.statdat,dat_sort$dat_sort.LST,dat_sort$dat_sort.MLPred,na.rm=T))
plot(obs,type="l",xlab="doy",ylab="Air Temperature (°C)",
     main="all stations",ylim=lim)
lines(pred,col="black",lty=2)
lines(pred_bc,col="red",lty=2)
lines(pred_ML,col="red",lty=1)
legend("bottomleft",legend=c("Stations","MODIS LST","Random Forests","Linear Model"),
       col=c("black","black","red","red"),lty=c(1,2,1,2),lwd=1,bty="n")
dev.off()
#######################################
pdf("/media/hanna/data/Antarctica/visualizations/exactTimeEval_rf_varimp.pdf")
plot(varImp(model),col="black")
dev.off()