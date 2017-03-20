#This script temporally aggregates the rainfall model predictions and validates
#and visualizes on the different temporal scales. Use the results of "evaluateModels.R"

rm(list=ls())
library(Rsenal)
library(viridis)
library(latticeExtra)
library(ggplot2)

#datapath <- "/media/memory01/data/IDESSA/Results/Evaluation/"
#figurepath <- "/media/memory01/data/IDESSA/Results/Figures/"
datapath <- "/media/hanna/data/CopyFrom181/Results/Evaluation/"
#figurepath <- "/media/hanna/data/CopyFrom181/Results/Figures/"
figurepath <- "/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_SARetrieval/Submission2/Revision/additionals/"
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
#Lab.palette <- colorRampPalette(c("white",rev(viridis(10))))

labraw <- paste0("rho = ", round(mean(rainstats_raw$rho,na.rm=TRUE),2),
                 "; RMSE = ",round(mean(rainstats_raw$RMSE,na.rm=TRUE),2))
labday <- paste0("rho = ", round(mean(rainstats_day$rho,na.rm=TRUE),2),
                 "; RMSE = ",round(mean(rainstats_day$RMSE,na.rm=TRUE),2))
labweek <- paste0("rho = ", round(mean(rainstats_week$rho,na.rm=TRUE),2),
                  "; RMSE = ",round(mean(rainstats_week$RMSE,na.rm=TRUE),2))
labmonth <- paste0("rho = ", round(mean(rainstats_month$rho,na.rm=TRUE),2),
                   "; RMSE = ",round(mean(rainstats_month$RMSE,na.rm=TRUE),2))

hourplot <- ggplot(comp, aes(RR_obs,RR_pred)) + 
  stat_binhex(bins=70)+ 
  xlab("Measured Rainfall (mm)")+
  ylab("Estimated Rainfall (mm)")+
  labs(title="(a)")+
  geom_abline(slope=1, intercept=1,lty=2)+
  xlim(-2,70)+ylim(-2,70)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:7),colors=viridis(10))+
  annotate("text",  x=-Inf, y = Inf, label = labraw, vjust=1.2, hjust=-0.0,size=3)
  #geom_text(aes(x=-Inf,y=Inf,vjust=1.5,hjust=-0.1),size = 4,
  #          label=labraw)

dayplot <- ggplot(comp_agg_day, aes(RR_obs,RR_pred)) + 
  stat_binhex(bins=50)+
  xlab("Measured Rainfall (mm)")+
  ylab("Estimated Rainfall (mm)")+
  labs(title="(b)")+
  geom_abline(slope=1, intercept=1,lty=2)+
  xlim(-2,200)+ylim(-2,200)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:4),colors=viridis(10))+
  annotate("text",  x=-Inf, y = Inf, label = labday, vjust=1.2, hjust=-0.0,size=3)
  #geom_text(aes(x=-Inf,y=Inf,vjust=1.5,hjust=-0.1),size = 4,
  #          label=labday)

weekplot <- ggplot(comp_agg_week, aes(RR_obs,RR_pred)) + 
  stat_binhex(bins=40)+
  xlab("Measured Rainfall (mm)")+
  ylab("Estimated Rainfall (mm)")+
  labs(title="(c)")+
  geom_abline(slope=1, intercept=1,lty=2)+
  xlim(-2,250)+ylim(-2,250)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:4),colors=viridis(10))+
  annotate("text",  x=-Inf, y = Inf, label = labweek, vjust=1.2, hjust=-0.0,size=3)
  #geom_text(aes(x=-Inf,y=Inf,vjust=1.5,hjust=-0.1),size = 4,
   #         label=labweek)

monthplot <- ggplot(comp_agg_month, aes(RR_obs,RR_pred)) + 
  stat_binhex(bins=30)+
  xlab("Measured Rainfall (mm)")+
  ylab("Estimated Rainfall (mm)")+
  labs(title="(d)")+
  geom_abline(slope=1, intercept=1,lty=2)+
  xlim(-2,420)+ylim(-2,420)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:3),colors=viridis(10))+
  annotate("text",  x=-Inf, y = Inf, label = labmonth, vjust=1.2, hjust=-0.0,size=3)
 # geom_text(aes(x=-Inf,y=Inf,vjust=1.5,hjust=-0.1),size = 4,
   #             label=labmonth)
 
library(gridExtra)
#grid.arrange(hourplot,dayplot,weekplot,monthplot) 


# pdf(paste0(figurepath,"RainfallAgg.pdf"),width=11,height=8.5)
# grid.arrange(hourplot,dayplot,weekplot,monthplot)
# dev.off()



pdf(paste0(figurepath,"RainfallAgg.pdf"),width=9,height=6.5)
grid.arrange(hourplot,dayplot,weekplot,monthplot)
dev.off()
