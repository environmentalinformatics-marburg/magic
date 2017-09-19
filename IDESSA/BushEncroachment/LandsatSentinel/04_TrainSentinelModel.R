library(CAST)
library(caret)
#mainpath <- "/media/memory02/casestudies/hmeyer/IDESSA_LandCover/AerialToSentinel/"
mainpath <- "/mnt/sd19007/casestudies/hmeyer/IDESSA_LandCover/AerialToSentinel/"
outpath <- paste0(mainpath,"/results")
datapath <- paste0(mainpath,"/data")

trainingtile_perc <- 0.33 # percentage of tiles to get training pixels from.
#keep the rest for spatially independent validation
trainingpixels <- 150000 # number of training pixels taken from training tiles

################################################################################
# PREPARATION
################################################################################
#read and clean data:
dataset <- readRDS(paste0(datapath,"/sentinel_bush_final.RDS"))
dataset <- dataset[complete.cases(dataset),]
names(dataset)[3:ncol(dataset)] <- paste0("S",names(dataset)[3:ncol(dataset)])

#define predictors and response:
predictors <- apply(expand.grid(c("S01_","S04_","S07_"),
              c(#"B1",
                "B11","B12","B2","B3","B4",
                "B5","B6","B7","B8","B8A",
                #"B9",
                "ndvi","ndvi_mn","ndvi_sd")),
              1,paste, collapse="")
response <- "bush"
# split data into 3 folds according to tile. use 1/5 tiles for training
k <- round(1/trainingtile_perc,0)
foldids <- CreateSpacetimeFolds(dataset,spacevar="tile_nr",k=k,seed=100)
traindata <- dataset[foldids$indexOut[[1]],]
testdata <- dataset[unlist(foldids$indexOut[2:k]),]
save(testdata,file=paste0(outpath,"/testdata_V2.RData"))
save(traindata,file=paste0(outpath,"/traindata_V2.RData"))

#reduce amount of training data pixels
traindata_subs <- createDataPartition(traindata$bush,list=FALSE,
                                 p=100/nrow(traindata)*trainingpixels/100)
traindata <- traindata[traindata_subs,]
save(traindata,file=paste0(outpath,"/traindata_final_V2.RData"))
# prepare a 10-fold LLOCV
foldids <- CreateSpacetimeFolds(traindata,spacevar="tile_nr",
                                k=10,seed=100)
ctrl <- trainControl(method="cv",
                     savePredictions = "all",
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
               trControl = ctrl,tuneLength=3)
#stop cluster and save model:
stopCluster(cl)
save(model,file=paste0(outpath,"/sentinelmodel_V2.RData"))
################################################################################