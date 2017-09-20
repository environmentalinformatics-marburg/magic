rm(list=ls())
library(caret)
library(randomForest)
library(Rsenal)
library(parallel)
library(doParallel)

wd <- "/media/memory02/casestudies/hmeyer/IDESSA_TAIR/"
load(paste0(wd,"/Tair_trainingSet_johannes_2.RData"))

dataset_training <- dataset_training[dataset_training$year=="2013",]
## index LOSOCV 
dataset_training$Station <- factor(dataset_training$Station)
set.seed(111)
station_out <- CreateSpacetimeFolds(dataset_training,spacevar = "Station",
                                    timevar= "day", k=10)

# reduziere landnutzungen da sonst fehler durch data splitting
#dataset_training$landcover[dataset_training$landcover=="Woody Savannas"] <- "Savannas"
#dataset_training$landcover[
#  dataset_training$landcover=="Cropland/Natural Vegetation Mosaic"] <- "Croplands"

# monat als numerisch
dataset_training$month <- as.numeric(dataset_training$month)

## parallel prozessierung starten
cl <- makeCluster(detectCores()-2)
registerDoParallel(cl)

## predictor und response definieren
predictors <- dataset_training[,c(9:15,17)]
response <- dataset_training$Tair

#rf model
model_rf_LLTO <- train(predictors,
                     response,
                     method = "rf",
                     tuneLength = 3,
                     trControl = trainControl(method = "cv", 
                                              index = station_out$index,
                                              indexOut = station_out$indexOut,
                                              savePredictions = TRUE))

save(model_rf_LLTO,file=paste0(wd,"/model_rf_LLTO.RData"))


