# This script prepares different case studies (currently Tair Antarctica, 
#Soil moisture cookfarm and soil moisture exploratories) and controls the
#comparison study of different validation and feature selection algorithms.

rm(list=ls())
library(caret)
library(Rsenal)

################################################################################
#user defined settings
################################################################################
datapath <- "/media/memory01/data/hmeyer/Overfitting/"
scriptpath <- "/home/hmeyer/magic/AnalyzeOverfitting/" #contains the modelling function
outpath <- paste0(datapath,"/results2/")
sampsize_Tair <- 1 # 1=use entire dataset
sampsize_Soil <- 1
sampsize_Expl <- 1
tuneLength <- 10
withinSD <- FALSE #see ?ffs
doParallel <- TRUE
caseStudy <- c("Expl")#"cookfarm,"Tair",Expl
algorithms <- c("rf")
### set individual models
featureSelect <- c("noSelection","ffs","rfe")#"noSelection","ffs","rfe"
validation <- c("llocv","ltocv","lltocv") #"cv","llocv","ltocv","lstocv"
additionals <- expand.grid("caseStudy"=caseStudy,"algorithms"=algorithms,
                           "validation"="cv","featureSelect"="noSelection")
individualModels <- expand.grid("caseStudy"=caseStudy,
                                "algorithms"=algorithms,
                                "validation"=validation,
                                "featureSelect"=featureSelect,
                                stringsAsFactors=FALSE)
individualModels <- rbind(additionals,individualModels)
##remove those that are not needed
individualModels <- individualModels[!(
  individualModels$featureSelect%in%c("rfe","ffs")&
    individualModels$validation%in%c("lltocv","ltocv")),]
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
    response <- "VW"
    predictors<-c("DEM","TWI","NDRE.M","NDRE.Sd","Bt","BLD","PHI","Precip_cum",
                  "MaxT_wrcc","MinT_wrcc","cdayt","Crop")
    spacevar <- "SOURCEID" #for LLOCV
    timevar <- "Date" # FOR TOCV
  }
  ########################### TAIR ANTARCTICA ##################################
  if (individualModels$caseStudy[i]=="Tair"){
    sampsize <- sampsize_Tair
    dataset <- get(load("Tair.RData"))
    dataset <- dataset[complete.cases(dataset),]
    dataset$time <- as.numeric(dataset$time)
    dataset$month <- as.numeric(dataset$month)
    response <- "statdat"
    predictors <- c("LST",
                    "doy",
                    "season",
                    "time",
                    "month",
                    "sensor",
                    "dem",
                    "slope",
                    "aspect",
                    "skyview",
                    "ice")
    spacevar <- "station"
    timevar <- "doy"
    nfolds_time <- 10
    nfolds_space <- 10
    nfolds_spacetime <- 10
  }
  ########################### EXPLORATORIES ####################################
  if (individualModels$caseStudy[i]=="Expl"){
    sampsize <- sampsize_Expl
    dataset <- get(load("dataset_exploratories.RData"))
    dataset <- dataset[complete.cases(dataset),]
    dataset <- dataset[dataset$Exploratorium=="ALB",]
    dataset$year <- as.factor(dataset$year)
    dataset <- dataset[dataset$year=="2013",]
    dataset$date <- as.character(dataset$date)
    names(dataset)[which(names(dataset)=="date")] <- "dts"
    dataset$month <- as.numeric(dataset$month)
     dataset$LUI <- as.numeric(dataset$LUI)
    response <- "SM_10"
    predictors <- c("Exploratorium",
                  "P_RT_NRT","Ta_200","Ts_10","elevation","slope","aspect",
                  "bulk","Clay","Fine_Silt","Coarse_Silt","Fine_Sand",
                  "Medium_Sand","Coarse_Sand",
                  "month","doy","LUI","Precip_cum","rw","hw")
    spacevar <- "plotID"
    timevar <- "dts"
    nfolds_time <- 10
    nfolds_space <- 10
    nfolds_spacetime <- 10
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
                        nfolds_space=nfolds_space,
                        nfolds_time=nfolds_time,tuneLength=tuneLength,
                        seed=10)
  print(i)
}