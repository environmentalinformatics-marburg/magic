library(reshape2)
datapath <- "/media/memory01/data/IDESSA/Results/Evaluation/"
figurepath <- "/media/memory01/data/IDESSA/Results/Figures/"
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
                                 levels=c("POD","PFD","FAR","HSS"))



pdf(paste0(figurepath,"RainfallAreaComparison.pdf"),width=6.5,height=6)
boxplot(meltclas_subs$value~meltclas_subs$variable,col="lightgrey",
            ylim=c(-0.2,1),outpch=8,outcex=0.4)
dev.off()



################################################################################
# RATE
################################################################################
results_rate <- results_rate[substr(results_rate$Date,1,4)=="2013",]
results_rate$Rsq<-(results_rate$Rsq*10)-2
meltreg <- melt(results_rate)

meltreg$variable <- as.character(meltreg$variable)

pdf(paste0(figurepath,"RainfallRateComparison.pdf"),width=7,height=6)
par(mar=c(4,4,2,4))
boxplot(meltreg$value~meltreg$variable,col="lightgrey",
        ylim=c(-2,4.5),outpch=8,outcex=0,las=2,at=c(1,2,3,4.5),
        ylab="mm")
abline(v=3.75,lty=3)
axis(4,at=c(-2,-1,0,1,2,3,4,5),labels=as.character((c(-2,-1,0,1,2,3,4,5)/10)+0.2),
     las=2)
mtext("explained variance", side = 4, line = 3)
dev.off()
