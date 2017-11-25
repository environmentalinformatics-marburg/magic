rm(list=ls())
#mainpath <- "/home/hmeyer/hmeyer/Nele_MIRS/version2/"
mainpath <- "/home/hanna/Documents/Presentations/Paper/submitted/Nele_MIRS/data/"
datapath <- paste0(mainpath,"data/")
spectrapath <- paste0(datapath,"/Baseline/")
modelpath <- paste0(mainpath,"/modeldata/")
setwd(mainpath)

library(hsdar)
library(caret)
library(doParallel)
library(Rsenal)
library(randomForest)
load(paste0(modelpath,"specLib.RData"))
load(paste0(modelpath,"rfemodel.RData"))

featureFrame <- data.frame(attribute(specci),as.data.frame(specci))
featureFrame <- featureFrame[!featureFrame$Labornummer%in%c(57341, 57345, 
                                                            57349, 57350, 57352),]
optVars <- names(varsRfeCV(rfemodel,sderror = TRUE))
#optVars <- rfemodel$optVariables
set.seed(100)

#folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", timevar = NA, k = 10)
folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", timevar = NA, 
                              k = length(unique(featureFrame$Labornummer)))

rfFuncs$fit <- function (x, y, first, last, ...) {
  loadNamespace("randomForest")
  randomForest::randomForest(x, y, importance=T,...)
}


ctrl <- trainControl(method="cv",savePredictions = TRUE,verbose=TRUE,
                    returnResamp = "all",index=folds$index,indexOut=folds$indexOut)

predictors <- featureFrame[,optVars]
response <- featureFrame$Basal_respiration


cl <- makeCluster(detectCores()-1)
registerDoParallel(cl)

set.seed(100)
model <- train(predictors,response,method="rf",
                trControl=ctrl,importance=TRUE,
                tuneLength=10)

stopCluster(cl)

#save(model,file=paste0(modelpath,"finalModel_otherrfeextract.RData"))
save(model,file=paste0(modelpath,"finalModel.RData"))

######################################



