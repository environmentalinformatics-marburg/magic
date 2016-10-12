library(reshape2)
datapath <- "/media/memory01/data/IDESSA/Results/Evaluation/"
#datapath <- "/media/hanna/data/CopyFrom181/Results/Evaluation/"
figurepath <- "/media/memory01/data/IDESSA/Results/Figures/"
#figurepath <- "/media/hanna/data/CopyFrom181/Results/Figures/"
load(paste0(datapath,"eval_rate.RData"))
load(paste0(datapath,"eval_area.RData"))
comp <- get(load(paste0(datapath,"evaluationData_all.RData")))
#figurepath <- "/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/"


comp <- comp[substr(comp$Date,1,4)=="2013",]



################################################################################
# AREA
################################################################################
pdf(paste0(figurepath,"AnalyseFAR.pdf"),width=4.5,height=6)
boxplot(comp$RR_pred[comp$RA_pred=="Rain"&comp$RA_obs=="NoRain"],
        comp$RR_pred[comp$RA_pred=="Rain"&comp$RA_obs=="Rain"],col="lightgrey",
        outpch=8,outcex=0.4,notch=T,names=c("False alarms","True positives"),
        ylab="Rainfall (mm)")
dev.off()


## rainfall area
results_area <- results_area[substr(results_area$Date,1,4)=="2013",]
meltclas <- melt(results_area)
meltclas$variable <- as.character(meltclas$variable)
meltclas_subs <- meltclas[!meltclas$variable%in%c("Bias","CSI","ETS","HKD"),]
meltclas_subs$variable <- factor(meltclas_subs$variable,
                                 levels=c("FAR","HSS","POD","PFD"))



pdf(paste0(figurepath,"RainfallAreaComparison.pdf"),width=5.5,height=6)
#boxplot(meltclas_subs$value~meltclas_subs$variable,col="lightgrey",
#            ylim=c(-0.2,1),outpch=8,outcex=0.4)

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
#results_rate$corr <- (sqrt(results_rate$Rsq)*10)-2
results_rate$correlation <- sqrt(results_rate$Rsq)

#results_rate$corr <- results_rate$corr*5

meltreg <- melt(results_rate[,-which(names(results_rate)=="Rsq")])
meltreg$variable <- factor(meltreg$variable,
                                 levels=c("RMSE","correlation","ME","MAE"))


pdf(paste0(figurepath,"RainfallRateComparison.pdf"),width=5.5,height=6)
#par(mar=c(4,4,2,4))
#boxplot(meltreg$value~meltreg$variable,col="lightgrey",
#        #ylim=c(-0.35,2.0),
#        outpch=8,outcex=0.3,las=2,at=c(1,2,3,4.5),
#        ylab="mm")
#abline(v=3.75,lty=3)
#axis(4,at=c(0,1,2,3,4,5),labels=as.character(c(0,1,2,3,4,5)/5),
#     las=2)
#mtext("r", side = 4, line = 3)
#dev.off()


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