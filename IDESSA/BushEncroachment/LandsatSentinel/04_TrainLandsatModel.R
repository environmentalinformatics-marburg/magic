rm(list=ls())
library(CAST)
library(caret)
#mainpath <- "/media/memory02/casestudies/hmeyer/IDESSA_LandCover/AerialToLandsat/"
#mainpath <- "/mnt/sd19007/casestudies/hmeyer/IDESSA_LandCover/AerialToLandsat/"
mainpath <- "/home/hmeyer/bushEncroachment/"
outpath <- paste0(mainpath,"/results/")
datapath <- paste0(mainpath,"/data/")

trainingtile_perc <- 0.5 # percentage of tiles to get training pixels from.
#keep the rest for spatially independent validation
trainingpixels <- 150000 # number of training pixels taken from training tiles

################################################################################
# PREPARATION
################################################################################
#read and clean data:
dataset <- read.csv(paste0(datapath,"/ex_L8.csv"))
dataset <- dataset[complete.cases(dataset),]
names(dataset)[grepl("ac_b_",names(dataset))] <- substr(names(dataset)[
  grepl("ac_b_",names(dataset))],8,
  nchar(names(dataset)[grepl("ac_b_",names(dataset))]))
#define predictors and response:
predictors <- c("b_dry","g_dry","r_dry","NIR_dry","SWIR1_dry",
                "SWIR2_dry","b_rainy","g_rainy","r_rainy",
                "NIR_rainy","SWIR1_rainy","SWIR2_rainy",
                "NDVI_dry","NDVI_rainy")
response <- "bush_perc"
# split data into 3 folds according to tile. use 1/5 tiles for training
k <- round(1/trainingtile_perc,0)
foldids <- CreateSpacetimeFolds(dataset,spacevar="bush_class_tile",k=k,seed=100)
traindata <- dataset[foldids$indexOut[[1]],]
testdata <- dataset[unlist(foldids$indexOut[2:k]),]
save(testdata,file=paste0(outpath,"/testdata.RData"))
save(traindata,file=paste0(outpath,"/traindata.RData"))
rm(testdata)
rm(dataset)
gc()
#reduce amount of training data pixels
traindata_subs <- createDataPartition(traindata$bush_perc,list=FALSE,
                                 p=100/nrow(traindata)*trainingpixels/100)
traindata <- traindata[traindata_subs,]
save(traindata,file=paste0(outpath,"/traindata_final.RData"))

# prepare a 10-fold LLOCV
foldids <- CreateSpacetimeFolds(traindata,spacevar="bush_class_tile",
                                k=10,seed=100)
ctrl <- trainControl(method="cv",
                     savePredictions = "all",
                     index=foldids$index,
                     indexOut=foldids$indexOut,
                     verboseIter=TRUE,
                     returnResamp = "all")
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
               trControl = ctrl,tuneLength=3,importance=TRUE)
#stop cluster and save model:
stopCluster(cl)
save(model,file=paste0(outpath,"/landsatmodel.RData"))
################################################################################