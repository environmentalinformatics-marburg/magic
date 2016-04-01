rm(list=ls())
library(caret)
library(Rsenal)
library(hexbin)
library(grid)
library(gridExtra)


setwd("/media/hanna/data/Antarctica/results/MLFINAL/")
modellist <- list.files(,pattern="model")
ptxt<-c()
hbp<-list()
for (i in 1:length(modellist)){
  model <- get(load(modellist[i]))
  modelname <- substr(modellist[i],7,9)
  if (modelname=="RF."){modelname="RF"}
  regstat <- data.frame("RMSE"=min(model$results$RMSE,na.rm=TRUE),
                        "R2"=model$results$Rsquared[which(
                          model$results$RMSE==min(model$results$RMSE,na.rm=TRUE))])  
  if (modelname=="CUB"){
  obs <- model$pred$obs[model$pred$committees==model$bestTune$committees&
                          model$pred$neighbors==model$bestTune$neighbors]
  pred <- model$pred$pred[model$pred$committees==model$bestTune$committees&
                          model$pred$neighbors==model$bestTune$neighbors]
  }
  if (modelname=="GBM"){
    obs <- model$pred$obs[model$pred$shrinkage==model$bestTune$shrinkage&
                            model$pred$n.trees==model$bestTune$n.trees]
    pred <- model$pred$pred[model$pred$shrinkage==model$bestTune$shrinkage&
                              model$pred$n.trees==model$bestTune$n.trees]
  }
  
  if (modelname=="RF"){
    obs <- model$pred$obs[model$pred$mtry==model$bestTune$mtry]
    pred <- model$pred$pred[model$pred$mtry==model$bestTune$mtry]
  }
  if (modelname=="LIN"){
    obs <- model$pred$obs
    pred <- model$pred$pred
  }
  
  
  
#  pdf(paste0("/media/hanna/data/Antarctica/visualizations/evaluation_",
#             modelname,"_hexbin_CV.pdf"))
  ptxt[i]<-paste0("R^2 = ",sprintf("%.2f", round(regstat$R2,2)),
               "\nRMSE = ",sprintf("%.2f", round(regstat$RMSE,2)))
  hbp[[i]] <- hexbinplot(obs~pred,xbins=60,
                  xlim=c(-80,10),ylim=c(-80,10),maxcnt=60,
                    ylab="Measured Air temperature (°C)", 
                    xlab="Predicted Air temperature(°C)",
                    colramp=colorRampPalette(rev(terrain.colors(10))),
                    panel = function(...) {
                      panel.hexbinplot(...)
                      panel.abline(a=0,b=1,lwd=2)
                      grid.text(ptxt[i], 0.1, 0.82)
                      
                    })
#  print(hbp)
#  dev.off()
}

hp <- c(update(hbp[[1]],
                   panel = function(...) {
                     panel.hexbinplot(...)
                     panel.abline(a=0,b=1,lwd=2)
                     grid.text(ptxt[1], 0.09, 0.89,just="left",gp=gpar(fontsize=9))}),
          update(hbp[[2]],
                 panel = function(...) {
                   panel.hexbinplot(...)
                   panel.abline(a=0,b=1,lwd=2)
                   grid.text(ptxt[2], 0.09, 0.89,just="left",gp=gpar(fontsize=9))}),
          update(hbp[[3]],
                 panel = function(...) {
                   panel.hexbinplot(...)
                   panel.abline(a=0,b=1,lwd=2)
                   grid.text(ptxt[3], 0.09, 0.89,just="left",gp=gpar(fontsize=9))}),
          update(hbp[[4]],
                 panel = function(...) {
                   panel.hexbinplot(...)
                   panel.abline(a=0,b=1,lwd=2)
                   grid.text(ptxt[4], 0.09, 0.89,just="left",gp=gpar(fontsize=9))})
          )


pdf(paste0("/media/hanna/data/Antarctica/visualizations/evaluation_hexbin_CV.pdf"))
hp
dev.off()
#names =model_LIN,model_RF,model_CUB,model_GBM

    