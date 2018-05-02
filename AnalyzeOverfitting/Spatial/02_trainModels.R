################################################################################
# Model1: Random CV
################################################################################
trainModel <- function (dat,predictors, response, tuneGrid=expand.grid(mtry = 2),
                        nfolds, seed, metric="Kappa", cv, selection,p=0.25,spacevar){
  
  if (selection=="ffs"){
  res <- createDataPartition(factor(dat[,spacevar]),p=p,list=FALSE)
  response <- dat$Class.coarse[res]
  predictors <- predictors[res,]
  dat <- dat[res,]
  }
  
  if (cv=="random"){
    ctrl <- trainControl(method="cv",number = nfolds,
                         savePredictions = TRUE,
                         verbose=TRUE)
  }
  if (cv=="LLO"){
    spacefolds <- CreateSpacetimeFolds(x=dat,
                                       spacevar = spacevar,
                                       k=nfolds,
                                       seed=seed)
    ctrl <- trainControl(method="cv",
                         number=nfolds,
                         savePredictions = TRUE,
                         verbose=TRUE,
                         index=spacefolds$index,
                         indexOut=spacefolds$indexOut)
  }
  
  if (selection=="ffs"){
    
    
    
    model <- ffs(predictors,response,method="rf",
                 trControl = ctrl,seed=seed,
                 tuneGrid = tuneGrid,
                 metric=metric)
    
    
  }
  if (selection=="none"){
    set.seed(seed)
    model <- train(predictors,
                   response,
                   method="rf",
                   trControl = ctrl,
                   tuneGrid = tuneGrid,
                   importance=TRUE,
                   metric=metric)
  }
}


