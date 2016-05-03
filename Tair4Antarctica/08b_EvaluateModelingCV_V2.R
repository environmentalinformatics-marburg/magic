rm(list=ls())
library(caret)
library(Rsenal)
library(hexbin)
library(grid)
library(gridExtra)
library(viridis)
library(latticeExtra)

setwd("/media/hanna/data/Antarctica/results/MLFINAL/")
modellist <- list.files(,pattern="model")
ptxt<-c()
hbp<-list()
for (i in 1:length(modellist)){
  model <- get(load(modellist[i]))
  modelname <- substr(modellist[i],7,9)
  if (modelname=="RF."){modelname="RF"}
 
  if (modelname=="CUB"){
    CUB <- data.frame("obs"=model$pred$obs[model$pred$committees==model$bestTune$committees&
                            model$pred$neighbors==model$bestTune$neighbors],
                      "pred"=model$pred$pred[model$pred$committees==model$bestTune$committees&
                              model$pred$neighbors==model$bestTune$neighbors],
                      "model"="CUBIST")
    
    
    CUB_regstat <- data.frame("RMSE"=min(model$results$RMSE,na.rm=TRUE),
                                       "R2"=model$results$Rsquared[which(
                                         model$results$RMSE==min(model$results$RMSE,na.rm=TRUE))])  
    
   CUB_ptxt<-paste0("Rsq = ",sprintf("%.2f", round(CUB_regstat$R2,2)),
                              "\nRMSE = ",sprintf("%.2f", round(CUB_regstat$RMSE,2)))
  }
  if (modelname=="GBM"){
    GBM <- data.frame("obs"=model$pred$obs[model$pred$shrinkage==model$bestTune$shrinkage&
                            model$pred$n.trees==model$bestTune$n.trees],
                      "pred"= model$pred$pred[model$pred$shrinkage==model$bestTune$shrinkage&
                              model$pred$n.trees==model$bestTune$n.trees],
                      "model"="GBM")
    GBM_regstat <- data.frame("RMSE"=min(model$results$RMSE,na.rm=TRUE),
                              "R2"=model$results$Rsquared[which(
                                model$results$RMSE==min(model$results$RMSE,na.rm=TRUE))])  
    
    GBM_ptxt<-paste0("Rsq = ",sprintf("%.2f", round(GBM_regstat$R2,2)),
                     "\nRMSE = ",sprintf("%.2f", round(GBM_regstat$RMSE,2)))
  }
  
  if (modelname=="RF"){
    RF <- data.frame("obs"=model$pred$obs[model$pred$mtry==model$bestTune$mtry],
                     "pred"=model$pred$pred[model$pred$mtry==model$bestTune$mtry],
                     "model"="RF")
    RF_regstat <- data.frame("RMSE"=min(model$results$RMSE,na.rm=TRUE),
                              "R2"=model$results$Rsquared[which(
                                model$results$RMSE==min(model$results$RMSE,na.rm=TRUE))])  
    
    RF_ptxt<-paste0("Rsq = ",sprintf("%.2f", round(RF_regstat$R2,2)),
                     "\nRMSE = ",sprintf("%.2f", round(RF_regstat$RMSE,2)))
  }
  if (modelname=="LIN"){
    LINEAR <- data.frame("obs"=model$pred$obs,"pred"=model$pred$pred,"model"="LINEAR")
    LIN_regstat <- data.frame("RMSE"=min(model$results$RMSE,na.rm=TRUE),
                             "R2"=model$results$Rsquared[which(
                               model$results$RMSE==min(model$results$RMSE,na.rm=TRUE))])  
    
    LIN_ptxt<-paste0("Rsq = ",sprintf("%.2f", round(LIN_regstat$R2,2)),
                    "\nRMSE = ",sprintf("%.2f", round(LIN_regstat$RMSE,2)))
  }
}

complete_df <- rbind(CUB,GBM,
                     LINEAR,RF,
                       stringsAsFactors=FALSE)
  
p <- xyplot(obs~pred|model,data=complete_df,
                           panel=panel.smoothScatter,
                           xlab=expression('Predicted T'['air']*'(°C)'),
                           ylab=expression('Observed T'['air']*'(°C)'),asp=1,
            par.settings = list(strip.background=list(col="grey")))




labs <- c(CUB_ptxt,GBM_ptxt,
          LIN_ptxt,RF_ptxt)

p1 <- update(p,panel = function(...) {
  panel.smoothScatter(...)
  panel.text(x=-12,y=-70,
             labels = labs[panel.number()])
})+
  layer(panel.abline(a=0,b=1))

png("/media/hanna/data/Antarctica/visualizations/evaluation_smoothscat.png",
    width=17,height=17,units="cm",res = 600)
print(p1)
dev.off()