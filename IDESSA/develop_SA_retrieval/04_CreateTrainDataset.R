library(caret)
setwd("/media/memory01/data/IDESSA/Results/ExtractedData/")
outpath <- "/media/memory01/data/IDESSA/Results/Model/"

matchfiles <- c("StationMatch_2010.RData","StationMatch_2012.RData",
                "StationMatch_2012.RData")
dataset <- data.frame()
for (i in 1:length(matchfiles)){
  tmp <- get(load(matchfiles[i]))
  names(tmp)[length(names(tmp))]<-"P_RT_NRT"
  
  tmp<-dataset[complete.cases(tmp),]
  tmp<-dataset[tmp$sunzenith!=-99,]
  
  dataset <- rbind(dataset,tmp)
}

responseRA <- as.character(dataset$P_RT_NRT)
responseRA[dataset$P_RT_NRT<=0]="NoRain"
responseRA[dataset$P_RT_NRT>0]="Rain"
responseRA <- as.factor(responseRA)
dataset$RainArea <- factor(responseRA,levels=c("Rain","NoRain"))

dataset$T0.6_1.6 <- dataset$VIS0.6-dataset$NIR1.6
dataset$T6.2_10.8 <- dataset$WV6.2-dataset$IR10.8
dataset$T7.3_12.0 <- dataset$WV7.3-dataset$IR12.0
dataset$T8.7_10.8 <- dataset$IR8.7-dataset$IR10.8
dataset$T10.8_12.0 <- dataset$IR10.8-dataset$IR12.0
dataset$T3.9_7.3 <- dataset$IR3.9-dataset$WV7.3
dataset$T3.9_10.8 <- dataset$IR3.9-dataset$IR10.8

save(dataset,file=paste0(outpath,"dataset.RData"))


dataset_day <- dataset[dataset$sunzenith<70,]
dataset_night <- dataset[dataset$sunzenith>=70,-which(names(dataset)%in%c(
  "VIS0.6","VIS0.8","NIR1.6","T0.6_1.6"))]
save(dataset_day,file=paste0(outpath,"dataset_day.RData"))
save(dataset_night,file=paste0(outpath,"dataset_night.RData"))
