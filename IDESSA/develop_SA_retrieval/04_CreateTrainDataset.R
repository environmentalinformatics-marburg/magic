library(caret)
setwd("/media/memory01/data/IDESSA/")
outpath <- "/media/memory01/data/IDESSA/Model/"
sampsize <- 0.5

matchfiles <- list.files(,pattern="StationMatch")
print(matchfiles)
dataset <- data.frame()
for (i in 1:length(matchfiles)){
  tmp <- get(load(matchfiles[i]))
  dataset <- rbind(dataset,tmp)
}
dataset <- dataset[,-which(names(dataset)=="Ta_200")]

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

dataset<-dataset[complete.cases(dataset),]
dataset<-dataset[dataset$sunzenith!=-99,]

dataset_day <- dataset[dataset$sunzenith<70,]
dataset_night <- dataset[dataset$sunzenith>=70,]



set.seed(100)
trainIndex_day <- createDataPartition(dataset_day$P_RT_NRT, 
                                  p = sampsize,
                                  list = FALSE,
                                  times = 1)
trainData_day <- dataset_day[trainIndex_day,]
testData_day <- dataset_day[-trainIndex_day,]

save(trainData_day,file=paste0(outpath,"trainData_day.RData"))
save(testData_day,file=paste0(outpath,"testData_day.RData"))

set.seed(100)
trainIndex_night <- createDataPartition(dataset_night$P_RT_NRT, 
                                      p = sampsize,
                                      list = FALSE,
                                      times = 1)
trainData_night <- dataset_night[trainIndex_night,-which(names(dataset_night)%in%c("VIS0.6","VIS0.8","NIR1.6","T0.6_1.6"))]
testData_night <- dataset_night[-trainIndex_night,-which(names(dataset_night)%in%c("VIS0.6","VIS0.8","NIR1.6","T0.6_1.6"))]
save(trainData_night,file=paste0(outpath,"trainData_night.RData"))
save(testData_night,file=paste0(outpath,"testData_night.RData"))
