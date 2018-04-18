rm(list=ls())
library(caret)
library(CAST)
#require(parallel)
require(doParallel)
mainpath <- "/home/hmeyer/OverfitSpatialLUC/"
#mainpath <-"/home/hanna/Documents/Projects/SpatialCV/"
outpath <- paste0(mainpath, "/results")
datapath <- paste0(mainpath,"/data")
dat <- read.csv(paste0(datapath,"/Coastal structure data.csv"),sep=";")

#response_fine <- dat$Class.fine
predictors <- dat[,c(7:319,337:341,347,348)]
dat <- dat[complete.cases(predictors),]

response <- dat$Class.coarse
predictors <- predictors[complete.cases(predictors),]


seed <- 100
nfolds <- length(unique(dat$Loc_no))
spacevar <- "Loc_no"

################################################################################
# Model1: Random CV
################################################################################
#ctrl <- trainControl(method="cv",number = nfolds,
#                     savePredictions = TRUE,
#                     verbose=TRUE)

#cl <- makeCluster(14)
#registerDoParallel(cl)

#set.seed(seed)
#model <- train(predictors,
#               response,
#               method="rf",
#               trControl = ctrl,
#               tuneGrid = expand.grid(mtry = 2),
#               importance=TRUE,
#               metric="Kappa")
#stopCluster(cl)
#save(model,file=paste0(outpath,"/model_random_noSelect.RData"))

################################################################################
# Model2: LLOCV
################################################################################

# spacefolds <- CreateSpacetimeFolds(x=dat,
#                                    spacevar = spacevar,
#                                    k=nfolds,
#                                    seed=seed)
# ctrl <- trainControl(method="cv",number=nfolds,
#                      savePredictions = TRUE,
#                      verbose=TRUE,
#                      index=spacefolds$index,
#                      indexOut=spacefolds$indexOut)
# 
# cl <- makeCluster(14)
# registerDoParallel(cl)
# 
# set.seed(seed)
# model <- train(predictors,
#                response,
#                method="rf",
#                trControl = ctrl,
#                tuneGrid = expand.grid(mtry = 2),
#                importance=TRUE,
#                metric="Kappa")
# stopCluster(cl)
# save(model,file=paste0(outpath,"/model_LLO_noSelect.RData"))
################################################################################
# Model3: LLOCV with FFS
################################################################################
nfolds <- 10 #!!! ONLY FOR FFS

 spacefolds <- CreateSpacetimeFolds(x=dat,
                                    spacevar = spacevar,
                                    k=nfolds,
                                    seed=seed)
 ctrl <- trainControl(method="cv",number=nfolds,
                      savePredictions = TRUE,
                      verbose=TRUE,
                      index=spacefolds$index,
                      indexOut=spacefolds$indexOut)

cl <- makeCluster(14)
registerDoParallel(cl)
model <- ffs(predictors,response,method="rf",
             trControl = ctrl,seed=seed,
             tuneGrid = expand.grid(mtry = 2),
             metric="Kappa")
stopCluster(cl)
save(model,file=paste0(outpath,"/model_LLO_ffs.RData"))

################################################################################
# Model4: retrain LLO after FFS
################################################################################


################################################################################
# Model5: random CV after FFS
################################################################################
# ctrl <- trainControl(method="cv",number=nfolds,
#                      savePredictions = TRUE,
#                      verbose=TRUE)
# 
# predictors <- model$trainingData[,1:ncol(model$trainingData)]
# 
# 
# cl <- makeCluster(14)
# registerDoParallel(cl)
# 
# model <- train(predictors,
#                response,
#                method="rf",
#                trControl = ctrl,
#                tuneGrid = expand.grid(mtry = 2),
#                importance=TRUE,
#                metric="Kappa")
# stopCluster(cl)
# save(model,file=paste0(outpath,"/model_random_ffs.RData"))
# 
# 


