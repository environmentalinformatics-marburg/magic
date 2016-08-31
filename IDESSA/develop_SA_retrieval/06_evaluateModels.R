#evaluate Models
rm(list=ls())
library(Rainfall)
library(Rsenal)
library(caret)
setwd("/media/memory01/data/IDESSA/Results/Model/")
outpath <- "/media/memory01/data/IDESSA/Results/Evaluation/"

for (daytime in c("day","night")){
  testData <- get(load(paste0("test_dataset_",daytime,".RData")))
  results <- data.frame("Date"=testData$date,"Station"=testData$Station)
  for (responsetype in c("RA","RR")){
    model <- get(load(paste0(daytime,"_model_",responsetype,".RData")))
    predVars <- scaleByValue(testData[,row.names(model$scaleParam)],model$scaleParam)
    if (responsetype=="RR"){
      tmpnamespred<-paste0(responsetype,"_pred")
      tmpnamesobs <- paste0(responsetype,"_obs")
      tmp <- data.frame(testData$P_RT_NRT,predict(model,predVars))
      results <- data.frame(results,tmp)
      names(results)[(ncol(results)-1):ncol(results)] <- c(
        tmpnamesobs,tmpnamespred)
      
    }else{
      tmp <- data.frame(testData$RainArea, predict(model,predVars),
                        predict(model,predVars,type="prob")$Rain)

          results <- data.frame(results,tmp)
      tmpnamesprob <- paste0(responsetype,"_prob")
      tmpnamespred <- paste0(responsetype,"_pred")
      tmpnamesobs <- paste0(responsetype,"_obs")
      names(results)[(ncol(results)-2):ncol(results)] <- c(
        tmpnamesobs,tmpnamespred,tmpnamesprob)
    }
  }
  results$RR_pred[results$RA_pred=="NoRain"]=0
  if(daytime=="night"){
    results_all <- rbind(resultstmp,results)
  }
  if(daytime=="day"){
    resultstmp <- results
  }
  save(results,file=paste0(outpath,"evaluationData_",daytime,".RData"))
}
save(results_all,file=paste0(outpath,"evaluationData_all.RData"))

#################################################################################
comp <- results_all
results_area <- data.frame()

for (i in unique(comp$Date)){
  subs <- comp[comp$Date==i,]
  subs_s <- subs[subs$RR_obs<mean(subs$RR_obs),]
  subs_l <- subs[subs$RR_obs>=mean(subs$RR_obs),]
  if (nrow(subs)<5){next}
  results_area <- data.frame(rbind(results_area,
                                   data.frame("Date"=i,
                                              classificationStats(subs$RA_pred,subs$RA_obs))))
 
}
save(results_area,file=paste0(outpath,"/eval_area.RData"))


results_rate <- data.frame()
for (i in unique(comp$Date)){
  subs <- comp[comp$Date==i,]
  if (nrow(subs)<5){next}
  if(sum(subs$RA_obs=="Rain")<5){next}
  results_rate <- data.frame(rbind(results_rate,
                                   data.frame("Date"=i,
                                              regressionStats(subs$RR_pred[subs$RA_obs=="Rain"],
                                                              subs$RR_obs[subs$RA_obs=="Rain"],
                                                              adj.rsq = FALSE))))
}
results_rate <- results_rate[,-which(names(results_rate)%in%c("ME.se","MAE.se","RMSE.se"))]
save(results_rate,file=paste0(outpath,"/eval_rate.RData"))

