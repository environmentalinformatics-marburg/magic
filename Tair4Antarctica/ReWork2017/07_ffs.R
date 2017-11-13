#07 run ffs
rm(list=ls())
library(caret)
library(CAST)
library(parallel)
library(doParallel)
library(randomForest)
#mainpath <- "/mnt/sd19007/users/hmeyer/Antarctica/ReModel2017/"
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")
modelpath <- paste0(datapath, "/modeldat/")

trainingDat <- get(load(paste0(modelpath,"trainingDat.RData")))
folds <- CreateSpacetimeFolds(trainingDat, spacevar = "Station", k = 10)

predictors <-trainingDat[,c("LST_day","LST_night","min_hillsh","mean_hillsh","max_hillsh",
"min_altitude","mean_altitude","max_altitude","min_azimuth",
"mean_azimuth","max_azimuth","DEM")]
response <- trainingDat$Temperature


## parallel prozessierung starten
cl <- makeCluster(detectCores()-5)
registerDoParallel(cl)

#################### FFS MODEL

ffs_model <- ffs(predictors,
                 response,
                 method = "rf",
                 importance =TRUE,
                 tuneGrid = expand.grid(mtry = 2),
                 trControl = trainControl(method = "cv", 
                                          index = folds$index,
                                          indexOut = folds$indexOut,
                                          savePredictions = TRUE,
                                          verboseIter=TRUE,
                                          returnResamp = "all"))
save(ffs_model,file=paste0(modelpath,"/ffs_model.RData"))

#################### FINAL MODEL

predictors <- trainingDat[,names(ffs_model$trainingData)[-length(names(ffs_model$trainingData))]]
rm(ffs_model)
gc()
model_final <- train(predictors,
                     response,
                     method = "rf",
                     importance =TRUE,
                     tuneLength = 15,
                     trControl = trainControl(method = "cv", 
                                              index = folds$index,
                                              indexOut = folds$indexOut,
                                              savePredictions = TRUE,
                                              verboseIter=TRUE,
                                              returnResamp = "all"))
save(model_final,file=paste0(modelpath,"/model_final.RData"))

stopCluster(cl)