# This scripts visualizes the model comparison. Use the results of evaluateModels.R

rm(list=ls())
library(reshape2)
library(latticeExtra)

mainpath <- "/media/memory01/data/IDESSA/Results/"
#mainpath <- "/media/hanna/data/CopyFrom181/Results/"
datapath <- paste0(mainpath, "Evaluation/")
figurepath <- paste0(mainpath,"Figures/")

#raineventsthres <- 5 # threshold. validate only rate quantity if the number
#of stations that observed rainfall is higher than "raineventsthres"

load(paste0(datapath,"eval_rate.RData"))
load(paste0(datapath,"eval_area.RData"))

################################################################################
# AREA
################################################################################

results_area <- results_area[substr(results_area$Date,1,4)=="2013",]
meltclas <- melt(results_area)
meltclas$variable <- as.character(meltclas$variable)
meltclas_subs <- meltclas[!meltclas$variable%in%c("Bias","CSI","ETS","HKD"),]
meltclas_subs$variable <- factor(meltclas_subs$variable,
                                 levels=c("FAR","HSS","POD","PFD"))

pdf(paste0(figurepath,"RainfallAreaComparison.pdf"),width=5.5,height=6)
bwplot(meltclas_subs$value~meltclas_subs$variable|meltclas_subs$variable,
       notch=FALSE,ylab="value",labels=FALSE,
       scales=list(y=list(relation = "free"),
                   x=list(relation = "free",labels=rep("",4))),
       fill="lightgrey",
       par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
                         strip.background=list(col="lightgrey"),
                         box.umbrella = list(col = "black"),
                         box.dot = list(col = "black", pch = 16, cex=0.4),
                         box.rectangle = list(col="black",fill= rep(c("black", "black"),2))))
dev.off()



################################################################################
# RATE
################################################################################
results_rate <- results_rate[substr(results_rate$Date,1,4)=="2013",]
#results_rate <- results_rate[results_rate$eventsObs>=raineventsthres,]
meltreg <- melt(results_rate)
meltreg$variable <- factor(meltreg$variable,
                                 #levels=c("RMSE","rho","ME","MAE"))
                                  levels=c("RMSE","rho"))


pdf(paste0(figurepath,"RainfallRateComparison.pdf"),width=6,height=3)
bwplot(meltreg$value~meltreg$variable|meltreg$variable,
       notch=FALSE,ylab="value",labels=FALSE,
       scales=list(y=list(relation = "free"),x=list(relation = "free",labels=rep("",4))),
       fill="lightgrey",
       par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
                         strip.background=list(col="lightgrey"),
                         box.umbrella = list(col = "black"),
                         box.dot = list(col = "black", pch = 16, cex=0.4),
                         box.rectangle = list(col="black",fill= rep(c("black", "black"),2))))
dev.off()

################################################################################
boxplot(results_rate$rho~substr(results_rate$Date,5,6),notch=T)
boxplot(results_rate$rho~substr(results_rate$Date,9,10),notch=T)
boxplot(results_area$HSS~substr(results_area$Date,9,10),notch=T)
