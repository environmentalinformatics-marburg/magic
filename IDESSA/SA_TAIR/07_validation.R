rm(list=ls())
library(caret)
library(corrplot)
library(viridis)
library(Rsenal)
library(vioplot)

mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/forPaper/"
datapath <- paste0(mainpath,"/modeldat")
vispath <- paste0(mainpath,"/visualizations")

testdata <- get(load(paste0(datapath,"/testdata.RData")))
model <- get(load(paste0(datapath,"/model_rf_LLTO.RData")))
dataset <- get(load(paste0(datapath,"/dataset_withNDVI.RData")))


#### Visualize Individual Linear Relation
dataset <- dataset[,names(dataset)%in%c(names(model$trainingData),"Tair")]
dataset <- dataset[complete.cases(dataset),]
dataset <- dataset[,c(1:12,14,13)]
names(dataset)[names(dataset)=="ndvi"] <- "NDVI"
names(dataset)[names(dataset)=="sunzenith"] <- "Sunzenith"
M <- cor(dataset)
pdf(paste0(vispath,"/corrplot.pdf"),width=6,height=6)
corrplot(M, method="color",type="lower",tl.col="black",
         tl.cex=0.9)
dev.off()

#### Validate with external testdata
pred <- predict(model,testdata)
regstats <- regressionStats(pred,testdata$Tair)
write.csv(regstats,paste0(vispath,"/regstats.csv"))

dat <- data.frame(pred=pred,obs=testdata$Tair)

pdf(paste0(vispath,"/externalvalidation.pdf"),width=6,height=5)
ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
  xlim(min(dat),max(dat))+ylim(min(dat),max(dat))+
  xlab("Measured Tair (°C)")+
  ylab("Predicted Tair (°C)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:3),colors=viridis(10))
dev.off()

pdf(paste0(vispath,"/datadistribution.pdf"),width=5,height=4)
vioplot(dat$obs,dat$pred,names=c("measured","predicted"),
        col="grey80")
dev.off()
