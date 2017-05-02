# this script takes models tarined and validated with different cross validation
# and feature selection strategies and compares their performance
rm(list=ls())
library(reshape2)
library(latticeExtra)

datapath <- "/media/memory01/data/hmeyer/Overfitting/"
#datapath <- "/media/hanna/data/Overfitting/"
outpath <- paste0(datapath,"/results/")
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
llocv_ffs <- get(load(models[grep("_llocv_ffs",models)]))
llocv_cv_ffs <-  llocv_ffs$random_kfold_cv
#lltocv_ffs <- get(load(models[grep("_lltocv_ffs",models)]))
#lltocv_cv_ffs <-  lltocv_ffs$random_kfold_cv
#ltocv_ffs <- get(load(models[grep("_ltocv_ffs",models)]))
#ltocv_cv_ffs <-  ltocv_ffs$random_kfold_cv

ffsselection <- list(llocv_ffs,llocv_cv_ffs)
names(ffsselection) <- c("llocv_ffs","llocv_cv_ffs")
################################################################################
### Get predictions and observed values for each resample
################################################################################

modelslist <- append(noselection,rfeselection)
modelslist <- append(modelslist,ffsselection)

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
pdf(paste0(figurepath,casestudy,"_comp_noselection.pdf"))
bwplot(results_melt_noselect$value~
         results_melt_noselect$modelopt,
       notch=TRUE,ylab="|pred-obs|",
       #scales = "free",
       fill="lightgrey",
       par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
                         strip.background=list(col="lightgrey"),
                         box.umbrella = list(col = "black"),
                         box.dot = list(col = "black", pch = 16, cex=0.4),
                         box.rectangle = list(col="black",
                                              fill= rep(c("black", "black"),2))))
dev.off()



####################### LLOCV Comparison ###################################

results_melt_llocv <- results_melt[results_melt$modelopt=="llocv",]
no_llocv <-  results_melt_llocv$value[
  results_melt_llocv$VarSelect=="noselect"&results_melt_llocv$cv!="cv"]
no_llocv_cv <- results_melt$value[results_melt$VarSelect=="noselect"&
                              results_melt$cv=="cv"&results_melt$modelopt=="cv"]

rfe_llocv <- results_melt_llocv$value[
  results_melt_llocv$VarSelect=="rfe"&results_melt_llocv$cv!="cv"]
rfe_cv <- results_melt_llocv$value[
  results_melt_llocv$VarSelect=="rfe"&results_melt_llocv$cv=="cv"]
ffs_llocv <- results_melt_llocv$value[
  results_melt_llocv$VarSelect=="ffs"&results_melt_llocv$cv!="cv"]
ffs_cv <- results_melt_llocv$value[
  results_melt_llocv$VarSelect=="ffs"&results_melt_llocv$cv=="cv"]


pdf(paste0(figurepath,casestudy,"_comp_LLOCV.pdf"),width=9,height=5) 
boxplot(no_llocv,no_llocv_cv,rfe_llocv,rfe_cv,ffs_llocv,ffs_cv,
        col=c("grey50","grey90"),notch=TRUE,
        #pch=20,cex=0,
        outline=FALSE,
        names=rep(c("LLO-CV","10-Fold-CV"),3),
        at=c(1,2,3.5,4.5,6,7),ylab="|pred-obs|")
mtext("No Selection", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.12, padj = 1,cex=1.2)
mtext("RFE", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.5, padj = 1,cex=1.2)
mtext("FFS", side = 1, line = 2, outer = FALSE, at = NA,
      adj = 0.85, padj = 1,cex=1.2)
dev.off()