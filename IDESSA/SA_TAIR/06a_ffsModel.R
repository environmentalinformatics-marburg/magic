rm(list=ls())
library(caret)
library(randomForest)
library(CAST)
library(lubridate)
library(parallel)
library(doParallel)
#mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/forPaper/modeldat/"
#mainpath <- "/mnt/sd19007/casestudies/hmeyer/IDESSA_TAIR/V2/"
mainpath <- "/home/hmeyer/Tair/"

nrOfStations <- 40
trainingYears <- 2010:2011
#sampleSize <- 150000
sampleSize_ffs <- 20000
method <- "rf"
#method <- "gbm"

load(paste0(mainpath,"modeldata.RData"))
dataset <- dataset[complete.cases(dataset[,3:17]),]

set.seed(100)
trainingStations <- sample(unique(dataset$Station),nrOfStations)
traindat <- dataset[year(dataset$date)%in%trainingYears&
                      dataset$Station%in%trainingStations,]
testdat <- dataset[!year(dataset$date)%in%trainingYears&
                 dataset$Station%in%trainingStations,]
save(testdat,file=paste0(mainpath,"/testdata.RData"))
save(traindat,file=paste0(mainpath,"/traindata.RData"))
rm(dataset,testdat)
gc()

set.seed(100)
traindat_samples_ffs <- createDataPartition(traindat$Station, times = 1,list=FALSE,
                                p=sampleSize_ffs/nrow(traindat))
traindat$Station <- factor(traindat$Station)
traindat_ffs <- traindat[traindat_samples_ffs,]

## index LOSOCV 

set.seed(100)
station_out_ffs <- CreateSpacetimeFolds(traindat_ffs,spacevar = "Station",
                                    timevar= "dateYD", k=10)

## predictor und response definieren
predictors <- c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3",
                "IR8.7","IR9.7","IR10.8","IR12.0","IR13.4","sunzenith",
                 "Precseason","ndvi","Dem","Continent")
predictors_ffs <- traindat_ffs[,predictors]
response_ffs <- traindat_ffs$Tair


## parallel prozessierung starten
cl <- makeCluster(detectCores()-5)
registerDoParallel(cl)

ffs_model <- ffs(predictors_ffs,
                       response_ffs,
                       method = method,
                       importance =TRUE,
                       #tuneLength = 3,
                       tuneGrid = expand.grid(mtry = 2),
                       trControl = trainControl(method = "cv", 
                                                index = station_out_ffs$index,
                                                indexOut = station_out_ffs$indexOut,
                                                savePredictions = TRUE,
                                                verboseIter=TRUE,
                                                returnResamp = "all"))

save(ffs_model,file=paste0(mainpath,"/ffs_model_",method,".RData"))



random_model <- train(predictors_ffs,
                 response_ffs,
                 method = method,
                 importance =TRUE,
                 tuneGrid = expand.grid(mtry = 2),
                 trControl = trainControl(method = "cv", 
                                          savePredictions = TRUE,
                                          verboseIter=TRUE,
                                          returnResamp = "all"))

save(random_model,file=paste0(mainpath,"/random_model_",method,".RData"))
