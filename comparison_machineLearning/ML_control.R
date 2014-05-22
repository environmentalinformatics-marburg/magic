##################################################################################################################
##################################################################################################################
#                              MACHINE LEARNING FOR RAINFALL - CONTROL SCIPT
#Author: Hanna Meyer
#Date: 2.5.2014

#This script contains the control of several R scripts for model training, prediction and visualization
#currently only for classification
##################################################################################################################
##################################################################################################################

doParallel=TRUE
##################################################################################################################
##################################################################################################################
#                                    
##################################################################################################################
##################################################################################################################
###datapaths
datapath="/media/hanna/ubt_kdata_0005/pub_rapidminer/input"
resultpath<-"/media/hanna/ubt_kdata_0005/pub_rapidminer/Results"
scriptpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/subscripts/"
additionalFunctionPath="/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/functions"
setwd(scriptpath)
##################################################################################################################
#                                       load packages and functions
##################################################################################################################
library(caret)
library(kernlab)
source(paste(additionalFunctionPath,"/balancing.R",sep="")) #balance function
source(paste(additionalFunctionPath,"/splitData.R",sep="")) #splitData function
source(paste(additionalFunctionPath,"/rocFromTab.R",sep="")) #ROC function
source(paste(additionalFunctionPath,"/rf_thres.R",sep="")) #RF function with threshold as tuning param
source(paste(additionalFunctionPath,"/mlp_thres.R",sep="")) #MLP function with threshold as tuning param
source(paste(additionalFunctionPath,"/nnet_thres.R",sep="")) #NNET function with threshold as tuning param
source(paste(additionalFunctionPath,"/svm_thres.R",sep="")) #SVM function with threshold as tuning param
source(paste(additionalFunctionPath,"/fourStats.R",sep="")) #fourStats funtion for summary function
source(paste(additionalFunctionPath,"/cutoffplot.R",sep="")) #plot cutoff levels


if (doParallel){
  library(doParallel)
  cl <- makeCluster(detectCores())
  registerDoParallel(cl)
}


##################################################################################################################
##################################################################################################################
#                                    2. ADJUST PARAMETRS 
##################################################################################################################
##################################################################################################################

##################################################################################################################
#                                          Data
##################################################################################################################


inputTable="rfInput_vp03_day_om.dat"
#inputTable="sampleData.csv"
response<-"RInfo" #field name of the response variable
dateField="chDate" #field name of the date+time variable. identifier for scenes. 
                   #important to split the data. must be unique per scende
##################################################################################################################
#                                Data splitting adjustments
##################################################################################################################
SizeOfTrainingSet=0.50 #how many percent of scenes will be used for training
cvNumber=10 # number of cross validation samples (cVNumber fold CV)
balance=FALSE #consider balanced response classes?
balanceFactor=c(1) # number of pixels in max class = 
#                                                                   number of pixels in min class * balance factor
centerscale=TRUE#center and scale the predictor variables?
sampsize=100 #how many pixels from the training data should actually be used for training? If
#to high (e.g after rebalancing) then the maximum number will be considered
useSeeds=TRUE
tuneThreshold=TRUE
##################################################################################################################
#                                            Predictors
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
model=c("rf","nnet","svm") # supported: rf,mlp,nnet,svm. MLP only if tuneThreshold=FALSE
##### RF Settings
ntree=80

##### MLP Settings

##### NNET Setting

##### SVM Settings

##################################################################################################################
##################################################################################################################
#                                       3.  RUN SUBSCRIPTS
##################################################################################################################
##################################################################################################################
#if several balancing factors are tried, save models ins eperate folders
tmpresultpath=resultpath
for (factor in balanceFactor){
  if (length(balanceFactor)>1){
    resultpath=tmpresultpath
    dir.create(paste(resultpath,"/balanceFactor_",factor,sep=""))
    resultpath=paste(resultpath,"/balanceFactor_",factor,sep="")
  }
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

}
  if (doParallel){
    stopCluster(cl)
  }
rm(list=ls())
