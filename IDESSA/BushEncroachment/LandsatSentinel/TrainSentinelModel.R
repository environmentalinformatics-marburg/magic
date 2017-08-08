library(CAST)
library(caret)
mainpath <- "/media/memory02/casestudies/hmeyer/IDESSA_LandCover/AerialToSentinel/"
outpath <- paste0(mainpath,"/results")
datapath <- paste0(mainpath,"/data")
################################################################################
# PREPARATION
################################################################################
#read and clean data:
dataset <- readRDS(paste0(datapath,"/sen_data.RDS"))
dataset <- dataset[complete.cases(dataset),]
#define predictors and response:
predictors <- c("B1","B11","B12","B2","B3","B4","B5","B6","B7","B8","B8A","B9",
                "ndvi","ndvi_mn","ndvi_sd")
response <- "bush_perc"
# split data into 3 folds according to tile. use 1/2 for training
foldids <- CreateSpacetimeFolds(dataset,spacevar="bush_class_tile",k=2,seed=100)
traindata <- dataset[foldids$indexOut[[1]],]
testdata <- dataset[foldids$indexOut[[2]],]
save(testdata,file=paste0(outpath,"/testdata.RData"))
save(traindata,file=paste0(outpath,"/traindata.RData"))

# prepare a 10-fold LLOCV
foldids <- CreateSpacetimeFolds(traindata,spacevar="bush_class_tile",
                                k=10,seed=100)
ctrl <- trainControl(method="cv",
                     savePredictions = TRUE,
                     verbose=TRUE,
                     index=foldids$index,
                     indexOut=foldids$indexOut)
################################################################################
# MODELLING
################################################################################
#start parallel processing on all cores except 3:
require(parallel)
require(doParallel)
cl <- makeCluster(detectCores()-3)
registerDoParallel(cl)
#train model:
set.seed(100)
model <- train(traindata[,predictors],traindata[,response],
               method="rf",
               trControl = ctrl,tuneLength=3,
               importance=TRUE)
#stop cluster and save model:
stopCluster(cl)
save(model,file=paste0(outpath,"/sentinelmodel.RData"))
################################################################################