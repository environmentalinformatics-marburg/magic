library(reshape2)
setwd("/media/memory01/data/IDESSA/Results/Evaluation/")
load("eval_rate.RData")
load("eval_area.RData")

results_rate<-results_rate[substr(results_rate$Date,1,4)=="2013",]
results_area<-results_area[substr(results_area$Date,1,4)=="2013",]

meltclas <- melt(results_area)
#meltMSG <- meltres[meltclas$Model=="MSG",]
meltclas$variable <- as.character(meltclas$variable)
#meltclas_subs <- meltclas[!meltclas$variable%in%c("Bias","CSI","ETS","HKD","HSS"),]
meltclas_subs <- meltclas[!meltclas$variable%in%c("Bias","CSI","ETS","HKD"),]
#meltclas_subs2 <- meltclas[meltclas$variable==c("CSI","ETS","HKD","HSS"),]
meltclas_subs$variable <- factor(meltclas_subs$variable,
                                 levels=c("POD","PFD","FAR","HSS"))

results_rate$Rsq<-(results_rate$Rsq*10)-2
meltreg <- melt(results_rate)
#meltregMSG <- meltreg[meltreg$Model=="MSG",]
meltreg$variable <- as.character(meltreg$variable)




setwd("/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/")

pdf("RainfallAreaComparison.pdf",width=6.5,height=6)
#par(mfrow=c(1,2))
boxplot(meltclas_subs$value~meltclas_subs$variable,col="lightgrey",
            ylim=c(-0.1,1),outpch=8,outcex=0.4)
#boxplot(meltclas_subs2$value~meltclas_subs2$variable,col="lightgrey",
#            ylim=c(-0.5,1),outpch=8,outcex=0.4)
dev.off()


pdf("RainfallRateComparison.pdf",width=7,height=6)
par(mar=c(4,4,2,4))
boxplot(meltreg$value~meltreg$variable,col="lightgrey",
        ylim=c(-2,4.5),outpch=8,outcex=0,las=2,at=c(1,2,3,4.5),
        ylab="mm")
abline(v=3.75,lty=3)
axis(4,at=c(-2,-1,0,1,2,3,4,5),labels=as.character((c(-2,-1,0,1,2,3,4,5)/10)+0.2),
     las=2)
mtext("explained variance", side = 4, line = 3)
dev.off()
