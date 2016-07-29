setwd("/media/memory01/data/IDESSA/Results/Evaluation/")
comp <- get(load("IMERGComparison.RData"))

results_area <- data.frame()
for (i in unique(comp$Date.x)){
  subs <- comp[comp$Date.x==i,]
  if (nrow(subs)<5){next}
  results_area <- data.frame(rbind(results_area,
                   data.frame("Model"="MSG",classificationStats(subs$RA_pred,subs$RA_obs)),
                   data.frame("Model"="IMERG",
                              classificationStats(subs$RA_IMERG,subs$RA_obs))))
  
}

results_rate <- data.frame()
for (i in unique(comp$Date.x)){
  subs <- comp[comp$Date.x==i,]
  if (nrow(subs)<5){next}
  if(sum(subs$RA_obs=="Rain")<5){next}
  results_rate <- data.frame(rbind(results_rate,
                                   data.frame("Model"="MSG",
                                              regressionStats(subs$RR_pred[subs$RA_obs=="Rain"],
                                                               subs$RR_obs[subs$RA_obs=="Rain"],
                                                              adj.rsq = FALSE)),
                                   data.frame("Model"="IMERG",
                                              regressionStats(subs$IMERG[subs$RA_obs=="Rain"],
                                                               subs$RR_obs[subs$RA_obs=="Rain"],
                                              adj.rsq = FALSE))))
  }
results_rate <- results_rate[,-which(names(results_rate)%in%c("ME.se","MAE.se","RMSE.se"))]

meltclas <- melt(results_area)
meltMSG <- meltres[meltclas$Model=="MSG",]
meltMSG$variable <- as.character(meltMSG$variable)
meltMSG_subs <- meltMSG[meltMSG$variable!="Bias",]

results_rate$Rsq<-(results_rate$Rsq*10)-2
meltreg <- melt(results_rate)
meltregMSG <- meltreg[meltreg$Model=="MSG",]
meltregMSG$variable <- as.character(meltregMSG$variable)


setwd("/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/")
pdf("RainfallAreaComparison.pdf",width=6,height=5)

boxplot(meltMSG_subs$value~meltMSG_subs$variable,col="lightgrey",
        ylim=c(-0.7,1.2),outpch=8,outcex=0.4)
dev.off()


pdf("RainfallRateComparison.pdf",width=6,height=4)
par(mar=c(4,4,2,4))
boxplot(meltregMSG$value~meltregMSG$variable,col="lightgrey",
        ylim=c(-2,4),outpch=8,outcex=0,las=2,at=c(1,2,3,4.5),
        ylab="mm")
abline(v=3.75,lty=3)
axis(4,at=c(-2,-1,0,1,2,3,4),labels=as.character((c(-2,-1,0,1,2,3,4)/10)+0.2),
     las=2)
mtext("explained variance", side = 4, line = 3)
dev.off()
