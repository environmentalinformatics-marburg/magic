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
responseRA[dataset$P_RT_NRT<=0]="Rain"
responseRA[dataset$P_RT_NRT>0]="NoRain"
responseRA <- as.factor(responseRA)
dataset$RainArea <- factor(responseRA,levels=c("Rain","NoRain"))



dataset$WV6.2_IR10.8 <- dataset$WV6.2-dataset$IR10.8
dataset$WV7.3_IR12.0 <- dataset$WV7.3-dataset$IR12.0
dataset$IR8.7_IR10.8 <- dataset$IR8.7-dataset$IR10.8
dataset$IR10.8_IR12.0 <- dataset$IR10.8-dataset$IR12.0
dataset$IR3.9_WV7.3 <- dataset$IR3.9-dataset$WV7.3
dataset$IR3.9_IR10.8 <- dataset$IR3.9-dataset$IR10.8

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
trainData_night <- dataset_night[trainIndex_night,-which(names(dataset_night)%in%c("VIS0.6","VIS0.8","NIR1.6"))]
testData_night <- dataset_night[-trainIndex_night,-which(names(dataset_night)%in%c("VIS0.6","VIS0.8","NIR1.6"))]
save(trainData_night,file=paste0(outpath,"trainData_night.RData"))
save(testData_night,file=paste0(outpath,"testData_night.RData"))
