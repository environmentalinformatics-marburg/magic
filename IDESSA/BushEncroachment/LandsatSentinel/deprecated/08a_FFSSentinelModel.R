#install.packages("CAST")
rm(list=ls())
library(CAST)
library(caret)
mainpath <- "/mnt/sd19007/users/hmeyer/IDESSA_LandCover/AerialToSentinel/classification_2016/"
outpath <- paste0(mainpath,"/results")
datapath <- paste0(mainpath,"/data")

#trainingtile_perc <- 0.33 # percentage of tiles to get training pixels from.
#keep the rest for spatially independent validation
trainingpixels <- 50000 # number of training pixels taken from training tiles

################################################################################
# PREPARATION
################################################################################
#read and clean data:
dataset <- readRDS(paste0(datapath,"/train.RDS"))
dataset <- dataset[complete.cases(dataset),]
#define predictors and response:
predictors <- apply(expand.grid(
  c("B1","B11","B12","B2","B3","B4",
    "B5","B6","B7","B8","B8A","B9",
    "ndvi","ndvi_mn","ndvi_sd","sen1"),
  c("_01","_04","_07")),
  1,paste, collapse="")
response <- "bush_perc"
#reduce amount of training data pixels

set.seed(100)
data_subs <- createDataPartition(dataset[,which(names(dataset)==response)],
                                 list=FALSE,
                                 p=100/nrow(dataset)*trainingpixels/100)
dataset <- dataset[data_subs,]
rm(data_subs)
# prepare a 10-fold LLOCV
foldids <- CreateSpacetimeFolds(dataset,spacevar="lcc_tile",
                                k=3,seed=100)
ctrl <- trainControl(method="cv",
                     savePredictions = FALSE,
                     verbose=FALSE,
                     index=foldids$index,
                     indexOut=foldids$indexOut)
################################################################################
# MODELLING
################################################################################
#start parallel processing on all cores except 3:
require(parallel)
require(doParallel)
cl <- makeCluster(10)
registerDoParallel(cl)
#train model:
set.seed(100)
model <- ffs(dataset[,predictors],
             dataset[,response],
             method="rf",
             trControl = ctrl,
             tuneLength=1,
             withinSE = TRUE)
#stop cluster and save model:
stopCluster(cl)
save(model,file=paste0(outpath,"/sentinel_FFS.RData"))
################################################################################
