
trainModels <- function (dataset,resampleVar,sampsize,
                         caseStudy,validation,featureSelect,
                         predictors,response,algorithm,outpath,
                         doParallel=FALSE,save=TRUE){
  set.seed(100)
  trainIndex <- createDataPartition(dataset[,resampleVar], 
                                    p = sampsize,
                                    list = FALSE,
                                    times = 1)
  trainData <- dataset[trainIndex,]
  testData <- dataset[-trainIndex,]
  
  
  save(trainData,file=paste0(outpath,"/trainData_",caseStudy,".RData"))
  save(testData,file=paste0(outpath,"/testData_",caseStudy,".RData"))
  
  
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
                         method="cv",savePredictions = TRUE)
    rtrl <- rfeControl(index=cvindices,
                       method="cv", rerank = TRUE)
  }
  if (validation=="cv"){
    ctrl <- trainControl(method="cv",savePredictions = TRUE)
    rtrl <- rfeControl(method="cv", rerank = TRUE)
  }
  
  
  
  ptm <- proc.time()
  if (featureSelect=="noSelection"){
    model <-train(trainData[,predictors],trainData[,response],method=algorithm,
                  trControl = ctrl,tuneLength=3)
  }
  if (featureSelect=="ffs"){
    model <-ffs(trainData[,predictors],trainData[,response],method=algorithm,
                trControl = ctrl,runParallel=TRUE,tuneLength=3)
  }
  if (featureSelect=="bss"){
    model <-bss(trainData[,predictors],trainData[,response],method=algorithm,
                trControl = ctrl,runParallel=TRUE,tuneLength=3)
  }
  if (featureSelect=="rfe"){
    #    rfcl <- rfeControl(rerank = TRUE,
    #               method = "cv")
    model <-rfe(trainData[,predictors],trainData[,response],method=algorithm,
                trControl = trainControl(method="cv"),runParallel=TRUE,tuneLength=3,
                rfeControl=rtrl,sizes=c(2:length(predictors)))
  }
  
  ptm <- proc.time() - ptm
  model$time <- ptm
  
  save(model,file=paste0(outpath,"/model_",algorithm,"_",caseStudy,"_",
                         validation,"_",featureSelect,".RData")) 
  return(model)
}