
rm(list=ls())
library(caret)
library(Rsenal)
sampsize_Tair <- 1
sampsize_Soil <- 1
doParallel <- TRUE
caseStudy <- c("Tair")#"Soil,"Tair"
algorithms <- c("rf")
featureSelect <- c("noSelection","ffs","rfe")#"noSelection","ffs","rfe"
validation <- c("llocv","ltocv","lltocv") #"cv","llocv","ltocv","lstocv"
additionals <- c("Tair","rf","cv","noSelection")

individualModels <- expand.grid("caseStudy"=caseStudy,
                                "algorithms"=algorithms,
                                "validation"=validation,
                                "featureSelect"=featureSelect,
                                stringsAsFactors=FALSE)
individualModels <- rbind(additionals,individualModels)

datapath <- "/media/memory01/data/hmeyer/Overfitting/"
#datapath <- "/media/hanna/data/Overfitting/"
scriptpath <- "/home/hmeyer/magic/AnalyzeOverfitting/"

outpath <- paste0(datapath,"/results/")
source(paste0(scriptpath,"/trainModels.R"))
setwd(datapath)



for (i in 1:nrow(individualModels)){
  if (individualModels$caseStudy[i]=="Soil"){
    sampsize <- sampsize_Soil
    dataset <- get(load("Soil.RData"))
    dataset <- dataset[complete.cases(dataset),]
    response <- "VW"
    predictors<-c("DEM","TWI","NDRE.M","NDRE.Sd","Bt","BLD","PHI","Precip_cum",
                  "MaxT_wrcc","MinT_wrcc","cdayt","Crop")
    spacevar <- "SOURCEID"
    timevar <- "Date"
  }
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

  model <- trainModels (dataset,spacevar=spacevar,timevar=timevar,
                        sampsize=sampsize,
                        caseStudy=individualModels$caseStudy[i],
                        validation=individualModels$validation[i],
                        featureSelect=individualModels$featureSelect[i],
                        predictors=predictors,response=response,
                        algorithm=individualModels$algorithms[i],
                        outpath=outpath,doParallel=TRUE,
                        calculate_random_fold_model=TRUE,
                        nfolds_spacetime=nfolds_spacetime,
                        nfolds_space=nfolds_space,
                        nfolds_time=nfolds_time)
  print(i)
}


