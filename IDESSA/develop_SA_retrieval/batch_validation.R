# This scripts starts all scripts for model validation
scriptpath <- "/home/hmeyer/magic/IDESSA/develop_SA_retrieval/"
setwd("scriptpath")
source("06a_evaluateModels.R")
source("06b_visualizeEval.R")
source("06c_evalAgg_overall.R")
source("07a_compareWithGPM.R")
source("07b_visualizeGPMComp.R")