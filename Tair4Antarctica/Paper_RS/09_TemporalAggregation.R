library(Rsenal)
library(ggplot2)
setwd("/media/hanna/data/Antarctica/results/MLFINAL/")
load("dataset.RData")
finalModel <- get(load("model_GBM.RData"))
dataset$week <- ceiling(dataset$doy/7)
dataset$pred <- predict(finalModel,dataset[,finalModel$finalModel$xNames])



################################################################################
# Calculate number of data points for differnet aggregation levels per Station
################################################################################


dataset <- dataset[complete.cases(dataset),]

### Daily
maxday <- 4
daysamples<-data.frame()
for (i in 1:length(unique(dataset$station))){
  subs <- dataset[dataset$station==unique(dataset$station)[i],]
  daysamples[,i] <- c()
  for (k in 1:365){
    daysamples[k,i]<-(nrow(subs[subs$doy==k,])/maxday)*100
  }
}
colnames(daysamples)<-unique(dataset$station)

### Weekly
maxweek <- 4*7
weeksamples<-data.frame()
for (i in 1:length(unique(dataset$station))){
  subs <- dataset[dataset$station==unique(dataset$station)[i],]
  weeksamples[,i] <- c()
  for (k in 1:35){
    weeksamples[k,i]<-(nrow(subs[subs$week==k,])/maxweek)*100
  }
}
colnames(weeksamples)<-unique(dataset$station)

### Monthly
maxmonth <- c(31*4,28*4,31*4,30*4,31*4,30*4,31*4,30*4,31*4,
              31*4,30*4,31*4)
monthsamples<-data.frame()
for (i in 1:length(unique(dataset$station))){
  subs <- dataset[dataset$station==unique(dataset$station)[i],]
  monthsamples[,i] <- c()
  for (k in 1:length(unique(dataset$month))){
    monthsamples[k,i]<-(nrow(subs[subs$month==unique(dataset$month)[k],])/
                          maxmonth[k])*100
  }
}
colnames(monthsamples)<-unique(dataset$station)

################################################################################
#Aggregate data and use only those with at least 60% available data
################################################################################
dayagg <- aggregate(data.frame(dataset$statdat,dataset$pred),
                     by=list(dataset$station,dataset$doy),FUN=function(x){mean(x,na.rm=T)})
dayagg$perc <- NA
for(i in 1:nrow(dayagg)){
  dayagg$perc[i]<-daysamples[dayagg$Group.2[i],as.character(dayagg$Group.1[i])]
}
dayagg <- dayagg[dayagg$perc>=60,]
names(dayagg)<-c("station","agg","statdat","pred","perc")


weekagg <- aggregate(data.frame(dataset$statdat,dataset$pred),
                      by=list(dataset$station,dataset$week),FUN="mean",na.rm=T)
weekagg$perc <- NA
for(i in 1:nrow(weekagg)){
  weekagg$perc[i]<-weeksamples[weekagg$Group.2[i],as.character(weekagg$Group.1[i])]
}
weekagg <- weekagg[weekagg$perc>=60,]
names(weekagg)<-c("station","agg","statdat","pred","perc")

monthagg <- aggregate(data.frame(dataset$statdat,dataset$pred),
                      by=list(dataset$station,dataset$month),FUN="mean",na.rm=T)
monthagg$perc <- NA
for(i in 1:nrow(monthagg)){
  monthagg$perc[i]<-monthsamples[monthagg$Group.2[i],as.character(monthagg$Group.1[i])]
}
monthagg <- monthagg[monthagg$perc>=60,]
names(monthagg)<-c("station","agg","statdat","pred","perc")

agglevels <- c("raw","day","week","month")
aggdata <- list(dataset,dayagg,weekagg,monthagg)
results <- list()
for (level in 1:length(agglevels)){
  results[[level]] <- data.frame(matrix(ncol=7))
for (i in 1:length(unique(dataset$station))){
  results[[level]][i,] <- regressionStats(aggdata[[level]]$pred[aggdata[[level]]$station==unique(dataset$station)[i]],
                                          aggdata[[level]]$statdat[aggdata[[level]]$station==unique(dataset$station)[i]])
}
  names(results[[level]])<- c("ME","ME.se","MAE","MAE.se","RMSE","RMSE.se","Rsq")
}
for (i in 1:length(results)){
results[[i]][!complete.cases(results[[i]]),]<-NA
}
Comparison <- data.frame("aggLevel"=c(rep("raw",32*4),
                                          rep("day",32*4),
                                          rep("week",32*4),
                                          rep("month",32*4)),
                         "Station"=rep(rep(unique(dataset$station),4),4),
                         "Value"=c(results[[1]]$ME,results[[1]]$MAE,
                                   results[[1]]$RMSE,results[[1]]$Rsq,
                                   results[[2]]$ME,results[[2]]$MAE,
                                   results[[2]]$RMSE,results[[2]]$Rsq,
                                   results[[3]]$ME,results[[3]]$MAE,
                                   results[[3]]$RMSE,results[[3]]$Rsq,
                                   results[[4]]$ME,results[[4]]$MAE,
                                   results[[4]]$RMSE,results[[4]]$Rsq),
                         "Score"=rep(c(rep("ME",32),rep("MAE",32),rep("RMSE",32),
                                     rep("Rsq",32)),4)
)


Comparison$aggLevel <- factor(Comparison$aggLevel,levels=c("raw","day","week","month"))

pdf("/media/hanna/data/Antarctica/visualizations/aggLevels.pdf")
ggplot(Comparison, aes(x = aggLevel, y = Value))+ 
  geom_boxplot(outlier.size = 0.4) +
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