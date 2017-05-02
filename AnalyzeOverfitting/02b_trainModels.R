#' Train models to compare cv and feature select methods
#' @description The function trains a model with either k-fold cross validation, 
#' leave location out cv (llocv), leave time out cv (ltocv) or leavelocation and
#' time out cv (lltocv) and either no feature selection, rfe or ffs. 
#' FFS and RFE model results in conjucntion with lolocv,ltocv or lltocv are 
#' complemented with k-fold cv results using the selected variables (optional).
#' @param dataset data.frame containing spatio-temporal data
#' @param spacevar Character indicating which column of x identifies the 
#' spatial units (e.g. ID of weather stations)
#' @param timevar Character indicating which column of x identifies the 
#' temporal units (e.g. the day of the year)
#' @param caseStudy Character Name of the case study
#' @param validation character. Either cv, llocv, ltocv or lltocv
#' @param featureSelect character. Either noSelection, ffs or rfe
#' @param predictors character vector. Names of the predictor variables
#' @param response character. Name of the repsonse variable
#' @param algorithm character. ML algorithm name as defined in caret package
#' @param outpath Path where the model will be saved
#' @param doParallel Logical
#' @param save Logical Save model or not
#' @param calculate_random_fold_model Logical Conmplement ffs or rfe model in 
#' conjucntion with llocv,ltocv or lltocv with random k-fold cv performance
#' @param nfolds_spacetime numeric. Number of folds for lltocv
#' @param nfolds_space numeric. Number of folds for llocv
#' @param nfolds_time numeric. Number of folds for ltocv
#' @param tuneLength numeric. see caret description in train

#' @return A trained model
#' @author Hanna Meyer
trainModels <- function (dataset,spacevar,timevar,
                         sampsize,
                         caseStudy,validation,featureSelect,
                         predictors,response,algorithm="rf",outpath,
                         doParallel=FALSE,save=TRUE,
                         calculate_random_fold_model=TRUE,
                         nfolds_spacetime=10,
                         nfolds_space=10,
                         withinSD=TRUE,
                         nfolds_time=10,
                         tuneLength=3,seed=10){
  
  ####################################################################
  #prepare trainControl
  ####################################################################
trainfuncs <- caretFuncs
#trainfuncs <- rfFuncs
#  trainfuncs$fit <- function (x, y, first, last, ...) {
#    loadNamespace("randomForest")
#    randomForest::randomForest(x, y, importance=T,...)
#  }
  rtrl <- rfeControl(method="cv",rerank = TRUE,verbose=TRUE,
                     returnResamp = "all",functions = trainfuncs)
  ctrl <- trainControl(method="cv",savePredictions = TRUE,
                       verbose=TRUE)
  ctrlKfold <- ctrl
  ####################################################################
  #prepare data splitting
  ####################################################################
  if (sampsize!=1){
    dataset <- dataset[createDataPartition(dataset[,response],p=sampsize,list=FALSE),]
  }
  spacefolds <- CreateSpacetimeFolds(x=dataset,timevar=NA,spacevar = spacevar,k=nfolds_space)
  timefolds <- CreateSpacetimeFolds(x=dataset,spacevar=NA, timevar = timevar,k=nfolds_time)
  spacetimefolds <- CreateSpacetimeFolds(x=dataset,spacevar = spacevar,
                                         timevar = timevar,k=nfolds_spacetime)
  
  if (validation=="llocv"){
    ctrl$index=spacefolds$index
    rtrl$index <- spacefolds$index
    ctrl$indexOut <- spacefolds$indexOut
    rtrl$indexOut <- spacefolds$indexOut
  }
  if (validation=="ltocv"){
    ctrl$index <- timefolds$index
    rtrl$index <- timefolds$index
    ctrl$indexOut <- timefolds$indexOut
    rtrl$indexOut <- timefolds$indexOut
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
  ####################################################################
  # TRAIN MODELS
  ####################################################################
  ####################################################################
  if(doParallel){
    require(parallel)
    require(doParallel)
    cl <- makeCluster(detectCores()-2)
    registerDoParallel(cl)
  }
  ####################################################################
  # TRAIN without feature selection
  ####################################################################
  if (featureSelect=="noSelection"){
    set.seed(seed)
    model <- train(dataset[,predictors],dataset[,response],method=algorithm,
                  trControl = ctrl,tuneLength=tuneLength)
  }
  ##############################################################################
  # train ffs model (usually based on llocv, ltocv,lltocv) and if 
  # calculate_random_fold_model==TRUE test
  # how selected variables peform on cv model
  ##############################################################################
  if (featureSelect=="ffs"){
    set.seed(seed)
    model_ffs <- ffs(dataset[,predictors],dataset[,response],method=algorithm,
                 trControl = ctrl,withinSD=withinSD,
                 runParallel=TRUE,tuneLength=3,
                 metric="RMSE")
    model <- train(dataset[,names(model_ffs$trainingData)[-which(
      names(model_ffs$trainingData)==".outcome")]],method=algorithm,
                 trControl = ctrl,
                 runParallel=TRUE,tuneLength=tuneLength,
                 metric="RMSE")
    
    if(save){
    save(model,file=paste0(outpath,"/TMP_model_",algorithm,"_",caseStudy,"_",
                           validation,"_",featureSelect,".RData"))
    }
    # add k-fold cv performance
    if(calculate_random_fold_model){
      set.seed(seed)
      model_cv <- train(dataset[,names(model_ffs$trainingData)[-which(
        names(model_ffs$trainingData)==".outcome")]],
        dataset[,response],method=algorithm,trControl=ctrlKfold,tuneLength=tuneLength,
        metric="RMSE")
      model$random_kfold_cv <- model_cv
    }
  }
  ##############################################################################
  # train rfe model (usually based on llocv, ltocv,lltocv) and test
  #how selected variables peform on cv model
  ##############################################################################
  if (featureSelect=="rfe"){
    set.seed(seed)
    model_raw <- rfe(dataset[,predictors],dataset[,response],
                     method=algorithm,
                     trControl = trainControl(method="cv",
                                              savePredictions = TRUE,
                                              verbose=TRUE),
                     runParallel=TRUE,
                     tuneLength=3,
                     rfeControl=rtrl,
                     sizes=seq(2,length(predictors),2),metric="RMSE")
    if(save){
    save(model_raw,file=paste0(outpath,"/model_raw_",algorithm,"_",caseStudy,"_",
                               validation,"_",featureSelect,".RData"))
    }
    #retrain model using optimal variables
    set.seed(seed)
    model <- train(dataset[,model_raw$optVariables],dataset[,response],
                   method=algorithm,trControl=ctrl,tuneLength=tuneLength,metric="RMSE")
    #add k-fold cv performance
    if(calculate_random_fold_model){
      set.seed(seed)
      model_cv <- train(dataset[,model_raw$optVariables],dataset[,response],
                        method=algorithm,trControl=ctrlKfold,tuneLength=tuneLength,
                        metric="RMSE")
      model$random_kfold_cv <- model_cv
    }
  }
  if(save){
  save(model,file=paste0(outpath,"/model_",algorithm,"_",caseStudy,"_",
                         validation,"_",featureSelect,".RData"))
  }
  if(doParallel){
    stopCluster(cl)
  }
  return(model)
}