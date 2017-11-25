#predict "Q10_exp_45" und "Basal_25_45_µg" Stability
rm(list=ls())
mainpath <- "/home/hmeyer/tmp_calculations/MIRS/"
#mainpath <- "/home/hanna/Documents/Presentations/Paper/submitted/Nele_MIRS/data/"
datapath <- paste0(mainpath,"data/")
spectrapath <- paste0(datapath,"/Baseline/")
modelpath <- paste0(mainpath,"/modeldata/")
setwd(mainpath)

#use hsdar version _0.5.1.tar.gz
install.packages(paste0(mainpath,"hsdar_0.5.1.tar.gz"),repos=NULL)
library(hsdar)
library(caret)
library(doParallel)
library(Rsenal)
library(CAST)

#head(featureFrame[,c(1:6,1844,1839)])
load(paste0(modelpath,"specLib.RData"))
SI <- read.table(paste0(mainpath,"/revision_SI/Ergebnisse_MIRS_Datensatz.txt"),sep="\t",header=TRUE)

featureFrame <- data.frame(attribute(specci),as.data.frame(specci))
featureFrame <- featureFrame[!featureFrame$Labornummer%in%c(57341, 57345, 
                                                            57349, 57350, 57352),]
featureFrame <- merge(featureFrame,SI,by.x="Labornummer",by.y="Nr")

##### STANDARDIZED CONDITIONS!! Therefore use only one spectrum per Labornummer
featureFrame <- featureFrame[!duplicated(featureFrame$Labornummer),]
featureFrame <- featureFrame[!is.na(featureFrame$Q10_exp_45)&!is.na(featureFrame$Basal_25_45_mg),]

set.seed(100)

folds <- CreateSpacetimeFolds(featureFrame, spacevar = "Labornummer", 
                              timevar = NA, k = 10)

rfFuncs$fit <- function (x, y, first, last, ...) {
  loadNamespace("randomForest")
  randomForest::randomForest(x, y, importance=T,...)
}

rtrl <- rfeControl(method="cv",functions=rfFuncs,rerank = TRUE,
                   index =folds$index,
                   indexOut =folds$indexOut,returnResamp = "all")
ctrl <- trainControl(method="cv",savePredictions = TRUE,verbose=TRUE)
ctrl2 <- trainControl(method="LOOCV",savePredictions = TRUE,verbose=TRUE,
                      returnResamp = "all")

predictors <- featureFrame[,c(4,6:1795)]
response1 <- featureFrame$Q10_exp_45
response2 <- featureFrame$Basal_25_45_mg
response3 <- featureFrame$Stability


cl <- makeCluster(detectCores()-5)
registerDoParallel(cl)
#####################
set.seed(100)
rfemodel_Q10 <- rfe(predictors,response1,method="rf",
                    trControl=ctrl,
                    tuneLength=10,
                    rfeControl = rtrl,
                    sizes = c(2:10,15,20,25,30,35,40,45,50,60,70,80,90,100,seq(150,500,25),
                              seq(600,ncol(predictors),50)))

save(rfemodel_Q10,file=paste0(modelpath,"rfemodel_SI_Q10.RData"))
optVars <- rfemodel_Q10$optVariables

set.seed(100)
model_Q10 <- train(predictors[,optVars],response1,method="rf",
                   trControl=ctrl2,importance=TRUE,
                   tuneLength=10)
################

save(model_Q10,file=paste0(modelpath,"rfemodel_SI_Q10_final.RData"))
rfemodel_Basal <- rfe(predictors,response2,method="rf",
                      trControl=ctrl,
                      tuneLength=10,
                      rfeControl = rtrl,
                      sizes = c(2:10,15,20,25,30,35,40,45,50,60,70,80,90,100,seq(150,500,25),
                                seq(600,ncol(predictors),50)))
save(rfemodel_Basal,file=paste0(modelpath,"rfemodel_SI_basal.RData"))

optVars <- rfemodel_Basal$optVariables

set.seed(100)
model_Basal <- train(predictors[,optVars],response2,method="rf",
                     trControl=ctrl2,importance=TRUE,
                     tuneLength=10)

save(model_Basal,file=paste0(modelpath,"model_SI_basal_final.RData"))
##############
set.seed(100)
rfemodel_stabil <- rfe(predictors,response3,method="rf",
                       trControl=ctrl,
                       tuneLength=10,
                       rfeControl = rtrl,
                       sizes = c(2:10,15,20,25,30,35,40,45,50,60,70,80,90,100,seq(150,500,25),
                                 seq(600,ncol(predictors),50)))

save(rfemodel_stabil,file=paste0(modelpath,"rfemodel_SI_stabil.RData"))
#optVars <- names(varsRfeCV(rfemodel_Q10,sderror = TRUE))
optVars <- rfemodel_stabil$optVariables
#optVars <- c("X1838","Land_use","X3998","X1672","X1840","X586")

#print(optVars)
set.seed(100)
model_stabil <- train(predictors[,optVars],response3,method="rf",
                      trControl=ctrl2,importance=TRUE,
                      tuneLength=10)
save(model_stabil,file=paste0(modelpath,"model_SI_stabil_final.RData"))

#########
stopCluster(cl)
