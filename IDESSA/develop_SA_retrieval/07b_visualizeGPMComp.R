# This script compares MSG based rainfall predictions with GPM IMERG estimates.
# A comparison table from "compareWithGPM.R" is required.
##########################
rm(list=ls())
library(Rsenal)
library(reshape2)
library(vioplot)
library(latticeExtra)
##########################
mainpath <- "/media/memory01/data/IDESSA/Results/"
#mainpath <- "/media/hanna/data/CopyFrom181/Results/"
datapath <- paste0(mainpath,"Evaluation/")
figurepath <- paste0(mainpath,"Figures/")

raineventsthres <- 5 # threshold. validate only rate quantity if the number
#of stations that observed rainfall is higher than "raineventsthres"
##########################
dat <- get(load(paste0(datapath,"IMERGComparison.RData")))
##########################
names(dat)[2] <- "Date"
dat$Day <- substr(dat$Date,1,8)
dat_area <- dat

################################################################################
# Compare rainfall quantities
################################################################################
results_rate <- list(data.frame(),data.frame())
for (i in unique(dat$Date)){
  subs <- dat[dat$Date==i,]
  regMSG <- tryCatch(regressionStats(subs$RR_pred,
                         subs$RR_obs,
                         method="spearman"),  error = function(e)e)
  regIMERG <- tryCatch(regressionStats(subs$IMERG,
                  subs$RR_obs,
                  method="spearman"),  error = function(e)e)
  if (inherits(regMSG,"error")|inherits(regIMERG,"error")){next}
  results_rate[[1]] <- data.frame(rbind(results_rate[[1]],
                                   data.frame("Date"=i,
                                              "eventsObs" = sum(subs$RR_obs>0),
                                              "eventsPred" = sum(subs$RR_pred>0),
                                              regMSG)))
  
  results_rate[[2]] <- data.frame(rbind(results_rate[[2]],
                                        data.frame("Date"=i,
                                                   "eventsObs" = sum(subs$RR_obs>0),
                                                   "eventsPred" = sum(subs$IMERG>0),
                                                   regIMERG)))
}

results_rate[[1]] <- results_rate[[1]][results_rate[[1]]$eventsObs>=raineventsthres,]
results_rate[[2]] <- results_rate[[2]][results_rate[[2]]$eventsObs>=raineventsthres,]
results_rate[[2]]$Model <- "IMERG"
results_rate[[1]]$Model <- "MSG"
results <- rbind(results_rate[[1]],results_rate[[2]])


results_melt <- melt(results)
#results_melt <- results_melt[results_melt$variable%in%(c("rho","RMSE","ME","MAE")),]
results_melt <- results_melt[results_melt$variable%in%(c("rho","RMSE")),]
results_melt$Model<-factor(results_melt$Model,levels=c("MSG","IMERG"))
#results_melt$variable<-factor(results_melt$variable,levels=c("RMSE","rho","MAE","ME"))
results_melt$variable<-factor(results_melt$variable,levels=c("RMSE","rho"))


pdf(paste0(figurepath,"IMERGcomp.pdf"),width=6,height=3)
bwplot(results_melt$value~results_melt$Model|results_melt$variable,
       notch=TRUE,ylab="value",
      scales = "free",fill="lightgrey",
      par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
      strip.background=list(col="lightgrey"),
      box.umbrella = list(col = "black"),
      box.dot = list(col = "black", pch = 16, cex=0.4),
      box.rectangle = list(col="black",fill= rep(c("black", "black"),2))))
dev.off()



################################################################################
#Compare rainfall area delineation
################################################################################
results_area <- list(data.frame(),data.frame())
for (i in unique(dat_area$Date)){
  subs <- dat_area[dat_area$Date==i,]
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


pdf(paste0(figurepath,"IMERGcomp_area.pdf"),width=5.5,height=6)
bwplot(results_melt$value~results_melt$Model|results_melt$variable,
       notch=TRUE,ylab="value",
       scales = "free",fill="lightgrey",
       par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
                         strip.background=list(col="lightgrey"),
                         box.umbrella = list(col = "black"),
                         box.dot = list(col = "black", pch = 16, cex=0.4),
                         box.rectangle = list(col="black",fill= rep(c("black", "black"),2))))
dev.off()
