library(Rsenal)
library(reshape2)
library(vioplot)
library(latticeExtra)

outpath <- "/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/"
dat<-get(load("Evaluation/IMERGComparison.RData"))
results_rate <- list()
results_rate[[1]]<-data.frame()
results_rate[[2]]<-data.frame()
results_area <- list()
results_area[[1]]<-data.frame()
results_area[[2]]<-data.frame()
dat$Day <- substr(dat$Date.x,1,8)
dat_area <- dat


################################################################################
#RATE
################################################################################
dat <- dat[dat$RA_obs=="Rain",]
#dat_agg_day <- aggregate(dat[,names(dat)%in%c("RR_obs","RR_pred","IMERG")],
#                          by=list(dat$Day,dat$Station),sum,na.rm=TRUE)
#names(dat_agg_day)[1:2]<-c("Day","Station")

for (i in unique(dat$Date.x)){
  subs <- dat[dat$Date.x==i,]
  if (nrow(subs)<5){next}
#  if(sum(subs$RA_obs=="Rain")<5){next}
  results_rate[[1]] <- data.frame(rbind(results_rate[[1]],
                                   data.frame("Date"=i,
                                              regressionStats(subs$RR_pred,
                                                              subs$RR_obs,
                                                              adj.rsq = FALSE))))
  
  results_rate[[2]] <- data.frame(rbind(results_rate[[2]],
                                        data.frame("Date"=i,
                                                   regressionStats(subs$IMERG,
                                                                   subs$RR_obs,
                                                                   adj.rsq = FALSE))))
}
results_rate[[2]]$Rsq[is.na(results_rate[[2]]$Rsq)]<-0
results_rate[[1]]$Rsq[is.na(results_rate[[1]]$Rsq)]<-0
results_rate[[2]]$Model<-"IMERG"
results_rate[[1]]$Model<-"MSG"
results<-rbind(results_rate[[1]],results_rate[[2]])


results_melt <- melt(results)
results_melt <- results_melt[results_melt$variable%in%(c("Rsq","RMSE","ME","MAE")),]
results_melt$Model<-factor(results_melt$Model,levels=c("MSG","IMERG"))
results_melt$variable<-factor(results_melt$variable,levels=c("RMSE","Rsq","MAE","ME"))


pdf(paste0(outpath,"IMERGcomp.pdf"),width=7,height=7)
bwplot(results_melt$value~results_melt$Model|results_melt$variable,
       notch=TRUE,ylab="value",
      scales = "free",fill="lightgrey",
      par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
      strip.background=list(col="lightgrey"),
      box.umbrella = list(col = "black"),
      box.dot = list(col = "black", pch = 16, cex=0.4),
      box.rectangle = list(col="black",fill= rep(c("black", "black"),2))))
dev.off()

pdf(paste0(outpath,"vioplot.pdf"),width=6,height=6)
vioplot(dat$RR_obs,dat$RR_pred,dat$IMERG,
        names=c("Rain gauge","MSG","IMERG"),col="grey")
title(ylab="Rainfall (mm)")
dev.off()
################################################################################
#Area
################################################################################
for (i in unique(dat_area$Date.x)){
  subs <- dat_area[dat_area$Date.x==i,]
  results_area[[1]] <- data.frame(rbind(results_area[[1]],
                                        data.frame("Date"=i,
                                                   classificationStats(subs$RA_pred,
                                                                   subs$RA_obs))))
  
  results_area[[2]] <- data.frame(rbind(results_area[[2]],
                                        data.frame("Date"=i,
                                                   classificationStats(subs$RA_IMERG,
                                                                   subs$RA_obs))))
}
results_area[[2]]$Model<-"IMERG"
results_area[[1]]$Model<-"MSG"
results<-rbind(results_area[[1]],results_area[[2]])


results_melt <- melt(results)
results_melt <- results_melt[results_melt$variable%in%(c("POD","PFD","FAR","HSS")),]
results_melt$Model<-factor(results_melt$Model,levels=c("MSG","IMERG"))
results_melt$variable<-factor(results_melt$variable,levels=c("FAR","HSS","POD","PFD"))


pdf(paste0(outpath,"IMERGcomp_area.pdf"),width=7,height=7)
bwplot(results_melt$value~results_melt$Model|results_melt$variable,
       notch=TRUE,ylab="value",
       scales = "free",fill="lightgrey",
       par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
                         strip.background=list(col="lightgrey"),
                         box.umbrella = list(col = "black"),
                         box.dot = list(col = "black", pch = 16, cex=0.4),
                         box.rectangle = list(col="black",fill= rep(c("black", "black"),2))))
dev.off()

