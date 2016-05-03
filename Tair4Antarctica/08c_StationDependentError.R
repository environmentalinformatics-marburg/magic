rm(list=ls())
library(ggplot2)
load("/media/hanna/data/Antarctica/results/MLFINAL/trainData.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL/model_GBM.RData")
statname <- unique(trainData$station)

meanrmse <- c()
meanrsq <- c()
for (i in 1:length(model_GBM$control$index)){
  indexi <- paste0("Resample", sprintf("%02d", i))
  meanrmse[i] <- mean(model_GBM$resample$RMSE[model_GBM$resample$Resample==indexi])
  meanrsq[i] <- mean(model_GBM$resample$Rsq[model_GBM$resample$Resample==indexi])
}
results <- data.frame(statname,meanrmse,meanrsq)

results$type="NA"
for (i in 1:nrow(results)){
  results$type[i] <- as.character(unique(trainData$type[trainData$station==results$statname[i]]))
}

results$location <- "Dry Valleys"
results$location[results$type=="Univ_Wisconsin"] <- "Ice"

boxplot(results$meanrmse~results$location)
boxplot(results$meanrsq~results$location)



Comparison<-data.frame("Value"=c(results$meanrmse,results$meanrsq),
                       "Score"=c(rep("RMSE",nrow(results)),
                                 rep("Rsq",nrow(results))),
                       "Location"=c(results$location,results$location))


pdf("/media/hanna/data/Antarctica/visualizations/StationDependentError.pdf",
    height=4,width=8)
ggplot(Comparison, aes(x = Location, y = Value))+ 
  geom_boxplot(outlier.size = 0.4,notch=F) +
  theme_bw()+
  #facet_grid(Score~., scales = "free")+
  facet_wrap(~Score , ncol = 2, scales = "free")+
  xlab("N = 32") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=14),
        panel.margin = unit(1, "lines"))
dev.off()