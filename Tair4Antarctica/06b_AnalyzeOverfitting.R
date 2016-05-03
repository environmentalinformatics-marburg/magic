rm(list=ls())
load("/media/hanna/data/Antarctica/results/MLFINAL/fullModel.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL/testData.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL/ffs_best_SD.RData")

library(hexbin)
library(caret)
library(grid)
library(viridis)

fullModel_cv <- fullModel$pred[fullModel$pred$committees==
                            fullModel$finalModel$tuneValue$committees&
                            fullModel$pred$neighbors==
                            fullModel$finalModel$tuneValue$neighbors,]



ffs_cv <- ffs_best$pred[ffs_best$pred$committees==
                          ffs_best$finalModel$tuneValue$committees&
                          ffs_best$pred$neighbors==
                          ffs_best$finalModel$tuneValue$neighbors,]



#### FULL MODEL CV
fullModel_cv_regstat <- data.frame("RMSE"=min(fullModel$results$RMSE,na.rm=TRUE),
                      "R2"=fullModel$results$Rsquared[which(
                        fullModel$results$RMSE==min(fullModel$results$RMSE,na.rm=TRUE))])  

fullModel_cv_ptxt<-paste0("R^2 = ",sprintf("%.2f", round(fullModel_cv_regstat$R2,2)),
                "\nRMSE = ",sprintf("%.2f", round(fullModel_cv_regstat$RMSE,2)))
fullModel_cv_hex <- hexbinplot(fullModel_cv$obs~fullModel_cv$pred,
           xbins=60,maxcnt=90,
           xlim=c(-80,10),ylim=c(-80,10),
           ylab="Measured Air temperature (°C)", 
           xlab="Predicted Air temperature(°C)",
           colramp=colorRampPalette(rev(viridis(10))))
         

#### FULL MODEL TEST
predtest <- predict(fullModel,testData)
regstat <- regressionStats(predtest,testData$statdat)
fullModel_test_regstat <- data.frame("RMSE"=regstat$RMSE,
                                   "R2"=regstat$Rsq)  

fullModel_test_ptxt<-paste0("R^2 = ",sprintf("%.2f", round(fullModel_test_regstat$R2,2)),
                          "\nRMSE = ",sprintf("%.2f", round(fullModel_test_regstat$RMSE,2)))
fullModel_test_hex <- hexbinplot(testData$statdat~predtest,
                               xbins=60,maxcnt=90,
                               xlim=c(-80,10),ylim=c(-80,10),
                               ylab="Measured Air temperature (°C)", 
                               xlab="Predicted Air temperature(°C)",
                               colramp=colorRampPalette(rev(viridis(10))))

#### FFS MODEL CV

ffs_cv_regstat <- data.frame("RMSE"=min(ffs_best$results$RMSE,na.rm=TRUE),
                                   "R2"=ffs_best$results$Rsquared[which(
                                     ffs_best$results$RMSE==min(ffs_best$results$RMSE,na.rm=TRUE))])  

ffs_cv_ptxt<-paste0("R^2 = ",sprintf("%.2f", round(ffs_cv_regstat$R2,2)),
                          "\nRMSE = ",sprintf("%.2f", round(ffs_cv_regstat$RMSE,2)))
ffs_cv_hex <- hexbinplot(ffs_cv$obs~ffs_cv$pred,
                               xbins=60,maxcnt=90,
                               xlim=c(-80,10),ylim=c(-80,10),
                               ylab="Measured Air temperature (°C)", 
                               xlab="Predicted Air temperature(°C)",
                               colramp=colorRampPalette(rev(viridis(10))))
                             
#### FFS MODEL TEST
predtest <- predict(ffs_best,testData)
regstat <- regressionStats(predtest,testData$statdat)
ffs_test_regstat <- data.frame("RMSE"=regstat$RMSE,
                                     "R2"=regstat$Rsq)  

ffs_test_ptxt<-paste0("R^2 = ",sprintf("%.2f", round(ffs_test_regstat$R2,2)),
                            "\nRMSE = ",sprintf("%.2f", round(ffs_test_regstat$RMSE,2)))
ffs_test_hex <- hexbinplot(testData$statdat~predtest,
                                 xbins=60,maxcnt=90,
                                 xlim=c(-80,10),ylim=c(-80,10),
                                 ylab="Measured Air temperature (°C)", 
                                 xlab="Predicted Air temperature(°C)",
                                colramp=colorRampPalette(rev(viridis(10))))
                               


hp <- c(
  update(ffs_cv_hex,
               panel = function(...) {
                 panel.hexbinplot(...)
                 panel.abline(a=0,b=1,lwd=2)
                 grid.text(ffs_cv_ptxt, 0.09, 0.89,just="left",gp=gpar(fontsize=9))}),

        update(ffs_test_hex,
               panel = function(...) {
                 panel.hexbinplot(...)
                 panel.abline(a=0,b=1,lwd=2)
                 grid.text(ffs_test_ptxt, 0.09, 0.89,just="left",gp=gpar(fontsize=9))}),
  update(fullModel_cv_hex,
         panel = function(...) {
           panel.hexbinplot(...)
           panel.abline(a=0,b=1,lwd=2)
           grid.text(fullModel_cv_ptxt, 0.09, 0.89,just="left",gp=gpar(fontsize=9))}),
  update(fullModel_test_hex,
         panel = function(...) {
           panel.hexbinplot(...)
           panel.abline(a=0,b=1,lwd=2)
           grid.text(fullModel_test_ptxt, 0.09, 0.89,just="left",gp=gpar(fontsize=9))})
     
  )
pdf(paste0("/media/hanna/data/Antarctica/visualizations/overfitting_hexbin.pdf"))
hp
dev.off()

################################################################################
#fullModel_cv: fullModel_cv$obs~fullModel_cv$pred
#fullModel test: testData$statdat~predtest
#ffs model test: testData$statdat~predtest
#ffs_cv: ffs_cv$obs~ffs_cv$pred

################################################################################