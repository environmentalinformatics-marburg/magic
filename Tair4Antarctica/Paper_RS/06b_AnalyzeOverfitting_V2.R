rm(list=ls())
load("/media/hanna/data/Antarctica/results/MLFINAL/fullModel.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL/testData.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL/ffs_best_SD.RData")

library(hexbin)
library(caret)
library(grid)
library(viridis)
library(latticeExtra)

fullModel_cv <- fullModel$pred[fullModel$pred$committees==
                                 fullModel$finalModel$tuneValue$committees&
                                 fullModel$pred$neighbors==
                                 fullModel$finalModel$tuneValue$neighbors,]

test=predict(fullModel,fullModel$trainingData)


full_losocv_df <- data.frame("obs"=fullModel_cv$obs,"pred"=fullModel_cv$pred,
                             "model"="FULL","method"="LOSOCV")

regressionStats(full_losocv_df$pred,full_losocv_df$obs)

ffs_cv <- ffs_best$pred[ffs_best$pred$committees==
                          ffs_best$finalModel$tuneValue$committees&
                          ffs_best$pred$neighbors==
                          ffs_best$finalModel$tuneValue$neighbors,]


ffs_losocv_df <- data.frame("obs"=ffs_cv$obs,"pred"=ffs_cv$pred,"model"="FFS",
                            "method"="LOSOCV")

ffs_losocv_regstat <- regressionStats(ffs_losocv_df$pred,ffs_losocv_df$obs)

predtest_full <- predict(fullModel,testData)


fullModel_test_df <- data.frame("obs"=testData$statdat,"pred"=predtest_full,
                                "model"="FULL","method"="RSS")

fullModel_test_regstat<-regressionStats(fullModel_test_df$pred,fullModel_test_df$obs)

predtest_ffs <- predict(ffs_best,testData)


ffs_test_df <- data.frame("obs"=testData$statdat,"pred"=predtest_ffs,"model"="FFS",
                          "method"="RSS")


regressionStats(ffs_test_df$pred,ffs_test_df$obs)






complete_df <- rbind(ffs_losocv_df,ffs_test_df,full_losocv_df,
                     fullModel_test_df,
                     stringsAsFactors=FALSE)

complete_df$model<-factor(complete_df$model,levels=c("FFS","FULL"))
complete_df$method<-factor(complete_df$method,levels=c("RSS","LOSOCV"))

p <- useOuterStrips(xyplot(obs~pred|method+model,data=complete_df,
                           xlim=c(-82,10),ylim=c(-82,10),
                           panel=panel.smoothScatter,
                           xlab=expression('Predicted T'['air']*'(°C)'),
                           ylab=expression('Observed T'['air']*'(°C)'),asp=1),
                    strip.left =strip.custom(bg="grey"),
                    strip =strip.custom(bg="grey"))

################################################################################



stat_full <- do.call("rbind",lapply(seq(unique(testData$station)),function(i){
  stat <- as.character(unique(testData$station))[i]
  test <- testData$statdat[testData$station==stat]
  pred <- predtest_full[testData$station==stat]
  regstat <- regressionStats(test,pred)[,c(5,7)]
  regstat$Resample <- paste0("Resample",sprintf("%02d",i))
  names(regstat)[2]="Rsquared"
  regstat$model <- "FULL RSS"
  regstat
}))



stat_ffs <- do.call("rbind",lapply(seq(unique(testData$station)),function(i){
  stat <- as.character(unique(testData$station))[i]
  test <- testData$statdat[testData$station==stat]
  pred <- predtest_ffs[testData$station==stat]
  regstat <- regressionStats(test,pred)[,c(5,7)]
  regstat$Resample <- paste0("Resample",sprintf("%02d",i))
  names(regstat)[2]="Rsquared"
  regstat$model <- "FFS RSS"
  regstat
}))

################################################################################
fullModel$resample$model <- "FULL LOSOCV"
ffs_best$resample$model <- "FFS LOSOCV"
stationcomp <- rbind(fullModel$resample[order(fullModel$resample$Resample),],
                     ffs_best$resample[order(ffs_best$resample$Resample),],
                     stat_full,
                     stat_ffs)

bwplot(stationcomp$Rsquared~stationcomp$model)



fullModel_cv_regstat <- data.frame("RMSE"=min(fullModel$results$RMSE,na.rm=TRUE),
                                   "R2"=fullModel$results$Rsquared[which(
                                     fullModel$results$RMSE==min(fullModel$results$RMSE,na.rm=TRUE))])  

fullModel_cv_ptxt<-paste0("R² = ",sprintf("%.2f", round(fullModel_cv_regstat$R2,2)),
                          "\nRMSE = ",sprintf("%.2f", round(fullModel_cv_regstat$RMSE,2)))

ffs_cv_regstat <- data.frame("RMSE"=min(ffs_best$results$RMSE,na.rm=TRUE),
                             "R2"=ffs_best$results$Rsquared[which(
                               ffs_best$results$RMSE==min(ffs_best$results$RMSE,na.rm=TRUE))])  

ffs_cv_ptxt<-paste0("R² = ",sprintf("%.2f", round(ffs_cv_regstat$R2,2)),
                    "\nRMSE = ",sprintf("%.2f", round(ffs_cv_regstat$RMSE,2)))

fullModel_rss_ptxt<-paste0("R² = ",sprintf("%.2f", round(mean(stat_full$Rsquared),2)),
       "\nRMSE = ",sprintf("%.2f", round(mean(stat_full$RMSE,2))))
ffs_rss_ptxt<-paste0("R² = ",sprintf("%.2f", round(mean(stat_ffs$Rsquared),2)),
                           "\nRMSE = ",sprintf("%.2f", round(mean(stat_ffs$RMSE,2))))
labs <- c(ffs_rss_ptxt,ffs_cv_ptxt,
          fullModel_rss_ptxt,fullModel_cv_ptxt)
p1 <- update(p,panel = function(...) {
  panel.smoothScatter(nrpoints=0,...)
  panel.text(x=-10,y=-70,
             labels = labs[panel.number()])
})+
  layer(panel.abline(a=0,b=1))
  
png("/media/hanna/data/Antarctica/visualizations/evaluation_smoothscat_CV.png",
    width=17,height=17,units="cm",res = 600)
  print(p1)
  dev.off()