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

featureFrame <- data.frame(attribute(specci),as.data.frame(specci))
featureFrame <- featureFrame[!featureFrame$Labornummer%in%c(57341, 57345, 
                                                           57349, 57350, 57352),]


#cvindices_out <- list()
#acc <- 1
#for (i in unique(featureFrame$Labornummer)){
#  cvindices_out[[acc]] <- which(featureFrame$Labornummer==i)
#  acc <- acc+1
#}
set.seed(100)
#tmp <- createFolds(1:length(unique(featureFrame$Labornummer)),10)
#cvindices_agg <- lapply(tmp,function(x){unlist(cvindices_out[x])})
#folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", 
#                              timevar = NA, k = 10)
folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", 
                              timevar = NA, k = 10)

rfFuncs$fit <- function (x, y, first, last, ...) {
  loadNamespace("randomForest")
  randomForest::randomForest(x, y, importance=T,...)
}

rtrl <- rfeControl(method="cv",functions=rfFuncs,rerank = TRUE,
                   index =folds$index,
                   indexOut =folds$indexOut,returnResamp = "all")
ctrl <- trainControl(method="cv",savePredictions = TRUE,verbose=TRUE)

predictors <- featureFrame[-c(1,which(names(featureFrame)%in%c("Labornummer",
                                                               #"Temperature",
                                                               #"Moisture",
                                                               #"Land_use"
                                                               "Basal_respiration"
                                                               )))]
response <- featureFrame$Basal_respiration


cl <- makeCluster(detectCores()-1)
registerDoParallel(cl)

set.seed(100)
rfemodel <- rfe(predictors,response,method="rf",
                trControl=ctrl,
                tuneLength=10,
                rfeControl = rtrl,
                sizes = c(2:10,15,20,25,30,35,40,45,50,60,70,80,90,100,seq(150,500,25),
                          seq(600,ncol(predictors),50)))


          
stopCluster(cl)
save(rfemodel,file=paste0(modelpath,"rfemodel.RData"))
#save(ffsmodel,file=paste0(modelpath,"ffsmodel.RData"))
######################################



