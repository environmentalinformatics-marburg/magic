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

source(paste0(mainpath,"02_trainModels.R"))
#response_fine <- dat$Class.fine
predictors <- dat[,c(7:319,337:341,347,348)]
dat <- dat[complete.cases(predictors),]

response <- dat$Class.coarse
predictors <- predictors[complete.cases(predictors),]


seed <- 100
nfolds <- length(unique(dat$Loc_no))
spacevar <- "Loc_no"


###Random CV
cl <- makeCluster(14)
registerDoParallel(cl)
model <- trainModel(dat,predictors, response, tuneGrid=expand.grid(mtry = 2:ncol(predictors)),
                    nfolds, seed=seed, metric="Kappa",cv="random",selection="none",
                    spacevar=spacevar,nfolds=nfolds)
stopCluster(cl)
save(model,file=paste0(outpath,"/model_random_noSelect.RData"))


cl <- makeCluster(14)
registerDoParallel(cl)
model <- trainModel(dat,predictors, response, tuneGrid=expand.grid(mtry = 2:ncol(predictors)),
                    nfolds, seed=seed, metric="Kappa",cv="LLO",selection="none",
                    spacevar=spacevar,nfolds=nfolds)
stopCluster(cl)
save(model,file=paste0(outpath,"/model_LLO_noSelect.RData"))

cl <- makeCluster(14)
registerDoParallel(cl)
model <- trainModel(dat,predictors, response, tuneGrid=expand.grid(mtry = 2),
                    nfolds, seed=seed, metric="Kappa",cv="LLO",selection="ffs",
                    spacevar=spacevar,nfolds=nfolds,p=0.3)
stopCluster(cl)
save(model,file=paste0(outpath,"/model_LLO_FFS.RData"))

predictors <- predictors[,model$selectedvars]

cl <- makeCluster(14)
registerDoParallel(cl)
model <- trainModel(dat,predictors, response, tuneGrid=expand.grid(mtry = 2:ncol(predictors)),
                    nfolds, seed=seed, metric="Kappa",cv="LLO",selection="none",
                    spacevar=spacevar,nfolds=nfolds)
stopCluster(cl)
save(model,file=paste0(outpath,"/model_LLO_afterFFS.RData"))


cl <- makeCluster(14)
registerDoParallel(cl)
model <- trainModel(dat,predictors, response, tuneGrid=expand.grid(mtry = 2:ncol(predictors)),
                    nfolds, seed=seed, metric="Kappa",cv="random",selection="none",
                    spacevar=spacevar,nfolds=nfolds)
stopCluster(cl)
save(model,file=paste0(outpath,"/model_random_afterFFS.RData"))


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
# nfolds_ffs <- 10 #!!! ONLY FOR FFS
# 
# 
# res <- createDataPartition(factor(dat[,spacevar]),p=0.25,list=FALSE)
# response <- dat$Class.coarse[res]
# predictors <- predictors[res,]
# subs <- dat[res,]
# 
#  spacefolds <- CreateSpacetimeFolds(x=subs,
#                                     spacevar = spacevar,
#                                     k=nfolds_ffs,
#                                     seed=seed)
#  ctrl <- trainControl(method="cv",number=nfolds_ffs,
#                       savePredictions = TRUE,
#                       verbose=TRUE,
#                       index=spacefolds$index,
#                       indexOut=spacefolds$indexOut)
# 
# cl <- makeCluster(10)
# registerDoParallel(cl)
# model <- ffs(predictors,response,method="rf",
#              trControl = ctrl,seed=seed,
#              tuneGrid = expand.grid(mtry = 2),
#              metric="Kappa")
# stopCluster(cl)
# save(model,file=paste0(outpath,"/model_LLO_ffs.RData"))

################################################################################
# Model4: retrain LLO after FFS
################################################################################
# load(paste0(outpath,"/model_LLO_ffs.RData"))
# predictors <- predictors[,model$selectedvars]
# spacefolds <- CreateSpacetimeFolds(x=dat,
#                                     spacevar = spacevar,
#                                     k=nfolds,
#                                     seed=seed)
#  ctrl <- trainControl(method="cv",number=nfolds,
#                       savePredictions = TRUE,
#                       verbose=TRUE,
#                       index=spacefolds$index,
#                       indexOut=spacefolds$indexOut)
# # 
#  cl <- makeCluster(14)
#  registerDoParallel(cl)
# # 
#  set.seed(seed)
#  model <- train(predictors,
#                 response,
#                 method="rf",
#                 trControl = ctrl,
#                 tuneGrid = expand.grid(mtry = 2),
#                 importance=TRUE,
#                 metric="Kappa")
#  stopCluster(cl)
#  save(model,file=paste0(outpath,"/model_LLO_afterFFS.RData"))
# 
# 
# 
# 
# ################################################################################
# # Model5: random CV after FFS
# ################################################################################
#  ctrl <- trainControl(method="cv",number=nfolds,
#                       savePredictions = TRUE,
#                       verbose=TRUE)
#  
#  cl <- makeCluster(14)
#  registerDoParallel(cl)
# # 
#  model <- train(predictors,
#                 response,
#                 method="rf",
#                 trControl = ctrl,
#                 tuneGrid = expand.grid(mtry = 2),
#                 importance=TRUE,
#                 metric="Kappa")
#  stopCluster(cl)
#  save(model,file=paste0(outpath,"/model_random_afterFFS.RData"))
# # 
# # 
# 
# 
