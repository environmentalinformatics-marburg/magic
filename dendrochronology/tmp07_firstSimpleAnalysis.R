#tmp07_firstSimpleAnalysis

rm(list=ls())
library(lubridate)
library(caret)
library(CAST)
mainpath <- "/home/hanna/Documents/Projects/Dendrodaten/"
dendropath <- paste0(mainpath, "/data/dendrodata/")
predpath <- paste0(mainpath, "/data/T_Prec_basedata/")
modelpath <- paste0(mainpath, "/model/")
vispath <- paste0(mainpath,"/visualizations/")

dendro <- get(load(paste0(predpath,"predictorsDendroMerged.RData")))
dendro <- dendro[complete.cases(dendro),]
#train a rf LLOCV model
indices <- CreateSpacetimeFolds(dendro,spacevar="Plot",
                                k=length(unique(dendro$Plot)))

model <- train(dendro[,c(1,4:(ncol(dendro)-1))],dendro$Dendro,model="rf",
               trControl = trainControl(method="cv",savePredictions = TRUE,
                                        returnResamp = "all",
                                        index=indices$index,indexOut=indices$indexOut),
               importance=TRUE)

save(model,file=paste0(modelpath,"/model_LLO.RData"))

dat <- model$pred[model$pred$mtry==model$finalModel$mtry,]

pdf(paste0(vispath,"/validation_LLO.pdf"))
ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
  xlim(min(dat[,1:2]),max(dat[,1:2]))+ylim(min(dat[,1:2]),max(dat[,1:2]))+
  xlab("Measured")+
  ylab("Predicted")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points",
                       breaks = seq(5,50,5),colors=viridis(10))
dev.off()

pdf(paste0(vispath,"/varimp.pdf"))
plot(varImp(model))
dev.off()


################# NUR ZUM VERGLEICH
model_Random <- train(dendro[,4:(ncol(dendro)-1)],dendro$Dendro,model="rf",
               trControl = trainControl(method="cv",savePredictions = TRUE,
                                        returnResamp = "all"),
               importance=TRUE)

save(model_Random,file=paste0(modelpath,"model_Random"))
dat <- model_Random$pred[model_Random$pred$mtry==model_Random$finalModel$mtry,]

pdf(paste0(vispath,"/validation_random.pdf"))
ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
  xlim(min(dat[,1:2]),max(dat[,1:2]))+ylim(min(dat[,1:2]),max(dat[,1:2]))+
  xlab("Measured")+
  ylab("Predicted")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points",
                       breaks = seq(5,50,5),colors=viridis(10))
dev.off()


################# Aggregated
dendro_agg <- aggregate(dendro[,4:ncol(dendro)],by=list(dendro$Plot,dendro$Year),
                     median)
names(dendro_agg)[1:2] <- c("Plot","Year")


indices <- CreateSpacetimeFolds(dendro_agg,spacevar="Plot",
                                k=length(unique(dendro_agg$Plot)))

model <- train(dendro_agg[,3:(ncol(dendro_agg)-1)],dendro_agg$Dendro,model="rf",
               trControl = trainControl(method="cv",savePredictions = TRUE,
                                        returnResamp = "all",
                                        index=indices$index,indexOut=indices$indexOut),
               importance=TRUE,tuneLength=15)


dat <- model$pred[model$pred$mtry==model$finalModel$mtry,]

pdf(paste0(vispath,"/validation_agg_LLO.pdf"))
ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
  xlim(min(dat[,1:2]),max(dat[,1:2]))+ylim(min(dat[,1:2]),max(dat[,1:2]))+
  xlab("Measured")+
  ylab("Predicted")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "data points",
                       breaks = seq(5,50,5),colors=viridis(10))
dev.off()

pdf(paste0(vispath,"/varimp_agg.pdf"))
plot(varImp(model))
dev.off()
