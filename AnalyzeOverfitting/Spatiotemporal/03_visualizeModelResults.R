# this script takes models trained and validated with different cross validation
# and feature selection strategies and compares their performance
rm(list=ls())
library(reshape2)
library(latticeExtra)
library(Rsenal)
library(caret)
library(scales)
################################################################################
#USER ADJUSTMENTS
datapath <- "/home/hanna/Documents/Projects/completed/Overfitting/"
casestudy <- "Tair" # cookfarm, Tair or Expl
targets <- c("LLTOCV","LLOCV","LTOCV") #"LLOCV,LTOCV
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

#### # Recursive feature selection
rfeselection <- list()
load_lltocv <- tryCatch({
  lltocv_rfe <- get(load(models[grep("_lltocv_rfe",models)]))
  lltocv_cv_rfe <- lltocv_rfe$random_kfold_cv
  rfeselection_lltocv <- list(lltocv_rfe,lltocv_cv_rfe)
  names(rfeselection_lltocv) <- c("lltocv_rfe","lltocv_cv_rfe")
  rfeselection <- append(rfeselection,rfeselection_lltocv)
},error = function(e) e)

load_llocv <- tryCatch({
  llocv_rfe <- get(load(models[grep("_llocv_rfe",models)]))
  llocv_cv_rfe <- llocv_rfe$random_kfold_cv
  rfeselection_llocv <- list(llocv_rfe,llocv_cv_rfe)
  names(rfeselection_llocv) <- c("llocv_rfe","llocv_cv_rfe")
  rfeselection <- append(rfeselection,rfeselection_llocv)
},error = function(e) e)

load_ltocv <- tryCatch({
  ltocv_rfe <- get(load(models[grep("_ltocv_rfe",models)]))
  ltocv_cv_rfe <- ltocv_rfe$random_kfold_cv
  rfeselection_ltocv <- list(ltocv_rfe,ltocv_cv_rfe)
  names(rfeselection_ltocv) <- c("ltocv_rfe","ltocv_cv_rfe")
  rfeselection <- append(rfeselection,rfeselection_ltocv)
},error = function(e) e)


#### # Forward feature selection
ffsselection <- list()
load_lltocv <- tryCatch({
  lltocv_ffs <- get(load(models[grep("_lltocv_ffs",models)]))
  lltocv_cv_ffs <- lltocv_ffs$random_kfold_cv
  ffsselection_lltocv <- list(lltocv_ffs,lltocv_cv_ffs)
  names(ffsselection_lltocv) <- c("lltocv_ffs","lltocv_cv_ffs")
  ffsselection <- append(ffsselection,ffsselection_lltocv)
},error = function(e) e)

load_llocv <- tryCatch({
  llocv_ffs <- get(load(models[grep("_llocv_ffs",models)]))
  llocv_cv_ffs <- llocv_ffs$random_kfold_cv
  ffsselection_llocv <- list(llocv_ffs,llocv_cv_ffs)
  names(ffsselection_llocv) <- c("llocv_ffs","llocv_cv_ffs")
  ffsselection <- append(ffsselection,ffsselection_llocv)
},error = function(e) e)

load_ltocv <- tryCatch({
  ltocv_ffs <- get(load(models[grep("_ltocv_ffs",models)]))
  ltocv_cv_ffs <- ltocv_ffs$random_kfold_cv
  ffsselection_ltocv <- list(ltocv_ffs,ltocv_cv_ffs)
  names(ffsselection_ltocv) <- c("ltocv_ffs","ltocv_cv_ffs")
  ffsselection <- append(ffsselection,ffsselection_ltocv)
},error = function(e) e)


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

####################### FFS Comparison ###################################
for (target in targets){
  results_melt_target <- results_melt[results_melt$modelopt==tolower(target),]
  no_target <-  results_melt_target$value[
    results_melt_target$VarSelect=="noselect"&results_melt_target$cv!="cv"]
  no_target_cv <- results_melt$value[results_melt$VarSelect=="noselect"&
                                       results_melt$cv=="cv"&results_melt$modelopt=="cv"]
  
  rfe_target <- results_melt_target$value[
    results_melt_target$VarSelect=="rfe"&results_melt_target$cv!="cv"]
  rfe_cv <- results_melt_target$value[
    results_melt_target$VarSelect=="rfe"&results_melt_target$cv=="cv"]
  ffs_target <- results_melt_target$value[
    results_melt_target$VarSelect=="ffs"&results_melt_target$cv!="cv"]
  ffs_cv <- results_melt_target$value[
    results_melt_target$VarSelect=="ffs"&results_melt_target$cv=="cv"]
  
  targetstring <- paste0(substr(target,1,nchar(target)-2),"-CV")
  pdf(paste0(figurepath,casestudy,"_comp_",target,".pdf"),width=9,height=6) 
  boxplot(no_target_cv,no_target,rfe_cv,rfe_target,ffs_cv,ffs_target,
          col=c("grey90","grey50"),notch=TRUE,
          #pch=20,cex=0,
          outline=FALSE,
          names=rep(c("random-CV",targetstring),3),
          at=c(1,2,3.5,4.5,6,7),ylab="cross-validated |pred-obs|")
  mtext("No Selection", side = 1, line = 2, outer = FALSE, at = NA,
        adj = 0.12, padj = 1,cex=1.2)
  mtext("RFE", side = 1, line = 2, outer = FALSE, at = NA,
        adj = 0.5, padj = 1,cex=1.2)
  mtext("FFS", side = 1, line = 2, outer = FALSE, at = NA,
        adj = 0.85, padj = 1,cex=1.2)
  dev.off()
}
################################################################################
################# Regression Table #############################################
################################################################################
regstats <- c()
sds_obs <- c()
means_obs <- c()
for (i in 1:length(modelspred)){
  regstats <- rbind(regstats,regressionStats(modelspred[[i]]$obs,modelspred[[i]]$pred))
  means_obs <- c(means_obs,mean(modelspred[[i]]$obs))
  sds_obs <- c(sds_obs,sd(modelspred[[i]]$obs))
}
regstats$mean_obs <- means_obs
regstats$sd_obs <- sds_obs
regstats <- round(regstats,4)
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
        notch=TRUE,ylab="cross-validated |pred-obs|",ylim=c(minm-minm*0.1,maxm+maxm*0.1),
        col="grey50",names=c("No Selection","RFE","FFS"))
dev.off()

################################################################################
################# plotVarImp ###################################################
################################################################################
pdf(paste0(figurepath,casestudy,"_varimp.pdf"),width=4,height=4)
plot(varImp(cv_noselect),col="black")
dev.off()
#from RFE
model_raw <- get(load(list.files(,pattern=paste0("model_raw_rf_",casestudy,"_lltocv_rfe"))))
subs <- model_raw$variables[model_raw$variables$Variables==max(model_raw$variables$Variables),]
imp <- aggregate(subs$Overall,by=list(subs$var),FUN="mean")

imp$x <- rescale(imp$x, to = c(0, 100))
imp <- imp[order(imp$x,decreasing = TRUE),]

imps <- list("importance" = data.frame("Overall"=imp$x,row.names = imp$Group.1),
             "model"=factor("rf"),"calledFrom"="varImp")
class(imps)<-"varImp.train"
pdf(paste0(figurepath,casestudy,"_varimpFromRFE.pdf"),width=4,height=4)
plot(imps,col="black")
dev.off()

################################################################################

