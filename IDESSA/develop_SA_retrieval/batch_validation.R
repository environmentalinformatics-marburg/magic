# This scripts starts all scripts for model validation
scriptpath <- "/home/hmeyer/magic/IDESSA/develop_SA_retrieval/"
setwd("scriptpath")
source("06a_evaluateModels.R",echo=TRUE)
source("06b_visualizeEval.R",echo=TRUE)
source("06c_evalAgg_overall.R",echo=TRUE)
source("07a_compareWithGPM.R",echo=TRUE)
source("07b_visualizeGPMComp.R",echo=TRUE)