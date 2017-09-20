rm(list=ls())
library(caret)
library(randomForest)
library(Rsenal)
library(viridis)

mainpath <- "/media/hanna/data/IDESSA_Bush/Sentinel/"
resultpath <- paste0(mainpath,"/Results/")
vispath <- paste0(mainpath,"/Visualizations/")

model <- get(load(paste0(resultpath,"/sentinelmodel.RData")))
testdat <-  get(load(paste0(resultpath,"/testdata.RData")))

#Variable importance
pdf(paste0(vispath,"/varimp.pdf"))
varImpPlot(model$finalModel,main="")
dev.off()

# Validation with external test data
pred <- predict(model,testdata)
stats <- regressionStats(pred,testdata$bush)
write.csv(stats,paste0(resultpath,"/externalvalid.csv"))

# Visualization of validation
dat <- data.frame(pred=pred,obs=testdata$bush)

pdf(paste0(vispath,"externalvalidation.pdf"))
ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
  xlim(0,1)+ylim(0,1)+
  xlab("Observed bush density in %")+
  ylab("Predicted bush density in %")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:4),colors=viridis(10))
dev.off()
