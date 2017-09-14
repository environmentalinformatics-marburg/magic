rm(list=ls())
library(caret)
library(randomForest)
library(CAST)
library(lubridate)
library(parallel)
library(doParallel)
#mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/modeldat/"
mainpath <- "/mnt/sd19007/casestudies/hmeyer/IDESSA_TAIR/V2/"
outpath <- "/home/hmeyer/"

nrOfStations <- 40
trainingYears <- 2010:2011
sampleSize <- 150000

load(paste0(mainpath,"dataset_withNDVI.RData"))
dataset <- dataset[complete.cases(dataset[,3:17]),]

set.seed(100)
trainingStations <- sample(unique(dataset$Station),nrOfStations)
traindat <- dataset[year(dataset$date)%in%trainingYears&
                      dataset$Station%in%trainingStations,]
testdat <- dataset[!year(dataset$date)%in%trainingYears|
                 !dataset$Station%in%trainingStations,]
save(testdat,file=paste0(outpath,"/testdata.RData"))
rm(dataset,testdat)
gc()
set.seed(100)
traindat_samples <- createDataPartition(traindat$Station, times = 1,list=FALSE,
                                p=sampleSize/nrow(traindat))
traindat <- traindat[traindat_samples,]
## index LOSOCV 
traindat$Station <- factor(traindat$Station)
set.seed(100)
station_out <- CreateSpacetimeFolds(traindat,spacevar = "Station",
                                    timevar= "dateYD", k=10)


## parallel prozessierung starten
cl <- makeCluster(detectCores()-5)
registerDoParallel(cl)

## predictor und response definieren
predictors <- c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3",
                "IR8.7","IR9.7","IR10.8","IR12.0","IR13.4","sunzenith",
                 "ndvi")
predictors <- traindat[,predictors]
response <- traindat$Tair

#rf model
model_rf_LLTO <- train(predictors,
                       response,
                       method = "rf",
                       importance =TRUE,
                       tuneLength = 3,
                       trControl = trainControl(method = "cv", 
                                                index = station_out$index,
                                                indexOut = station_out$indexOut,
                                                savePredictions = TRUE,
                                                verboseIter=TRUE,
                                                returnResamp = "all"))

save(model_rf_LLTO,file=paste0(outpath,"/model_rf_LLTO.RData"))


