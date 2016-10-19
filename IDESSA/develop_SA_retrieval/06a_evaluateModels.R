# This scripts create a data frame with predicted values for the test data
# and the corresponding observed data. It then calculates summary statistics.
# This script requires trained models and test Data with predictor variables and
# observed rainfall.

rm(list=ls())
library(Rainfall)
library(Rsenal)
library(caret)
raineventsthres <- 5 # threshold. calculate rho only rate quantity if the number
#of stations that observed rainfall is higher than "raineventsthres"

mainpath <- "/media/memory01/data/IDESSA/Results/"
#mainpath <- "/media/hanna/data/CopyFrom181/Results/"
modelpath <- paste0(mainpath,"Model/")
outpath <- paste0(mainpath,"Evaluation/")



################################################################################
# Create validation data
################################################################################
results <- list()
acc <- 0
for (daytime in c("day","night")){
  acc <- acc+1
  testData <- get(load(paste0(modelpath,"test_dataset_",daytime,".RData")))
  results[[acc]] <- data.frame("Date"=testData$date,"Station"=testData$Station)
  for (responsetype in c("RA","RR")){
    model <- get(load(paste0(modelpath,daytime,"_model_",responsetype,".RData")))
    predVars <- scaleByValue(testData[,row.names(model$scaleParam)],
                             model$scaleParam)
    if (responsetype=="RR"){
      tmpnamespred <- paste0(responsetype,"_pred")
      tmpnamesobs <- paste0(responsetype,"_obs")
      tmp <- data.frame(testData$P_RT_NRT,predict(model,predVars))
      results[[acc]]  <- data.frame(results[[acc]] ,tmp)
      names(results[[acc]] )[(ncol(results[[acc]] )-1):ncol(results[[acc]] )] <- c(tmpnamesobs,
                                                                                   tmpnamespred)
    }else{
      tmp <- data.frame(testData$RainArea, predict(model,predVars),
                        predict(model,predVars,type="prob")$Rain)
      
      results[[acc]]  <- data.frame(results[[acc]] ,tmp)
      tmpnamesprob <- paste0(responsetype,"_prob")
      tmpnamespred <- paste0(responsetype,"_pred")
      tmpnamesobs <- paste0(responsetype,"_obs")
      names(results[[acc]] )[(ncol(results[[acc]] )-2):ncol(results[[acc]] )] <- c(
        tmpnamesobs,tmpnamespred,tmpnamesprob)
    }
  }
  results[[acc]] $RR_pred[results[[acc]] $RA_pred=="NoRain"] <- 0
  results[[acc]] $RR_pred[results[[acc]] $RR_pred<0] <- 0
  results[[acc]] $daytime <- daytime
}
results_all <- rbind(results[[1]],results[[2]])
save(results_all,file=paste0(outpath,"evaluationData_all.RData"))

################################################################################
# Caluclate hourly summary statistics
################################################################################

comp <- results_all
results_area <- data.frame()
results_rate <- data.frame()

for (i in unique(comp$Date)){
  subs <- comp[comp$Date==i,]
  results_area <- data.frame(rbind(results_area,
                                   data.frame("Date"=i,
                                              "Daytime" = unique(subs$daytime),
                                              "eventsObs" = sum(subs$RR_obs>0),
                                              "eventsPred" = sum(subs$RR_pred>0),
                                              classificationStats(subs$RA_pred,
                                                                  subs$RA_obs))))
  
  regMSG <- tryCatch(regressionStats(subs$RR_pred,
                                     subs$RR_obs,
                                     method="spearman"),  error = function(e)e)
  if (inherits(regMSG,"error")){next}
  results_rate <- data.frame(rbind(results_rate,
                                   data.frame("Date"=i,
                                              "Daytime" = unique(subs$daytime),
                                              "eventsObs" = sum(subs$RR_obs>0),
                                              "eventsPred" = sum(subs$RR_pred>0),
                                              regMSG)))
}

save(results_area,file=paste0(outpath,"/eval_area.RData"))
results_rate <- results_rate[,-which(names(results_rate)%in%c("ME.se","MAE.se","RMSE.se","Rsq"))]
results_rate$rho[results_rate$eventsObs<raineventsthres] <- NA
save(results_rate,file=paste0(outpath,"/eval_rate.RData"))

