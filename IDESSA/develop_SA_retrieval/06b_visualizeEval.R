library(reshape2)
setwd("/media/memory01/data/IDESSA/Results/Evaluation/")
load("eval_rate.RData")
load("eval_area.RData")

meltclas <- melt(results_area)
#meltMSG <- meltres[meltclas$Model=="MSG",]
meltclas$variable <- as.character(meltclas$variable)
meltclas_subs <- meltclas[meltclas$variable!="Bias",]

results_rate$Rsq<-(results_rate$Rsq*10)-2
meltreg <- melt(results_rate)
#meltregMSG <- meltreg[meltreg$Model=="MSG",]
meltreg$variable <- as.character(meltreg$variable)


setwd("/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/")
pdf("RainfallAreaComparison.pdf",width=6,height=5)

boxplot(meltclas_subs$value~meltclas_subs$variable,col="lightgrey",
        ylim=c(-0.7,1.2),outpch=8,outcex=0.4)
dev.off()


pdf("RainfallRateComparison.pdf",width=6,height=4)
par(mar=c(4,4,2,4))
boxplot(meltreg$value~meltreg$variable,col="lightgrey",
        ylim=c(-2,4),outpch=8,outcex=0,las=2,at=c(1,2,3,4.5),
        ylab="mm")
abline(v=3.75,lty=3)
axis(4,at=c(-2,-1,0,1,2,3,4),labels=as.character((c(-2,-1,0,1,2,3,4)/10)+0.2),
     las=2)
mtext("explained variance", side = 4, line = 3)
dev.off()
