################################################################################
# Control processing flow
################################################################################
#folder structure must be as following: working directory contains subfolders:
#TrainingData
#out
  #images
#PredictionImages
#Scripts
rm(list=ls())
################### USER SETTINGS ##############################################
#working_directory <- "G:/FinaleDaten_Suedafrika/"
working_directory <- "/home/hanna/Documents/Presentations/Google Images/FinaleDaten_Suedafrika/final"
allowParallel=FALSE
################################################################################

lib <- c("caret", "randomForest", "rgdal","Rsenal","raster", "cluster", 
         "satellite","RColorBrewer", "sp","maptools",
         "plotKML","rgeos","dismo","maps",
         #"MODIS",
         "gdistance", "RCurl","rgeos","gdalUtils","plyr")
sapply(lib, function(x) library(x, character.only = TRUE))


#Grunddaten <- paste0(working_directory,"Input/")
TrainingData <- paste0(working_directory,"/TrainingData/")
PredictionImages <- paste0(working_directory,"/PredictionImages/")
out <- paste0(working_directory,"/out/")

source(paste0(working_directory,"/scripts/Functions.R"))
source(paste0(working_directory,"/scripts/Create_TrainingData.R"))
source(paste0(working_directory,"/scripts/RandomForest_Model.R"))
source(paste0(working_directory,"/scripts/Validation_RF_Model.R"))
source(paste0(working_directory,"/scripts/Classification_Google.R"))
