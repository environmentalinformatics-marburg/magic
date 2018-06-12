rm(list=ls())
library(caret)
library(corrplot)
library(viridis)
library(Rsenal)
library(vioplot)

mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/forPaper/"
datapath <- paste0(mainpath,"/modeldat")
vispath <- paste0(mainpath,"/visualizations")

testdata <- get(load(paste0(datapath,"/testdata.RData")))
model <- get(load(paste0(datapath,"/model_final.RData")))

pred_cv <- model$pred[model$pred$mtry==model$bestTune$mtry,]
pred_ext <- predict(model,testdat)
boxplot(abs(pred_cv$pred-pred_cv$obs),abs(pred_ext-testdat$Tair),notch=T)

regressionStats(pred_cv$pred,pred_cv$obs)
regressionStats(pred_ext,testdat$Tair)
