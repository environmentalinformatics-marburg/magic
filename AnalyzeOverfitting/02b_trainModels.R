
trainModels <- function (dataset,spacevar,timevar,
                         sampsize,
                         caseStudy,validation,featureSelect,
                         predictors,response,algorithm,outpath,
                         doParallel=FALSE,save=TRUE,
                         calculate_random_fold_model=TRUE,
                         nfolds_spacetime=10,
                         nfolds_space=10,
                         nfolds_time=10){
  

  
  
  rfFuncs2 <- rfFuncs
  rfFuncs2$fit <- function (x, y, first, last, ...) {
    loadNamespace("randomForest")
    randomForest::randomForest(x, y, importance=T,...)
  }
  
  spacefolds <- CreateSpacetimeFolds(x=dataset,timevar=NA,spacevar = spacevar,k=nfolds_space)
  timefolds <- CreateSpacetimeFolds(x=dataset,spacevar=NA, timevar = timevar,k=nfolds_time)
  spacetimefolds <- CreateSpacetimeFolds(x=dataset,spacevar = spacevar,
                                         timevar = timevar,k=nfolds_spacetime)
  
  
  rtrl <- rfeControl(method="cv",rerank = TRUE,verbose=TRUE,
                     returnResamp = "all",functions = rfFuncs2)
  ctrl <- trainControl(method="cv",savePredictions = TRUE,
                       verbose=TRUE)
  ctrlKfold <- ctrl
  
  ####################################################################
  if (validation=="llocv"){
    ctrl$index=spacefolds$index
    rtrl$index <- spacefolds$index
    ctrl$indexOut <- spacetimefolds$indexOut
    rtrl$indexOut <- spacetimefolds$indexOut
  }
  if (validation=="ltocv"){
    ctrl$index=timefolds$index
    rtrl$index <- timefolds$index
    ctrl$indexOut <- spacetimefolds$indexOut
    rtrl$indexOut <- spacetimefolds$indexOut
  }
  if (validation=="lltocv"){
    ctrl$index <- spacetimefolds$index
    rtrl$index <- spacetimefolds$index
    ctrl$indexOut <- spacetimefolds$indexOut
    rtrl$indexOut <- spacetimefolds$indexOut
  }
  if(validation=="cv"){
    calculate_random_fold_model=FALSE
  }
  ####################################################################
  # TRAIN
  ####################################################################
  if(doParallel){
    require(parallel)
    require(doParallel)
    cl <- makeCluster(detectCores()-2)
    registerDoParallel(cl)
  }
  
  if (featureSelect=="noSelection"){
    set.seed(100)
    model <- train(dataset[,predictors],dataset[,response],method=algorithm,
                  trControl = ctrl,tuneLength=3)
  }
  #####
  # train ffs model (usually based on llocv, ltocv,lltocv) and if 
  # calculate_random_fold_model==TRUE test
  # how selected variables peform on cv model
  ####
  if (featureSelect=="ffs"){
    set.seed(100)
    model <- ffs(dataset[,predictors],dataset[,response],method=algorithm,
                 trControl = ctrl,runParallel=TRUE,tuneLength=3)
    save(model,file=paste0(outpath,"/TMP_model_",algorithm,"_",caseStudy,"_",
                           validation,"_",featureSelect,".RData"))
    if(calculate_random_fold_model){
      set.seed(100)
      model_cv <- train(dataset[,names(model$trainingData)[-which(
        names(model$trainingData)==".outcome")]],
        dataset[,response],method=algorithm,trControl=ctrlKfold,tuneLength=3)
      model$random_kfold_cv <- model_cv
    }
  }
  #####
  # train rfe model (usually based on llocv, ltocv,lltocv) and test
  #how selected variables peform on cv model
  ####
  if (featureSelect=="rfe"){
    set.seed(100)
    model_raw <- rfe(dataset[,predictors],dataset[,response],
                     method=algorithm,
                     trControl = trainControl(method="cv",
                                              savePredictions = TRUE,
                                              verbose=TRUE),
                     runParallel=TRUE,
                     tuneLength=2,
                     rfeControl=rtrl,
                     sizes=seq(2,length(predictors),2))
    save(model_raw,file=paste0(outpath,"/model_raw_",algorithm,"_",caseStudy,"_",
                               validation,"_",featureSelect,".RData"))
    #retrain model using optimal variables
    set.seed(100)
    model <- train(dataset[,model_raw$optVariables],dataset[,response],
                   method=algorithm,trControl=ctrl,tuneLength=3)
    
    if(calculate_random_fold_model){
      set.seed(100)
      model_cv <- train(dataset[,model_raw$optVariables],dataset[,response],
                        method=algorithm,trControl=ctrlKfold,tuneLength=3)
      model$random_kfold_cv <- model_cv
    }
  }
  save(model,file=paste0(outpath,"/model_",algorithm,"_",caseStudy,"_",
                         validation,"_",featureSelect,".RData"))
  if(doParallel){
    stopCluster(cl)
  }
  return(model)
}