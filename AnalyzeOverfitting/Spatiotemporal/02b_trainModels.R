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
                         metric,
                         nfolds_time=10,
                         tuneLength=3,tuneGrid=NA,seed=100){
  
  ####################################################################
  #prepare trainControl
  ####################################################################
  #modify RFE function:
  #trainfuncs <- caretFuncs #use caretFubcs if tuning is still required
  trainfuncs <- rfFuncs 
  trainfuncs$fit <- function (x, y, first, last, ...) {
    loadNamespace("randomForest")
    randomForest::randomForest(x, y, importance=T,...)
  }
  # set seeds to make sure models are identical though running in parallel:
  set.seed(seed)
  tl <- tuneLength
  if (is.na(tuneLength)){tl <- nrow(tuneGrid)}
  seeds <- vector(mode = "list", 
                  length = max(nfolds_space,nfolds_spacetime,nfolds_time)+1)
  for(seed in 1:(max(nfolds_space,nfolds_spacetime,nfolds_time)+1)){ 
    seeds[[seed]] <- sample.int(1000, tl)
  }
  # set rfe and train control
  rtrl <- rfeControl(method="cv",
                     verbose=TRUE,
                     returnResamp = "all",
                     functions = trainfuncs)
  
  ctrl <- trainControl(method="cv",
                       savePredictions = TRUE,
                       verbose=TRUE)
  ctrlKfold <- ctrl
  ctrlKfold$seeds <- seeds[c(1:10,length(seeds))]
  ####################################################################
  #prepare data splitting
  ####################################################################
  if (sampsize!=1){
    dataset <- dataset[createDataPartition(dataset[,response],
                                           p=sampsize,list=FALSE),]
  }
  # create Index and Index out for fifferent CV strategies: 
  spacefolds <- CreateSpacetimeFolds(x=dataset,timevar=NA,spacevar = spacevar,
                                     k=nfolds_space,seed=seed)
  timefolds <- CreateSpacetimeFolds(x=dataset,spacevar=NA, timevar = timevar,
                                    k=nfolds_time,seed=seed)
  spacetimefolds <- CreateSpacetimeFolds(x=dataset,spacevar = spacevar,
                                         timevar = timevar,
                                         k=nfolds_spacetime,seed=seed)
  # adapt index values in trainControl accordingly: 
  if (validation=="llocv"){
    ctrl$index <- spacefolds$index
    rtrl$index <- spacefolds$index
    ctrl$indexOut <- spacefolds$indexOut
    rtrl$indexOut <- spacefolds$indexOut
    ctrl$seeds <- seeds[c(1:nfolds_space,length(seeds))]
    #    rtrl$seeds <- ctrl$seeds
  }
  if (validation=="ltocv"){
    ctrl$index <- timefolds$index
    rtrl$index <- timefolds$index
    ctrl$indexOut <- timefolds$indexOut
    rtrl$indexOut <- timefolds$indexOut
    ctrl$seeds <- seeds[c(1:nfolds_time,length(seeds))]
  }
  if (validation=="lltocv"){
    ctrl$index <- spacetimefolds$index
    rtrl$index <- spacetimefolds$index
    ctrl$indexOut <- spacetimefolds$indexOut
    rtrl$indexOut <- spacetimefolds$indexOut
    ctrl$seeds <- seeds[c(1:nfolds_spacetime,length(seeds))]
  }
  if(validation=="cv"){
    calculate_random_fold_model=FALSE
    ctrl$seeds <- seeds[c(1:10,length(seeds))]
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
                   trControl = ctrl,tuneLength=tuneLength,
                   tuneGrid = tuneGrid,
                   importance=TRUE)
  }
  ##############################################################################
  # train ffs model (usually based on llocv, ltocv,lltocv) and if 
  # calculate_random_fold_model==TRUE test how selected variables peform for
  # random cv
  ##############################################################################
  if (featureSelect=="ffs"){
    set.seed(seed)
    model <- ffs(dataset[,predictors],dataset[,response],method=algorithm,
                 trControl = ctrl,withinSD=withinSD,seed=seed,
                 runParallel=TRUE,tuneLength=tuneLength,
                 tuneGrid = tuneGrid,
                 metric=metric)
    if(save){
      save(model,file=paste0(outpath,"/TMP_model_",algorithm,"_",caseStudy,"_",
                             validation,"_",featureSelect,".RData"))
    }
    # add random k-fold cv performance
    if(calculate_random_fold_model){
      set.seed(seed)
      model_cv <- train(dataset[,names(model$trainingData)[-which(
        names(model$trainingData)==".outcome")]],
        dataset[,response],method=algorithm,trControl=ctrlKfold,tuneLength=tuneLength,
        tuneGrid = tuneGrid,
        metric=metric)
      model$random_kfold_cv <- model_cv
    }
  }
  ##############################################################################
  #train rfe model (usually based on llocv, ltocv,lltocv) and test
  #how selected variables peform for random cv
  ##############################################################################
  if (featureSelect=="rfe"){
    set.seed(seed)
    
    model_raw <- rfe(dataset[,predictors],dataset[,response],
                     method=algorithm,
                     # trControl = trainControl(method="cv",
                     #    savePredictions = TRUE,
                     #    verbose=TRUE),
                     runParallel=TRUE,
                     #               tuneLength=tuneLength,
                     rfeControl=rtrl,
                     sizes=seq(2,length(predictors),1),metric=metric)
    if(save){
      save(model_raw,file=paste0(outpath,"/model_raw_",algorithm,"_",caseStudy,"_",
                                 validation,"_",featureSelect,".RData"))
    }
    #retrain model using optimal variables
    set.seed(seed)
    model <- train(dataset[,model_raw$optVariables],dataset[,response],
                   method=algorithm,trControl=ctrl,tuneLength=tuneLength,
                   tuneGrid = tuneGrid,metric=metric)
    #add random k-fold cv performance
    if(calculate_random_fold_model){
      set.seed(seed)
      model_cv <- train(dataset[,model_raw$optVariables],dataset[,response],
                        method=algorithm,trControl=ctrlKfold,tuneLength=tuneLength,
                        tuneGrid = tuneGrid,
                        metric=metric)
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