# This script compares MSG based rainfall predictions with GPM IMERG estimates.
# A comparison table from "compareWithGPM.R" is required.
##########################
rm(list=ls())
library(Rsenal)
library(reshape2)
library(vioplot)
library(latticeExtra)
##########################
mainpath <- "/media/hanna/data/CopyFrom181/Results/"
#mainpath <- "/media/hanna/data/CopyFrom181/Results/"
datapath <- paste0(mainpath, "Evaluation/")
#figurepath <- paste0(mainpath,"Figures/")
figurepath <-"/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_SARetrieval/Submission2/Revision/additionals/"


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




pdf(paste0(figurepath,"IMERGcomp_vio.pdf"),
width=9,height=4.5)
par(mfrow=c(1,2),mar=c(2.5,4,2,1))
vioplot(results_rate[[1]]$RMSE,results_rate[[2]]$RMSE,
        col="lightgrey",
        names=c("MSG","IMERG"))
title(main = "RMSE", ylab = "mm")
vioplot(results_rate[[1]]$rho[complete.cases(results_rate[[1]]$rho)],
        results_rate[[2]]$rho[complete.cases(results_rate[[2]]$rho)],
        col="lightgrey",
        names=c("MSG","IMERG"))
title(main = "rho", ylab = "")
dev.off()


################################################################################
#Compare rainfall area delineation
################################################################################
results_area <- list(data.frame(),data.frame())
for (i in unique(dat_area$Date)){
  subs <- dat_area[dat_area$Date==i,]
  results_area[[1]] <- data.frame(rbind(results_area[[1]],
                                        data.frame("Date"=i,
                                                   "eventsObs" = sum(subs$RA_obs=="Rain"),
                                                   "eventsPred" = sum(subs$RA_pred=="Rain"),
                                                   classificationStats(subs$RA_pred,
                                                                   subs$RA_obs))))
  
  results_area[[2]] <- data.frame(rbind(results_area[[2]],
                                        data.frame("Date"=i,
                                                   "eventsObs" = sum(subs$RA_obs=="Rain"),
                                                   "eventsPred" = sum(subs$RA_IMERG=="Rain"),
                                                   classificationStats(subs$RA_IMERG,
                                                                   subs$RA_obs))))
}
results_area[[2]]$Model<-"IMERG"
results_area[[1]]$Model<-"MSG"
#results_area[[1]] <- results_area[[1]][results_area[[1]]$eventsObs>=raineventsthres,]
#results_area[[2]] <- results_area[[2]][results_area[[2]]$eventsObs>=raineventsthres,]

results<-rbind(results_area[[1]],results_area[[2]])


pdf(paste0(figurepath,"IMERGcomp_area_vio.pdf"),
    width=7.5,height=8.5)
par(mfrow=c(2,2),mar=c(2.5,4,2,1))
vioplot(results_area[[1]]$POD[complete.cases(results_area[[1]]$POD)],
        results_area[[2]]$POD[complete.cases(results_area[[2]]$POD)],
        col="lightgrey",
        names=c("MSG","IMERG"))
title(main = "POD", ylab = "")
vioplot(results_area[[1]]$PFD[complete.cases(results_area[[1]]$PFD)],
        results_area[[2]]$PFD[complete.cases(results_area[[2]]$PFD)],
        col="lightgrey",
        names=c("MSG","IMERG"))
title(main = "POFD", ylab = "")
vioplot(results_area[[1]]$FAR[complete.cases(results_area[[1]]$FAR)],
        results_area[[2]]$FAR[complete.cases(results_area[[2]]$FAR)],
        col="lightgrey",
        names=c("MSG","IMERG"))
title(main = "FAR", ylab = "")
vioplot(results_area[[1]]$HSS[complete.cases(results_area[[1]]$HSS)],
        results_area[[2]]$HSS[complete.cases(results_area[[2]]$HSS)],
        col="lightgrey",
        names=c("MSG","IMERG"))
title(main = "HSS", ylab = "")

dev.off()

