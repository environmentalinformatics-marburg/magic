##################################################################################################################
#
#                              MACHINE LEARNING FOR RAINFALL - CONTROL SCIPT
#   Author: Hanna Meyer
#   Date: 2.5.2014
#
#   This script contains the control of several R scripts for model training, prediction and visualization
#   currently only for classification
##################################################################################################################
rm(list=ls())
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
#                                   1. User adjustment section
##################################################################################################################
##################################################################################################################
##################################################################################################################
#                                    General adjustments
##################################################################################################################
#choose where to work (currently "hanna" and "ui183" are supported. New profiles have to be created in the "datapath" section)
profil="hanna"
doParallel=TRUE
useSeeds=TRUE
shortTest=TRUE#if TRUE then learning parameters and data set are set automatically for quick test of the system
##################################################################################################################
#                                          Data adjustments
##################################################################################################################
inputTable="rfInput_vp03_day_om.dat"
response<-"RInfo" #field name of the response variable
dateField="chDate" #field name of the date+time variable. identifier for scenes. 
                   #important to split the data. must be unique per scende
centerscale=TRUE#center and scale the predictor variables?
##################################################################################################################
#                                Data splitting adjustments
##################################################################################################################
SizeOfTrainingSet=0.25 #how many percent of scenes will be used for training?
cvNumber=10 # number of cross validation samples (cVNumber fold CV)
balance=FALSE #use balanced response classes?
balanceFactor=c(1) #if balance==TRUE: how to balance?number of pixels in max class = 
#          number of pixels in min class * balance factor
sampsize=5000 #how many pixels from the training data should actually be used for training? If
#to high then the maximum number will be considered
##################################################################################################################
#                                      Choose Predictors (must be included in "inputTable")
##################################################################################################################
predictorVariables=c("SZen",
                     "B01","B02","B03","B04","B05","B06","B07","B08","B09","B10","B11",
                     #"Tau",
                     #"Aef","CWP",
                     "B0103","B0409","B0406","B0709","B0910","B0509","B0610"
)
##################################################################################################################
#                                      Learning adjustments
##################################################################################################################
model=c("rf","nnet","svm") # supported: rf,nnet,svm.
tuneThreshold=TRUE #should the optimal probability threshold be tuned?
thresholds=seq(0.0, 1.0, 0.02) #if tuneThreshold==TRUE: Which thresholds?
##### RF Settings:
ntree=500
rf_mtry=c(2:length(predictorVariables))
##### NNET Settings:
nnet_decay=c(0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.075, 0.1)
nnet_size=c(2:length(predictorVariables))
##### SVM Settings:
svm_sigma="sigest(as.matrix(predictors))[2]" #analyticaly solved with sigest. vector is also allowed
svm_cost=c(0.25, 0.50, 1.00, 2.00, 4.00, 8.00, 16.00, 32.00, 46.00, 128.00)
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
#                                      2. Organization (no adjustments required)
##################################################################################################################
##################################################################################################################
##################################################################################################################
#                                   Initialize "shortTest"
##################################################################################################################
if(shortTest){
  inputTable="rfInput_vp03_day_om.dat"
  sampsize=100
  thresholds=seq(0.0, 1.0, 0.2)
  rf_mtry=c(2:5)
  ##### NNET Settings:
  nnet_decay=c(0.005, 0.01, 0.05)
  nnet_size=c(2:5)
  ##### SVM Settings:
  svm_sigma="sigest(as.matrix(predictors))[2]" #analyticaly solved with sigest. vector is also allowed
  svm_cost=c(0.25, 2.00, 4.00, 32.00)
}
##################################################################################################################
#                                    Set data paths according to "profil"
##################################################################################################################
if (profil=="hanna"){
  datapath="/media/hanna/ubt_kdata_0005/pub_rapidminer/input"
  resultpath<-"/media/hanna/ubt_kdata_0005/pub_rapidminer/Results"
  scriptpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/subscripts/"
  additionalFunctionPath="/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/functions"
}
if(profil=="ui183"){
  datapath="/media/memory18201/casestudies/ML_comp/Input_Data"
  resultpath<-"/media/memory18201/casestudies/ML_comp/Results"
  scriptpath="/home/hmeyer/ML_comp_scripts/subscripts"
  additionalFunctionPath="/home/hmeyer/ML_comp_scripts/functions"
}
setwd(scriptpath)
##################################################################################################################
#                                          Load functions
##################################################################################################################
library(caret)
library(kernlab)
for (i in list.files(additionalFunctionPath)){
  source(paste(additionalFunctionPath,"/",i,sep=""))
}
##################################################################################################################
#                                          Organise parallel processing
##################################################################################################################
if (doParallel){
  library(doParallel)
  cl <- makeCluster(detectCores())
  registerDoParallel(cl)
}
##################################################################################################################
#                                          Organise balancing
##################################################################################################################
#if several balancing factors are tried, save models in seperate folders:
tmpresultpath=resultpath
for (factor in balanceFactor){
  if (length(balanceFactor)>1){
    resultpath=tmpresultpath
    dir.create(paste(resultpath,"/balanceFactor_",factor,sep=""))
    resultpath=paste(resultpath,"/balanceFactor_",factor,sep="")
  }
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
#                                      3. Run subscripts (no adjustments required)
##################################################################################################################
##################################################################################################################  
  
##################################################################################################################
#                                           Preprocessing
##################################################################################################################
  source("Preprocessing.R",echo=TRUE)
  #source("VisualizationOfInput.R") #(first run preprocessing.R)
##################################################################################################################
#                                          Learning
##################################################################################################################
  source("RunClassificationModels.R",echo=TRUE)
  source("VisualizationOfModelOutput_Tuning.R",echo=TRUE)
##################################################################################################################
#                             Prediction and Validation
##################################################################################################################

  source("PredictAndValidateClassificationModel.R",echo=TRUE)
  source("VisualizationOfModelPrediction.R",echo=TRUE)
  source("SpatialModelResults.R",echo=TRUE)
##################################################################################################################
##################################################################################################################
#                             Stop cluster and clear workspace
##################################################################################################################
}
if (doParallel){
  stopCluster(cl)
}
rm(list=ls())
