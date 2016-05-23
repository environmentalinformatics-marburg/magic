rm(list=ls())
library(caret)
library(Rsenal)
sampsize=0.01
doParallel=FALSE
caseStudy <- c("Soil","Tair"
              #,"Rainfall"
              )
algorithms <- c("cubist","rf","gbm")
validation <- c("cv","losocv")
featureSelect <- c("noSelection","rfe","ffs","bss")

individualModels <- expand.grid("caseStudy"=caseStudy,
                                "algorithms"=algorithms,
                                "validation"=validation,
                                "featureSelect"=featureSelect)

#datapath <- "/media/memory01/casestudies/hmeyer/Overfitting/"
datapath <- "/media/hanna/data/Overfitting/"
scriptpath <- "/home/hmeyer/hmeyer/Overfitting/"

outpath <- paste0(datapath,"/results/")
source(paste0(scriptpath,"/trainModels.R"))
setwd(datapath)



for (i in 1:nrow(individualModels)){
  if (individualModels$caseStudy[i]=="Soil"){
    dataset <- get(load("Soil.RData"))
    dataset <- dataset[complete.cases(dataset),]
    response <- "VW"
    predictors<-c("DEM","TWI","NDRE.M","NDRE.Sd","Bt","BLD","PHI","Precip_cum",
                    "MaxT_wrcc","MinT_wrcc","cdayt","Crop")
    resampleVar <- "SOURCEID"
  }
  if (individualModels$caseStudy[i]=="Tair"){
    dataset <- get(load("Tair.RData"))
    dataset <- dataset[complete.cases(dataset),]
    response <- "statdat"
    predictors<-c("LST","doy","season","time","month","sensor","dem","slope",
                  "aspect","skyview","ice")
    resampleVar <- "station"
  }
  
  model <- trainModels (dataset,resampleVar=resampleVar,sampsize=sampsize,
                           caseStudy=individualModels$caseStudy[i],
                        validation=individualModels$validation[i],
                        featureSelect=individualModels$featureSelect[i],
                           predictors=predictors,response=response,
                        algorithm=individualModels$algorithms[i],
                        outpath=outpath,doParallel=TRUE)
  print(i)
}
#output: recorded time, station based perf, overall perf

