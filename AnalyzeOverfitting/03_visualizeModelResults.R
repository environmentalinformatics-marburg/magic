# this script takes models tarined and validated with different cross validation
# and feature selection strategies and compares their performance
rm(list=ls())
library(reshape2)
library(latticeExtra)

#datapath <- "/media/memory01/data/hmeyer/Overfitting/"
datapath <- "/media/hanna/data/Overfitting/"
outpath <- paste0(datapath,"/results3/")
#outpath <- "/home/hanna/Documents/Projects/Overfitting/" #tmp
figurepath <- paste0(datapath,"/figures/")
setwd(outpath)

casestudy <- "Expl" # Tair or Expl
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
#llocv,ltocv and lltocv are reference models
#aim is to improve the performance of these models.
#therefore rfe and ffs is tested:

#### # Recursive feature selection
llocv_rfe <- get(load(models[grep("_llocv_rfe",models)]))
llocv_cv_rfe <- llocv_rfe$random_kfold_cv
#ltocv_rfe <- get(load(models[grep("_ltocv_rfe",models)]))
#ltocv_cv_rfe <- ltocv_rfe$random_kfold_cv
#lltocv_rfe <- get(load(models[grep("_lltocv_rfe",models)]))
#lltocv_cv_rfe <- lltocv_rfe$random_kfold_cv

rfeselection <- list(llocv_rfe,llocv_cv_rfe)
names(rfeselection) <- c("llocv_rfe","llocv_cv_rfe")

#### # Forward feature selection
lltocv_ffs <- get(load(models[grep("_lltocv_ffs",models)]))
lltocv_cv_ffs <-  lltocv_ffs$random_kfold_cv
#lltocv_ffs <- get(load(models[grep("_lltocv_ffs",models)]))
#lltocv_cv_ffs <-  lltocv_ffs$random_kfold_cv
#ltocv_ffs <- get(load(models[grep("_ltocv_ffs",models)]))
#ltocv_cv_ffs <-  ltocv_ffs$random_kfold_cv

ffsselection <- list(lltocv_ffs,lltocv_cv_ffs)
names(ffsselection) <- c("lltocv_ffs","lltocv_cv_ffs")
################################################################################
### Get predictions and observed values for each resample
################################################################################

#modelslist <- append(noselection,rfeselection)
#modelslist <- append(modelslist,ffsselection)
modelslist <- append(noselection,ffsselection)

modelspred <- modelslist
for (i in 1:length(modelslist)){
  modelspred[[i]] <- modelslist[[i]]$pred[modelslist[[i]]$pred$mtry==
                                             modelslist[[i]]$results$mtry,]
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
maxm <- 0
minm <- 100
for (i in unique(results_melt_noselect$cv)){
valmin <- boxplot(results_melt_noselect$value[results_melt_noselect$cv==i])$stats[c(1, 5), ][1]
valmax <- boxplot(results_melt_noselect$value[results_melt_noselect$cv==i])$stats[c(1, 5), ][2]
maxm <- max(maxm,valmax)
minm <- min(minm,valmin)
}

pdf(paste0(figurepath,casestudy,"_comp_noselection.pdf"))
bwplot(results_melt_noselect$value~
         results_melt_noselect$modelopt,do.out = FALSE,
       notch=TRUE,ylab="|pred-obs|",ylim=c(minm-1,maxm+1),
       #scales = "free",
       fill="lightgrey",
       par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
                         strip.background=list(col="lightgrey"),
                         box.umbrella = list(col = "black"),
                         box.dot = list(col = "black", pch = 16, cex=0.4),
                         box.rectangle = list(col="black",
                                              fill= rep(c("black", "black"),2))))
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


pdf(paste0(figurepath,casestudy,"_comp_lltoCV.pdf"),width=9,height=5) 
boxplot(no_lltocv,no_lltocv_cv,rfe_lltocv,rfe_cv,ffs_lltocv,ffs_cv,
        col=c("grey50","grey90"),notch=TRUE,
        #pch=20,cex=0,
        outline=FALSE,
        names=rep(c("LLTO-CV","10-Fold-CV"),3),
        at=c(1,2,3.5,4.5,6,7),ylab="|pred-obs|")
mtext("No Selection", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.12, padj = 1,cex=1.2)
mtext("RFE", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.5, padj = 1,cex=1.2)
mtext("FFS", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.85, padj = 1,cex=1.2)
dev.off()