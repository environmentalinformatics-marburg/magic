rm(list=ls())
mainpath <- "/home/hanna/Documents/Presentations/Paper/submitted/Nele_MIRS/data/"
#datapath <- paste0(mainpath,"data/")
#spectrapath <- paste0(datapath,"/Baseline/")
modelpath <- paste0(mainpath,"/modeldata/")
setwd(mainpath)


library(hsdar)
library(caret)
library(doParallel)
library(Rsenal)

load(paste0(modelpath,"specLib.RData"))

featureFrame <- data.frame(attribute(specci),as.data.frame(specci))
featureFrame <- featureFrame[!featureFrame$Labornummer%in%c(57341, 57345, 
                                                            57349, 57350, 57352),]
SI <- read.csv("/home/hanna/Documents/Presentations/Paper/submitted/Nele_MIRS/data/revision_SI/Ergebnisse_Tabelle2_SR.txt",
               sep="\t")
SI <- SI[!duplicated(SI$Labornummer),c("Labornummer","C")]
featureFrame <- merge(featureFrame,SI,by.x="Labornummer",by.y="Labornummer")
predictors <- featureFrame[,c("Temperature","Moisture","Land_use","C")]
response <- featureFrame$Basal_respiration

folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", timevar = NA, 
                              k = length(unique(featureFrame$Labornummer)))     

ctrl <- trainControl(method="cv",savePredictions = TRUE,verbose=TRUE,
                     returnResamp = "all",index=folds$index,indexOut=folds$indexOut)
set.seed(100)
model <- train(predictors,response,method="rf",
               trControl=ctrl,importance=TRUE,
               tuneLength=10)
save(model,file=paste0(modelpath,"model_C.RData"))
