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
#choose where to work (currently "hanna" and "ui183" are supported. 
#New profiles have to be created in the "datapath" section)
profil="hanna"
doParallel=TRUE
useSeeds=TRUE
shortTest=TRUE#if TRUE then learning parameters and data set are set automatically for quick test of the system
##################################################################################################################
#                                          Data adjustments
##################################################################################################################
inputTable="rfInput_vp03_day_as.dat"
response<-"Rain" #field name of the response variable. "Rain" or "RInfo"
dateField="chDate" #field name of the date+time variable. identifier for scenes. 
#important to split the data. must be unique per scene. format: yyyymmddhhmm
centerscale=TRUE#center and scale the predictor variables?
transformResponse=FALSE#Transform Rain rates?
rainAreaFromRadar=FALSE#If false all cloudy pixels are considered as potentially raining. If true only pixels
#where radar says it rains are considered for rain rate assignment
##################################################################################################################
#                                Data splitting adjustments
##################################################################################################################
SizeOfTrainingSet=0.33 #how many percent of scenes will be used for training?
cvNumber=10 # number of cross validation samples (cVNumber fold CV)
sampsize=0.05 #how many percent of training scene pixels from the training data should actually be used for training? 
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
adaptiveResampling=FALSE #use adaptive crosss validation?

###only for classification:
tuneThreshold=TRUE #should the optimal probability threshold be tuned?  
thresholds=c(seq(0.0, 0.20, 0.01),seq(0.30,1,0.1)) #if tuneThreshold==TRUE: Which thresholds?


##### RF Settings:
ntree=500
rf_mtry=c(2:length(predictorVariables))
##### NNET Settings:
nnet_decay=seq(0.01,0.1,0.02)
nnet_size=seq(2,length(predictorVariables),2)
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
type="classification"
if (response=="Rain"){
  type="regression" #classification or regression?
}
if (type=="regression"){
  tuneThreshold=FALSE
}
##################################################################################################################
#                                   Initialize "shortTest"
##################################################################################################################
if(shortTest){
  inputTable="rfInput_vp03_day_om.dat"
  sampsize=0.002
  if (tuneThreshold) thresholds=seq(0.0, 1.0, 0.2)
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
  resultpath<-paste("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/",response, "_", substr(inputTable,1,nchar(inputTable)-4),sep="")
  scriptpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/subscripts/"
  additionalFunctionPath="/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/functions"
}
if(profil=="ui183"){
  datapath="/media/memory18201/casestudies/ML_comp/Input_Data"
  resultpath<-paste("/media/memory18201/casestudies/ML_comp/Results/",response, "_", substr(inputTable,1,nchar(inputTable)-4),sep="")
  scriptpath="/home/hmeyer/ML_comp_scripts/subscripts"
  additionalFunctionPath="/home/hmeyer/ML_comp_scripts/functions"
}
setwd(scriptpath)
dir.create(resultpath)
##################################################################################################################
#                                          Load functions and packages
##################################################################################################################
usedPackages=c("caret","kernlab","ROCR","raster","latticeExtra","fields","reshape2",
               "grid","maps","mapdata","sp","rgdal","RColorBrewer","lattice","doParallel")



lapply(usedPackages, library, character.only=T)
for (i in list.files(additionalFunctionPath)){
  source(paste(additionalFunctionPath,"/",i,sep=""))
}
##################################################################################################################
#                                          Organise parallel processing
##################################################################################################################
if (doParallel){
  cl <- makeCluster(detectCores())
  registerDoParallel(cl)
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
##################################################################################################################
#                                          Learning
##################################################################################################################
source("RunModels.R",echo=TRUE)
source("VisualizationOfModelOutput_Tuning.R",echo=TRUE)
##################################################################################################################
#                             Prediction and Validation
##################################################################################################################
source("PredictModels.R",echo=TRUE)
if (type=="classification") source("ROC_comp.R",echo=TRUE)
if (type=="regression") source("RMSE_comp.R",echo=TRUE)
if (response=="RInfo") source("SpatialRInfoResults.R",echo=TRUE)
if (response=="Rain") source("SpatialRainResults.R",echo=TRUE)
##################################################################################################################
##################################################################################################################
#                             Stop cluster and clear workspace
##################################################################################################################

if (doParallel){
  stopCluster(cl)
}
rm(list=ls())
gc()
