rm(list=ls())
mainpath <- "/home/hmeyer/hmeyer/Nele_MIRS/version2/"
datapath <- paste0(mainpath,"data/")
spectrapath <- paste0(datapath,"/Baseline/")
modelpath <- paste0(mainpath,"/modeldata/")
setwd(mainpath)

library(hsdar)
library(caret)
library(doParallel)
library(Rsenal)

load(paste0(modelpath,"specLib.RData"))
load(paste0(modelpath,"rfemodel.RData"))

featureFrame <- data.frame(attribute(specci),as.data.frame(specci))
featureFrame <- featureFrame[!featureFrame$Labornummer%in%c(57341, 57345, 
                                                            57349, 57350, 57352),]
optVars <- names(varsRfeCV(rfemodel,sderror = TRUE))


#cvindices_out <- list()
#acc <- 1
#for (i in unique(featureFrame$Labornummer)){
#  cvindices_out[[acc]] <- which(featureFrame$Labornummer==i)
#  acc <- acc+1
#}
set.seed(100)
#tmp <- createFolds(1:length(unique(featureFrame$Labornummer)),10)
#cvindices_agg <- lapply(tmp,function(x){unlist(cvindices_out[x])})

folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", timevar = NA, k = 10)
#folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", timevar = NA)


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
save(model,file=paste0(modelpath,"finalModel.RData"))

######################################



