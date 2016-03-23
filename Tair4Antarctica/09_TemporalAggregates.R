library(Rsenal)
load("/media/hanna/data/Antarctica/results/ML/testData.RData")
bestPerforming <- "linMod"


testData$week <- ceiling(testData$doy/7)

bestPerforming <-which(names(testData)==bestPerforming)

#raw <- aggregate(data.frame(testData$statdat,testData[,bestPerforming]),by=data.frame(testData$station),mean)
raw <- data.frame(testData$station,testData$statdat,testData[,bestPerforming])
dailyAgg<-aggregate(data.frame(testData$statdat,testData[,bestPerforming]),by=data.frame(testData$station,testData$doy),mean)
weeklyAgg<-aggregate(data.frame(testData$statdat,testData[,bestPerforming]),by=data.frame(testData$station,testData$week),mean)
monthlyAgg<-aggregate(data.frame(testData$statdat,testData[,bestPerforming]),by=data.frame(testData$station,testData$month),mean)
aggLevels <- list(raw,dailyAgg,weeklyAgg,monthlyAgg)
results<-list()

for (k in 1:length(aggLevels)){
  aggLevel <- aggLevels[[k]]
  results[[k]] <- data.frame()
for (i in unique(aggLevel[,1])){
  agg <- aggLevel[aggLevel[,1]==i,]
  if (k==1){
    results[[k]] <- rbind(results[[k]],data.frame("aggLevel"=k,"station"=i,
                                                  regressionStats(agg[,2],agg[,3])))
  }else{
  results[[k]] <- rbind(results[[k]],data.frame("aggLevel"=k,"station"=i,
                                                regressionStats(agg[,3],agg[,4])))
  }
}
}



Comparison <- data.frame("aggLevel"=rep(c(rep("raw",nrow(results[[1]])),
                                              rep("day",nrow(results[[2]])),
                                            rep("week",nrow(results[[3]])),
                                                rep("month",nrow(results[[4]]))),4),
                             "Station"=rep(results[[1]]$station,4*4),
                             "Value"=c(results[[1]]$RMSE,results[[2]]$RMSE,
                                       results[[3]]$RMSE,results[[4]]$RMSE,
                                       results[[1]]$ME,results[[2]]$ME,
                                       results[[3]]$ME,results[[4]]$ME,
                                       results[[1]]$MAE,results[[2]]$MAE,
                                       results[[3]]$MAE,results[[4]]$MAE,
                                       results[[1]]$Rsq,  results[[2]]$Rsq,
                                       results[[3]]$Rsq,  results[[4]]$Rsq),
                             "Score"=c(rep("RMSE",nrow(results[[1]])*4),
                                       rep("ME",nrow(results[[1]])*4),
                                       rep("MAE",nrow(results[[1]])*4),
                                       rep("R^2",nrow(results[[1]])*4))
                             )
    
Comparison$aggLevel <- factor(Comparison$aggLevel,levels=c("raw","day","week","month"))
    

pdf("/media/hanna/data/Antarctica/visualizations/aggLevels.pdf")
ggplot(Comparison, aes(x = aggLevel, y = Value))+ 
      #  geom_boxplot_noOutliers(aes(fill =MODEL),outlier.size = NA) + #use colors?
      geom_boxplot(outlier.size = 0.4) +
      theme_bw()+
      #facet_grid(Score~., scales = "free")+
      facet_wrap(~Score , ncol = 2, scales = "free")
      xlab("") + ylab("")+
      theme(legend.title = element_text(size=16, face="bold"),
            legend.text = element_text(size = 16),
            legend.key.size=unit(1,"cm"),
            strip.text.y = element_text(size = 16),
            strip.text.x = element_text(size = 16),
            axis.text=element_text(size=14),
            panel.margin = unit(0.7, "lines"))
dev.off()                 

