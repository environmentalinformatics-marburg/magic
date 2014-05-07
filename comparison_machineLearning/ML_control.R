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
#sink(paste(resultpath,"/logfile.txt",sep=""))
##################################################################################################################
#                                       load packages and functions
##################################################################################################################
library(caret)
library(kernlab)
source(paste(additionalFunctionPath,"/balancing.R",sep="")) #balance function
source(paste(additionalFunctionPath,"/splitData.R",sep="")) #splitData function
source(paste(additionalFunctionPath,"/rocFromTab.R",sep="")) #ROC function

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
response<-"RInfo" #field name of the response variable
dateField="chDate" #field name of the date+time variable. identifier for scenes. 
                   #important to split the data. must be unique per scende
##################################################################################################################
#                                Data splitting adjustments
##################################################################################################################
SizeOfTrainingSet=0.50 #how many percent of scenes will be used for training
cvNumber=10 # number of cross validation samples (cVNumber fold CV)
balance=TRUE #consider balanced response classes?
centerscale=TRUE#center and scale the predictor variables?
sampsize=500 #how many pixels from the training data should actually be used for training? If
#to high (e.g after rebalancing) then the maximum number will be considered
useSeeds=FALSE
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
model=c("rf","nnet","svm") # supported: rv,mlp,nnet,svm
##### RF Settings
ntree=1000
##### MLP Settings
##### NNET Setting
##### SVM Settings

##################################################################################################################
##################################################################################################################
#                                       3.  RUN SUBSCRIPTS
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
if (doParallel){
  stopCluster(cl)
}
#unlink("logfile.txt",append=TRUE, type="message")
rm(list=ls())