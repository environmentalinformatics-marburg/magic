# This scripts visualizes the model comparison. Use the results of evaluateModels.R

rm(list=ls())
library(reshape2)
library(latticeExtra)

mainpath <- "/media/hanna/data/CopyFrom181/Results/"
#mainpath <- "/media/hanna/data/CopyFrom181/Results/"
datapath <- paste0(mainpath, "Evaluation/")
#figurepath <- paste0(mainpath,"Figures/")
figurepath <-"/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_SARetrieval/Submission2/Revision/additionals/"

load(paste0(datapath,"eval_rate.RData"))
load(paste0(datapath,"eval_area.RData"))

################################################################################
# AREA
################################################################################

results_area <- results_area[substr(results_area$Date,1,4)=="2013",]

pdf(paste0(figurepath,"RainfallAreaComparison_vio.pdf"),
    width=9,height=4.5)
#par(mfrow=c(1,2),mar=c(2.5,4,2,1))
par(mar=c(2.5,4,2,1))
lo <- layout(matrix(c(1,2,0,0),1,2, byrow = TRUE), widths=c(2,1))
#layout.show(lo)

vioplot(results_area$POD[complete.cases(results_area$POD)],
        results_area$PFD[complete.cases(results_area$PFD)],
        results_area$FAR[complete.cases(results_area$FAR)],
        col="lightgrey",
        names=c("POD","POFD","FAR"))

vioplot(results_area$HSS[complete.cases(results_area$HSS)],
        col="lightgrey",
        names=c("HSS"))

dev.off()


################################################################################
# RATE
################################################################################
results_rate <- results_rate[substr(results_rate$Date,1,4)=="2013",]



pdf(paste0(figurepath,"RainfallRateComparison_vio.pdf"),
    width=8.5,height=4.2)
par(mfrow=c(1,2),mar=c(4,4,2,1))
vioplot(results_rate$RMSE[complete.cases(results_rate$RMSE)],
        col="lightgrey",
        names=c("RMSE"))
title(ylab = "mm")

vioplot(results_rate$rho[complete.cases(results_rate$rho)],
        col="lightgrey",
        names=c("rho"))
title(ylab = "")
dev.off()

################################################################################
