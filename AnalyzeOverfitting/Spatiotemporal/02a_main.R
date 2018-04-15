# This script prepares different case studies (currently Tair Antarctica, 
#Soil moisture cookfarm and soil moisture exploratories) and controls the
#comparison study of different validation and feature selection algorithms.

rm(list=ls())
library(caret)
library(Rsenal)

################################################################################
#user defined settings
################################################################################
#paths:
datapath <- "/media/memory01/data/hmeyer/Overfitting/"
scriptpath <- "/home/hmeyer/magic/AnalyzeOverfitting/" #contains the modelling 
#                                                   function "02b_trainModels.R"
outpath <- paste0(datapath,"/results_Tair_final/")
#sample sizes. 1= entire dataset and is recommended:
sampsize_Tair <- 1
sampsize_Soil <- 1
sampsize_Expl <- 1
#tune and train settings:
seed <- 111
tuneLength <- NA
tuneGrid <- expand.grid(mtry = 2) # only use one mtry value if already shown 
#                                   that this is the optimal one
withinSD <- FALSE #see ?ffs
doParallel <- TRUE
caseStudy <- c("Tair")#"cookfarm,"Tair"
algorithms <- c("rf") #currently only tested with rf
nfolds_time <- 10 # number of folds for LTOCV
nfolds_space <- 10 # number of folds for LLOCV
nfolds_spacetime <- 10 # number of folds for LLTOCV
metric="RMSE"
# define individual models:
featureSelect <- c("noSelection","ffs","rfe")#"noSelection","ffs","rfe"
validation <- c("llocv","ltocv","lltocv") #"cv","llocv","ltocv","lstocv"
additionals <- expand.grid("caseStudy"=caseStudy,"algorithms"=algorithms,
                           "validation"="cv","featureSelect"=c("noSelection","ffs","rfe"))
individualModels <- expand.grid("caseStudy"=caseStudy,
                                "algorithms"=algorithms,
                                "validation"=validation,
                                "featureSelect"=featureSelect,
                                stringsAsFactors=FALSE)
individualModels <- rbind(additionals,individualModels)

################################################################################
#set response and predictors for every dataset
################################################################################
source(paste0(scriptpath,"/02b_trainModels.R"))
setwd(datapath)
for (i in 1:nrow(individualModels)){
  ########################### COOKFARM #########################################
  if (individualModels$caseStudy[i]=="cookfarm"){
    sampsize <- sampsize_Soil
    dataset <- get(load("Soil.RData"))
    dataset <- dataset[complete.cases(dataset),]
    dataset <- dataset[dataset$altitude==-0.3,]
    dataset$year <- factor(as.character(substr(dataset$Date,1,4)))
    dataset$yearmonth <- factor(as.character(substr(dataset$Date,1,7)))
    dataset <- dataset[substr(dataset$Date,1,4)%in%c("2011","2012","2013"),]
    response <- "VW"
    predictors <- c("DEM","TWI","NDRE.M","NDRE.Sd","Bt","BLD","PHI","Precip_cum",
                  "MaxT_wrcc","MinT_wrcc","cdayt","Crop")
    spacevar <- "SOURCEID" #for LLOCV
    timevar <- "yearmonth" # for TOCV
  }
  ########################### TAIR ANTARCTICA ##################################
  if (individualModels$caseStudy[i]=="Tair"){
    sampsize <- sampsize_Tair
    dataset <- get(load("Tair.RData"))
    dataset <- dataset[complete.cases(dataset),]
    dataset$time <- as.numeric(dataset$time)
    dataset$month <- as.numeric(dataset$month)
    response <- "statdat"
    predictors <- c("LST","season","time","month","sensor","dem","slope",
                    "aspect","skyview","ice")
    spacevar <- "station"
    timevar <- "doy"
  }
  ########################### EXPLORATORIES ####################################
  if (individualModels$caseStudy[i]=="Expl"){
    sampsize <- sampsize_Expl
    dataset <- get(load("dataset_exploratories.RData"))
    dataset <- dataset[complete.cases(dataset),]
#    dataset <- dataset[dataset$Exploratorium=="ALB",]
    dataset$year <- as.factor(dataset$year)
    dataset <- dataset[dataset$year%in%c("2013"),]
    dataset$date <- as.character(dataset$date)
    names(dataset)[which(names(dataset)=="date")] <- "dts"
    dataset$month <- as.numeric(dataset$month)
    dataset$LUI <- as.numeric(dataset$LUI)
    response <- "SM_10"
    predictors <- c(
                  "P_RT_NRT","Ta_200","Exploratorium","elevation","slope",
                  "aspect","bulk","Clay","Fine_Silt","Coarse_Silt","Fine_Sand",
                  "Medium_Sand","Coarse_Sand","SWDR_300","PrecDeriv","month",
                  "doy","LUI","Precip_cum","evaporation","Ts_10")
    spacevar <- "plotID"
    timevar <- "dts"
  }
  ##############################################################################
  #Run modelling procedure for the respective individual model settings
  ##############################################################################
  model <- trainModels (dataset,spacevar=spacevar,timevar=timevar,
                        sampsize=sampsize,
                        caseStudy=individualModels$caseStudy[i],
                        validation=individualModels$validation[i],
                        featureSelect=individualModels$featureSelect[i],
                        predictors=predictors,response=response,
                        algorithm=individualModels$algorithms[i],
                        outpath=outpath,doParallel=doParallel,
                        calculate_random_fold_model=TRUE,
                        withinSD = withinSD,
                        nfolds_spacetime=nfolds_spacetime,
                        nfolds_space=nfolds_space,metric=metric,
                        nfolds_time=nfolds_time,tuneLength=tuneLength,
                        tuneGrid=tuneGrid,
                        seed=seed)
  print(i)
}