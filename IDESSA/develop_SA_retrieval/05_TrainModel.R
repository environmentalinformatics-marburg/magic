library(Rainfall)
setwd("/media/memory01/data/IDESSA/Model")
outpath <- "/media/memory01/data/IDESSA/Model/"

for (daytime in c("day","night")){
  
  trainData <- get(load(paste0(outpath,"trainData_",daytime,".RData")))
  if(daytime=="day"){
    
    predictornames <- c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3",
                        "IR8.7","IR9.7","IR10.8","IR12.0","IR13.4","sunzenith",
                        "WV6.2_IR10.8","WV7.3_IR12.0","IR8.7_IR10.8","IR10.8_IR12.0",
                        "IR3.9_WV7.3","IR3.9_IR10.8")
  }else{
    predictornames <- c("IR3.9","WV6.2","WV7.3",
                        "IR8.7","IR9.7","IR10.8","IR12.0","IR13.4",
                        "WV6.2_IR10.8","WV7.3_IR12.0","IR8.7_IR10.8","IR10.8_IR12.0",
                        "IR3.9_WV7.3","IR3.9_IR10.8")
    
  }
  responseRA <- dataset$RainArea
  predictorsRA <- trainData[,predictornames]
  
  responseRR <-trainData$P_RT_NRT[trainData$P_RT_NRT>0]
  predictorsRR <- trainData[trainData$P_RT_NRT>0,predictornames]
  
  model_RA <- train4rainfall(predictorsRA,responseRA, out = "RInfo",
                             scaleVars = TRUE,sampsize = 1)
  
  save(model_RA,file=paste0(outpath,daytime,"_model_RA.RData"))
  
  model_RR <- train4rainfall(predictorsRR,responseRR,scaleVars = TRUE,
                             sampsize = 1)
  save(model_RR,file=paste0(outpath,daytime,"_model_RR.RData"))
}