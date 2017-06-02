# this script takes models tarined and validated with different cross validation
# and feature selection strategies and compares their performance
rm(list=ls())
library(reshape2)
library(latticeExtra)
library(Rsenal)
library(caret)
################################################################################
#USER ADJUSTMENTS
datapath <- "/media/hanna/data/Overfitting/"
casestudy <- "cookfarm" # Tair or Expl
################################################################################

outpath <- paste0(datapath,"/Results_",casestudy)
figurepath <- paste0(datapath,"/figures/")
setwd(outpath)
################################################################################
# Get individual models
################################################################################
models <- list.files(,pattern=paste0("model_rf_",casestudy))
models <- models[substr(models,1,3)!="TMP"]

#### # no feature selection
cv_noselect <-  get(load(models[grep("_cv_no",models)]))
llocv_noselect <- get(load(models[grep("_llocv_no",models)]))
ltocv_noselect <- get(load(models[grep("_ltocv_no",models)]))
lltocv_noselect <- get(load(models[grep("_lltocv_no",models)]))

noselection <- list(cv_noselect,llocv_noselect,
                    ltocv_noselect,lltocv_noselect)
names(noselection) <- c("cv_noselect","llocv_noselect",
                         "ltocv_noselect","lltocv_noselect")

#lltocv is the reference model
#aim is to improve the performance of these models.
#therefore rfe and ffs is tested:

#### # Recursive feature selection
lltocv_rfe <- get(load(models[grep("_lltocv_rfe",models)]))
lltocv_cv_rfe <- lltocv_rfe$random_kfold_cv


rfeselection <- list(lltocv_rfe,lltocv_cv_rfe)
names(rfeselection) <- c("lltocv_rfe","lltocv_cv_rfe")

#### # Forward feature selection
lltocv_ffs <- get(load(models[grep("_lltocv_ffs",models)]))
lltocv_cv_ffs <-  lltocv_ffs$random_kfold_cv


ffsselection <- list(lltocv_ffs,lltocv_cv_ffs)
names(ffsselection) <- c("lltocv_ffs","lltocv_cv_ffs")
################################################################################
### Get predictions and observed values for each resample
################################################################################

modelslist <- append(noselection,rfeselection)
modelslist <- append(modelslist,ffsselection)

modelspred <- modelslist
for (i in 1:length(modelslist)){
  modelspred[[i]] <- modelslist[[i]]$pred[modelslist[[i]]$pred$mtry==
                                             modelslist[[i]]$bestTune$mtry,]
}

################################################################################
### Calculate the absolute error for each data point 
################################################################################

results <-c()
for (i in 1:length(modelspred)){
  cv <- c(gsub("_.*$", "", names(modelspred)[i]),"cv")[lengths(
    regmatches(names(modelspred)[i], gregexpr("_", names(modelspred)[i])))]

    results <- rbind(results,
                   data.frame("Diff"=abs(modelspred[[i]]$pred-
                                           modelspred[[i]]$obs),
                                "VarSelect"= gsub('.*_', '', names(modelspred)[i]),
                              "cv"= cv,
                              "modelopt"= gsub("_.*$", "", names(modelspred)[i])))
}


results_melt <- melt(results)

################################################################################
### Visualize differences
################################################################################
results_melt_noselect <- results_melt[results_melt$VarSelect=="noselect",]

#define minmax for scaling without outliers
maxm <- -100
minm <- 100
for (i in unique(results_melt_noselect$cv)){
valmin <- boxplot(results_melt_noselect$value[results_melt_noselect$cv==i])$stats[c(1, 5), ][1]
valmax <- boxplot(results_melt_noselect$value[results_melt_noselect$cv==i])$stats[c(1, 5), ][2]
maxm <- max(maxm,valmax)
minm <- min(minm,valmin)
}

pdf(paste0(figurepath,casestudy,"_comp_noselection.pdf"),width=6,height=5)
boxplot(results_melt_noselect$value~
         results_melt_noselect$modelopt,outline=FALSE,
       notch=TRUE,ylab="cross-validated |pred-obs|",
       names=c("random-CV","LLO-CV","LTO-CV","LLTO-CV"),
       ylim=c(minm-minm*0.05,maxm+maxm*0.05),
       col="grey50")
dev.off()

####################### LLTOCV Comparison ###################################

results_melt_lltocv <- results_melt[results_melt$modelopt=="lltocv",]
no_lltocv <-  results_melt_lltocv$value[
  results_melt_lltocv$VarSelect=="noselect"&results_melt_lltocv$cv!="cv"]
no_lltocv_cv <- results_melt$value[results_melt$VarSelect=="noselect"&
                              results_melt$cv=="cv"&results_melt$modelopt=="cv"]

rfe_lltocv <- results_melt_lltocv$value[
  results_melt_lltocv$VarSelect=="rfe"&results_melt_lltocv$cv!="cv"]
rfe_cv <- results_melt_lltocv$value[
  results_melt_lltocv$VarSelect=="rfe"&results_melt_lltocv$cv=="cv"]
ffs_lltocv <- results_melt_lltocv$value[
  results_melt_lltocv$VarSelect=="ffs"&results_melt_lltocv$cv!="cv"]
ffs_cv <- results_melt_lltocv$value[
  results_melt_lltocv$VarSelect=="ffs"&results_melt_lltocv$cv=="cv"]


pdf(paste0(figurepath,casestudy,"_comp_lltoCV.pdf"),width=9,height=6) 
boxplot(no_lltocv_cv,no_lltocv,rfe_cv,rfe_lltocv,ffs_cv,ffs_lltocv,
        col=c("grey50","grey90"),notch=TRUE,
        #pch=20,cex=0,
        outline=FALSE,
        names=rep(c("random-CV","LLTO-CV"),3),
        at=c(1,2,3.5,4.5,6,7),ylab="cross-validated |pred-obs|")
mtext("No Selection", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.12, padj = 1,cex=1.2)
mtext("RFE", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.5, padj = 1,cex=1.2)
mtext("FFS", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.85, padj = 1,cex=1.2)
dev.off()

################################################################################
################# Regression Table #############################################
################################################################################
regstats <- c()
for (i in 1:length(modelspred)){
regstats <- rbind(regstats,regressionStats(modelspred[[i]]$obs,modelspred[[i]]$pred))
}
regstats <- round(regstats,2)
regstats$name <- names(modelspred)
write.csv(regstats[,-which(names(regstats)%in%c("ME.se","MAE.se","RMSE.se"))],
          paste0(figurepath,casestudy,"_regstatstab.csv"),row.names=FALSE)

################################################################################
################# Compare feature selection with 10-fold #######################
################################################################################

cv_noselect <-  get(load(models[grep("_cv_no",models)]))
rfe_cv <- get(load(models[grep("_cv_rfe",models)]))
ffs_cv <- get(load(models[grep("_cv_ffs",models)]))

modelslist <- list(cv_noselect,rfe_cv,ffs_cv)
names(modelslist)<- c("cv_noselect","cv_rfe","cv_ffs")


modelspred <- modelslist
for (i in 1:length(modelslist)){
  modelspred[[i]] <- modelslist[[i]]$pred[modelslist[[i]]$pred$mtry==
                                            modelslist[[i]]$results$mtry,]
}

results <-c()
for (i in 1:length(modelspred)){
  cv <- c(gsub("_.*$", "", names(modelspred)[i]),"cv")[lengths(
    regmatches(names(modelspred)[i], gregexpr("_", names(modelspred)[i])))]
  
  results <- rbind(results,
                   data.frame("Diff"=abs(modelspred[[i]]$pred-
                                           modelspred[[i]]$obs),
                              "VarSelect"= gsub('.*_', '', names(modelspred)[i]),
                              "cv"= cv,
                              "modelopt"= gsub("_.*$", "", names(modelspred)[i])))
}


results_melt <- melt(results)

maxm <- -100
minm <- 100
for (i in unique(results_melt$cv)){
  valmin <- boxplot(results_melt$value[results_melt$cv==i])$stats[c(1, 5), ][1]
  valmax <- boxplot(results_melt$value[results_melt$cv==i])$stats[c(1, 5), ][2]
  maxm <- max(maxm,valmax)
  minm <- min(minm,valmin)
}
if(any(unique(results_melt$VarSelect)!=c("noselect", "rfe","ffs"))){
  print("waring: factor levels dont match manual adjustments in plot")
}
pdf(paste0(figurepath,casestudy,"_comp_10fold_selections.pdf"),width=6,height=5)
boxplot(results_melt$value~
          results_melt$VarSelect,outline=FALSE,
        notch=TRUE,ylab="cross-validated |pred-obs|",ylim=c(minm-1,maxm+1),
        col="grey50",names=c("No Selection","RFE","FFS"))
dev.off()

################################################################################
################# plotVarImp ###################################################
################################################################################
pdf(paste0(figurepath,casestudy,"_varimp.pdf"),width=4,height=4)
plot(varImp(cv_noselect),col="black")
dev.off()

