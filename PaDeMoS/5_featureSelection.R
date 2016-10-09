load("/home/hanna/Documents/Presentations/Paper/Meyer2016_PaDeMoS/scripts_and_data/results//trainData/FeatureFrame.RData")

library(caret)
library(hsdar)

cvSplits<-createFolds(featureFrame$attributes$VegCover, k = 10, list = TRUE, returnTrain = FALSE)



rfeModel_Vegcover<-list()
for (i in 1:(length(featureFrame)-1)){
  tctrl <- trainControl(method="cv")
  rctrl <- rfeControl(index=cvSplits,
                      returnResamp = "all",
                    functions = rfFuncs,
                      method="cv")
  predictors<-data.frame(featureFrame[[i]],"VegType"=featureFrame$attributes$VegType)
  response<-featureFrame$attributes$VegCover
  size <- 1:ncol(predictors)
  if (ncol(predictors)>50){
    size<-c(1:10,15,seq(20,50,10),75,100,seq(150,ncol(predictors),50))
  }
  
### RFE Model  ###############################################################    
rfeModel_Vegcover[[i]] <- rfe(predictors,
                response,
                linout = TRUE,
                trace = FALSE,
                sizes = size,
                method = "rf",
                rfeControl = rctrl,
                trControl=tctrl,
                tuneLength=5,
                metric="RMSE",
                maximize=FALSE)

  print(i)
}

save(rfeModel_Vegcover,file="/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/rfeModel_Vegcover.RData")
################################################################################
featureFrame <- lapply(featureFrame,function(x)x[!is.na(featureFrame$attributes$biomass),])
#cvSplits<-createFolds(featureFrame$attributes$biomass, k = 10, list = TRUE, returnTrain = FALSE)
rfeModel_Biomass<-list()
for (i in 1:(length(featureFrame)-1)){
  tctrl <- trainControl(method="repeatedcv",number=3,repeats=50)
  rctrl <- rfeControl(#returnResamp = "all",
                      functions = rfFuncs,
                      method="repeatedcv",repeats=50,number=3)
  predictors<-data.frame(featureFrame[[i]],"VegType"=featureFrame$attributes$VegType,
                         "VegCover"=featureFrame$attributes$VegCover)
  response<-featureFrame$attributes$biomass
  size <- 1:ncol(predictors)
  if (ncol(predictors)>50){
    size<-c(1:10,15,seq(20,50,10),75,100,seq(150,2000,200),seq(2500,ncol(predictors),500))
  }
  
  ### RFE Model  ###############################################################    
  rfeModel_Biomass[[i]] <- rfe(predictors,
                       response,
                       linout = TRUE,
                       trace = FALSE,
                       sizes = size,
                       method = "rf",
                       rfeControl = rctrl,
                       trControl=tctrl,
                       tuneLength=5,
                       metric="RMSE",
                       maximize=FALSE)
  

  print(i)
}
save(rfeModel_Biomass,file="/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/rfeModel_Biomass.RData")

