
trainModels <- function (dataset,resampleVar,sampsize,
                         caseStudy,validation,featureSelect,
                         predictors,response,algorithm,outpath,
                         doParallel=FALSE,save=TRUE){
  set.seed(100)
  if (sampsize==1){
    trainData <- dataset
  }else{
  trainIndex <- createDataPartition(dataset[,resampleVar], 
                                    p = sampsize,
                                    list = FALSE,
                                    times = 1)
  trainData <- dataset[trainIndex,]
  testData <- dataset[-trainIndex,]
  save(testData,file=paste0(outpath,"/testData_",caseStudy,".RData"))
  }
  
  save(trainData,file=paste0(outpath,"/trainData_",caseStudy,".RData"))
 
  
  
  rfFuncs2 <- rfFuncs
  rfFuncs2$fit <- function (x, y, first, last, ...) {
    loadNamespace("randomForest")
    randomForest::randomForest(x, y, importance=T,...)
  }
  
  cvindices <- list()
  acc <- 1
  for (i in unique(trainData[,resampleVar])){
    cvindices[[acc]] <- which(trainData[,resampleVar]!=i)
    acc <- acc+1
  }
  
  
  if(doParallel){
    require(parallel)
    require(doParallel)
    cl <- makeCluster(detectCores())
    registerDoParallel(cl)
  }
  if (validation=="losocv"){
    ctrl <- trainControl(index=cvindices,
                         method="cv",savePredictions = TRUE,
                         verbose=TRUE)
    rtrl <- rfeControl(method="cv",index=cvindices, rerank = TRUE,verbose=TRUE,
                       returnResamp = "all",functions = rfFuncs2)
  }
  if (validation=="cv"){
    ctrl <- trainControl(method="cv",savePredictions = TRUE,verbose=TRUE)
    rtrl <- rfeControl(method="cv", rerank = TRUE,verbose=TRUE,
                       returnResamp = "all",functions = rfFuncs2)

  }
  

  
  
  ptm <- proc.time()
  if (featureSelect=="noSelection"){
    set.seed(100)
    model <-train(trainData[,predictors],trainData[,response],method=algorithm,
                  trControl = ctrl,tuneLength=3)
  }
  if (featureSelect=="ffs"){
    set.seed(100)
    model <-ffs(trainData[,predictors],trainData[,response],method=algorithm,
                trControl = ctrl,runParallel=TRUE,tuneLength=3)
  }
  if (featureSelect=="bss"){
    model <-bss(trainData[,predictors],trainData[,response],method=algorithm,
                trControl = ctrl,runParallel=TRUE,tuneLength=3)
  }
  if (featureSelect=="rfe"){
      #fold <- createFolds(trainData$month,10)
        #rfcl <- rfeControl(rerank = TRUE,
         #          method = "cv",index=fold,verbose=TRUE)
    if (caseStudy=="Tair"){
      #trainData$season<-as.numeric(trainData$season)
      #trainData$aspect<-as.numeric(trainData$aspect)
      #trainData$time <- as.numeric(trainData$time)
      #trainData$month <- as.numeric(trainData$month)
      #trainData$ice <- as.numeric(trainData$ice)
      #trainData$sensor <- as.numeric(trainData$sensor)
    }
    set.seed(100)
    model <-rfe(trainData[,predictors],trainData[,response],
                method=algorithm,
                trControl = trainControl(method="cv",
                                         savePredictions = TRUE,verbose=TRUE),
                runParallel=TRUE,
                tuneLength=2,
                rfeControl=rtrl,
                sizes=seq(2,length(predictors),2))
  }
  
  ptm <- proc.time() - ptm
  model$time <- ptm
  
  save(model,file=paste0(outpath,"/model_",algorithm,"_",caseStudy,"_",
                         validation,"_",featureSelect,".RData")) 
  return(model)
}