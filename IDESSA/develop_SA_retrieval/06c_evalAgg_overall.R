#This script temporally aggregates the rainfall model predictions and validates
#and visualizes on the different temporal scales. Use the results of "evaluateModels.R"

rm(list=ls())
library(Rsenal)
library(viridis)
library(latticeExtra)

datapath <- "/media/memory01/data/IDESSA/Results/Evaluation/"
figurepath <- "/media/memory01/data/IDESSA/Results/Figures/"
#datapath <- "/media/hanna/data/CopyFrom181/Results/Evaluation/"
#figurepath <- "/media/hanna/data/CopyFrom181/Results/Figures/"

#setwd("/media/memory01/data/IDESSA/Results/Evaluation/")

raineventsthres <- 5 # threshold. validate only rate quantity if the number
#of stations that observed rainfall is higher than "raineventsthres"

comp <- get(load(paste0(datapath,"evaluationData_all.RData")))

comp <- comp[substr(comp$Date,1,4)=="2013",]




################################################################################
comp$Month <- substr(comp$Date,1,6)

comp$Day <- substr(comp$Date,1,8)

mydf <- as.Date(comp$Day, format="%Y%m%d")
weeknum <- as.numeric( format(mydf+3, "%U"))

comp$Week <- paste0(substr(comp$Date,1,4), sprintf("%02d",weeknum))




comp_agg_day <- aggregate(comp[,names(comp)%in%c("RR_obs","RR_pred")],
                          by=list(comp$Day,comp$Station),sum,na.rm=TRUE)
comp_agg_week <- aggregate(comp[,names(comp)%in%c("RR_obs","RR_pred")],
                           by=list(comp$Week,comp$Station),sum,na.rm=TRUE)
comp_agg_month <- aggregate(comp[,names(comp)%in%c("RR_obs","RR_pred")],
                            by=list(comp$Month,comp$Station),sum,na.rm=TRUE)





################################################################################
#Rainfall rate 
################################################################################
####### Hourly
 rainstats_raw <- data.frame()
 for (i in unique(comp$Date)){
   subs <- comp[comp$Date==i,]
#   if (nrow(subs)<5){next}
   regMSG <- tryCatch(regressionStats(subs$RR_pred,
                                      subs$RR_obs,method="spearman"),  error = function(e)e)
   if (inherits(regMSG,"error")){next}
   rainstats_raw <- rbind(rainstats_raw,
                          data.frame("Date"=i,
                                     "eventsObs" = sum(subs$RR_obs>0),
                                     "eventsPred" = sum(subs$RR_pred>0),
                                     regMSG))
 } 
 
 
 rainstats_raw$rho[rainstats_raw$eventsObs<raineventsthres] <- NA
  ####### Daily
 
 rainstats_day <- data.frame()
 for (i in unique(comp_agg_day$Group.1)){
   subs <- comp_agg_day[comp_agg_day$Group.1==i,]
#   if (nrow(subs)<5){next}
   rainstats_day <- rbind(rainstats_day,
                      regressionStats(subs$RR_pred,
                                      subs$RR_obs,method="spearman"))
 }
 ####### Weekly
 rainstats_week <- data.frame()
 for (i in unique(comp_agg_week$Group.1)){
   subs <- comp_agg_week[comp_agg_week$Group.1==i,]
 #  if (nrow(subs)<5){next}
   rainstats_week <- rbind(rainstats_week,
                          regressionStats(subs$RR_pred,
                                          subs$RR_obs,method="spearman"))
 }
 
 ####### Monthly
 rainstats_month <- data.frame()
 for (i in unique(comp_agg_month$Group.1)){
   subs <- comp_agg_month[comp_agg_month$Group.1==i,]
 #  if (nrow(subs)<5){next}
   rainstats_month <- rbind(rainstats_month,
                           regressionStats(subs$RR_pred,
                                           subs$RR_obs,method="spearman"))
 }

 ############################################################
 #Plot
 ############################################################
Lab.palette <- colorRampPalette(c("white",rev(viridis(10))))
hourplot <- xyplot(comp$RR_pred~comp$RR_obs,
                          panel = panel.smoothScatter,nrpoints=0,colramp=Lab.palette,
                          nbin=500,bandwidth=c(0.3,0.3),
                          xlim=c(-2,70),ylim=c(-2,70),
                          xlab="Measured Rainfall (mm)", ylab="Predicted Rainfall (mm)")

dayplot <- xyplot(comp_agg_day$RR_pred~comp_agg_day$RR_obs,
                         panel = panel.smoothScatter,nrpoints=0,colramp=Lab.palette,
                         nbin=500,bandwidth=c(0.5,0.5),
                         xlim=c(-2,200),ylim=c(-2,200),
                         xlab="Measured Rainfall (mm)", ylab="Predicted Rainfall (mm)")

weekplot <- xyplot(comp_agg_week$RR_pred~comp_agg_week$RR_obs,
                   panel = panel.smoothScatter,nrpoints=0,colramp=Lab.palette,
                          nbin=500,bandwidth=c(1,1),
                          xlim=c(-2,250),ylim=c(-2,250),
                          xlab="Measured Rainfall (mm)", ylab="Predicted Rainfall (mm)")

monthplot <- xyplot(comp_agg_month$RR_pred~comp_agg_month$RR_obs,
                    panel = panel.smoothScatter, nrpoints=0,colramp=Lab.palette,
                    nbin=500,bandwidth=c(2,2),
                           xlim=c(-2,450),ylim=c(-2,450),
                           col="black",
                           xlab="Measured Rainfall (mm)", ylab="Predicted Rainfall (mm)")

hourplot <- update(hourplot,panel = function(...) {
  panel.smoothScatter(...)
  panel.text(x=hourplot$x.limits[2]*0.15,y=hourplot$y.limits[2]*0.95,
             labels = paste0("rho = ", round(mean(rainstats_raw$rho,na.rm=TRUE),2)))
})+
  layer(panel.abline(a=0,b=1,lty=2))

dayplot <- update(dayplot,panel = function(...) {
  panel.smoothScatter(...)
  panel.text(x=dayplot$x.limits[2]*0.15,y=dayplot$y.limits[2]*0.95,
             labels = paste0("rho = ", round(mean(rainstats_day$rho,na.rm=TRUE),2)))
})+
  layer(panel.abline(a=0,b=1,lty=2))

weekplot <- update(weekplot,panel = function(...) {
  panel.smoothScatter(...)
  panel.text(x=weekplot$x.limits[2]*0.15,y=weekplot$y.limits[2]*0.95,
             labels = paste0("rho = ", round(mean(rainstats_week$rho,na.rm=TRUE),2)))
})+
  layer(panel.abline(a=0,b=1,lty=2))

monthplot <- update(monthplot,panel = function(...) {
  panel.smoothScatter(...)
  panel.text(x=monthplot$x.limits[2]*0.15,y=monthplot$y.limits[2]*0.95,
             labels = paste0("rho = ", round(mean(rainstats_month$rho,na.rm=TRUE),2)))
})+
  layer(panel.abline(a=0,b=1,lty=2))

aggplots<-c(weekplot,monthplot,hourplot,dayplot)



pdf(paste0(figurepath,"RainfallAgg.pdf"),width=8,height=8)
aggplots
dev.off()

png(paste0(figurepath,"RainfallAgg.png"),
    width=16,height=16,units="cm",res = 600,type="cairo")
aggplots
dev.off()
