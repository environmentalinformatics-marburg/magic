library(reshape2)
library(latticeExtra)

datapath <- "/media/memory01/data/hmeyer/Overfitting/"

outpath <- paste0(datapath,"/results/")
#outpath <- "/home/hanna/Documents/Projects/Overfitting/" #tmp
setwd(outpath)

models_Tair <- list.files(,pattern="model_rf_Tair")
models_Tair_rfe <- list.files(,pattern="modelretrain_rf_Tair")

losocv_ffs <- get(load(models_Tair[grep("losocv_ffs",models_Tair)]))
cv_ffs <- get(load(models_Tair[grep("_cv_ffs",models_Tair)]))
losocv_rfe <- get(load(models_Tair_rfe[grep("losocv_rfe",models_Tair_rfe)]))
cv_rfe <- get(load(models_Tair_rfe[grep("_cv_rfe",models_Tair_rfe)]))
losocv_no <- get(load(models_Tair[grep("losocv_no",models_Tair)]))
cv_no <- get(load(models_Tair[grep("_cv_no",models_Tair)]))

losocv_ffs_pred <- losocv_ffs$pred[losocv_ffs$pred$mtry==losocv_ffs$results$mtry,]
cv_ffs_pred <- cv_ffs$pred[cv_ffs$pred$mtry==cv_ffs$results$mtry,]
losocv_no_pred <-losocv_no$pred [losocv_no$pred$mtry==losocv_no$results$mtry,]
cv_no_pred <- cv_no$pred[cv_no$pred$mtry==cv_no$results$mtry,]
losocv_rfe_pred <- losocv_rfe$pred[losocv_rfe$pred$mtry==losocv_rfe$results$mtry,]
cv_rfe_pred <- cv_rfe$pred[cv_rfe$pred$mtry==cv_rfe$results$mtry,]


losocv_ffs_pred <- data.frame("Diff"=abs(losocv_ffs_pred$pred-losocv_ffs_pred$obs),
                              "VarSelect"="ffs","cv"="LOLO")
cv_ffs_pred <- data.frame("Diff"=abs(cv_ffs_pred$pred-cv_ffs_pred$obs),
                          "VarSelect"="ffs","cv"="10fold")
losocv_no_pred <- data.frame("Diff"=abs(losocv_no_pred$pred-losocv_no_pred$obs),
                             "VarSelect"="no","cv"="LOLO")
cv_no_pred <- data.frame("Diff"=abs(cv_no_pred$pred-cv_no_pred$obs),
                         "VarSelect"="no","cv"="10fold")
losocv_rfe_pred <-   data.frame("Diff"=abs(losocv_rfe_pred$pred-losocv_rfe_pred$obs),
                                "VarSelect"="rfe","cv"="LOLO")
cv_rfe_pred   <- data.frame("Diff"=abs(cv_rfe_pred$pred-cv_rfe_pred$obs),
                            "VarSelect"="rfe","cv"="10fold")
results <- rbind(losocv_ffs_pred,cv_ffs_pred,losocv_no_pred,
                 cv_no_pred,losocv_rfe_pred,cv_rfe_pred)

results_melt <- melt(results)

bwplot(results_melt$value~results_melt$VarSelect|results_melt$cv,
       notch=TRUE,ylab="|pred-obs|",
       #scales = "free",
       fill="lightgrey",
       par.settings=list(plot.symbol=list(col="black",pch=8,cex=0.4),
                         strip.background=list(col="lightgrey"),
                         box.umbrella = list(col = "black"),
                         box.dot = list(col = "black", pch = 16, cex=0.4),
                         box.rectangle = list(col="black",
                                              fill= rep(c("black", "black"),2))))
