####test runtime
inputTable="rfInput_vp03_day_as.dat"
response<-"Rain" #field name of the response variable. "Rain" or "RInfo"
dateField="chDate" #field name of the date+time variable. identifier for scenes. 
#important to split the data. must be unique per scene. format: yyyymmddhhmm
centerscale=TRUE#center and scale the predictor variables?
transformResponse=FALSE#Transform Rain rates?
rainAreaFromRadar=TRUE#If false all cloudy pixels are considered as potentially raining. If true only pixels
#where radar says it rains are considered for rain rate assignment
##################################################################################################################
#                                Data splitting adjustments
##################################################################################################################
SizeOfTrainingSet=0.33 #how many percent of scenes will be used for training?
cvNumber=10 # number of cross validation samples (cVNumber fold CV)
sampsize=0.05 #how many percent of training scene pixels from the training data should actually be used for training? 
predictorVariables=c("SZen",
                     "B01","B02","B03","B04","B05","B06","B07","B08","B09","B10","B11",
                     #"Tau",
                     #"Aef","CWP",
                     "B0103","B0409","B0406","B0709","B0910","B0509","B0610"
)
##################################################################################################################
#                                      Learning adjustments
##################################################################################################################
model=c("rf","nnet","svm","avNNet") # supported: rf,nnet,svm.
adaptiveResampling=FALSE #use adaptive crosss validation?

###only for classification:
tuneThreshold=TRUE #should the optimal probability threshold be tuned?  


##### RF Settings:
ntree=500
rf_mtry=4
rf_threshold = 0.2
##### NNET Settings:
nnet_decay=0.09
nnet_size=18
nnet_threshold = 0.19. 

##### SVM Settings:
svm_sigma="sigest(as.matrix(predictors))[2]" #analyticaly solved with sigest. vector is also allowed
svm_cost=128
svm_threshold = 0.11. 
##################################################################################################################

datapath="/media/memory18201/casestudies/ML_comp/Input_Data"
resultpath<-paste("/media/memory18201/casestudies/ML_comp/Results/testRuntime/",response, "_", substr(inputTable,1,nchar(inputTable)-4),sep="")
scriptpath="/home/hmeyer/ML_comp_scripts/subscripts"
additionalFunctionPath="/home/hmeyer/ML_comp_scripts/functions"

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

type="classification"
if (response=="Rain"){
  type="regression" #classification or regression?
}
if (type=="regression"){
  tuneThreshold=FALSE
}

##################################################################################################################
#                                          Organise parallel processing
##################################################################################################################
if (doParallel){
  cl <- makeCluster(detectCores())
  registerDoParallel(cl)
}
##################
source("Preprocessing.R",echo=TRUE)
#################
summaryFunction = "fourStats"
if (type=="regression")summaryFunction ="defaultSummary"
classProbs=FALSE
if (type=="classification") classProbs=TRUE
ctrl <- trainControl(index=cvSplits,
                     method="cv",
                     summaryFunction = eval(parse(text=summaryFunction)),
                     classProbs = classProbs)

if (type=="classification"){
  metric="Dist" #wenn nicht _thres dann "ROC
  maximize = FALSE #when dist is used, then min value is important
}


if (type=="regression"){
  metric="RMSE"
  maximize=FALSE
  #metric="Rsquared"
  #maximize=TRUE
}


###############
if (tuneThreshold) {
  method = rf_thres
  tuneGridRF=expand.grid(.mtry = rf_mtry,.threshold=rf_threshold)
}
if (!tuneThreshold) {
  method = "rf"
  tuneGridRF=expand.grid(.mtry =rf_mtry)
}

ptm <- proc.time()
if(useSeeds) set.seed(20)
fit_rf <- train (predictors, 
                 class, 
                 method = method, 
                 trControl = ctrl,
                 tuneGrid=tuneGridRF,
                 ntree=ntree,
                 metric=metric,
                 maximize = maximize #when dist is used, then min value is important
)
ptm <- proc.time() - ptm
capture.output(paste("Computation time: ",round(ptm[3],2)," sec"), cat("predictor Variables: "),
               predictorVariables,print(fit_rf),file=paste(resultpath,"/fit_rf.txt",sep=""))
#######################
linout=FALSE
if (type=="regression") linout = TRUE

if (any(model=="nnet")){
  
  if (tuneThreshold) {
    method = nnet_thres
    tuneGrid_NNet <- expand.grid(.size = nnet_size,
                                 .decay = nnet_decay,.threshold=nnet_threshold)
  }
  if (!tuneThreshold) {
    method = "nnet"
    tuneGrid_NNet <- expand.grid(.size = nnet_size,
                                 .decay = nnet_decay)
    
    ptm <- proc.time()
    if(useSeeds) set.seed(20)
    fit_rf <- train (predictors, 
                     class, 
                     method = method, 
                     trControl = ctrl,
                     tuneGrid=tuneGridRF,
                     ntree=ntree,
                     metric=metric,
                     maximize = maximize #when dist is used, then min value is important
    )
    ptm <- proc.time() - ptm
    capture.output(paste("Computation time: ",round(ptm[3],2)," sec"),cat("predictor Variables: "),
                   predictorVariables,print(fit_nnet),file=paste(resultpath,"/fit_nnet.txt",sep=""))
