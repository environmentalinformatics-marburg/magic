rm(list=ls())
library(caret)
library(randomForest)
library(CAST)
library(lubridate)
library(parallel)
library(doParallel)

mainpath <- "/home/hmeyer/Tair/"

nrOfStations <- 40
trainingYears <- 2010:2011
sampleSize <- 150000
#sampleSize_ffs <- 20000

load(paste0(mainpath,"traindata.RData"))
load(paste0(mainpath,"ffs_model.RData"))
set.seed(100)

traindat_samples_full <- createDataPartition(traindat$Station, times = 1,list=FALSE,
                                            p=sampleSize/nrow(traindat))
traindat$Station <- factor(traindat$Station)
traindat_full <- traindat[traindat_samples_full,]

## index LOSOCV 

set.seed(100)
station_out_full <- CreateSpacetimeFolds(traindat_full,spacevar = "Station",
                                        timevar= "dateYD", k=10)




## parallel prozessierung starten
cl <- makeCluster(detectCores()-5)
registerDoParallel(cl)

response_full <- traindat_full$Tair
predictors_full <- traindat_full[,names(ffs_model$trainingData)[-length(names(ffs_model$trainingData))]]
rm(ffs_model)
gc()
#rf model
model_final <- train(predictors_full,
                        response_full,
                        method = "rf",
                        importance =TRUE,
                        tuneLength = 15,
                        trControl = trainControl(method = "cv", 
                                                 index = station_out_full$index,
                                                 indexOut = station_out_full$indexOut,
                                                 savePredictions = TRUE,
                                                 verboseIter=TRUE,
                                                 returnResamp = "all"))
 
 save(model_final,file=paste0(mainpath,"/model_final.RData"))