#visualize
rm(list=ls())
mainpath <- "/home/hanna/Documents/Presentations/Paper/submitted/Nele_MIRS/data/"
#datapath <- paste0(mainpath,"data/")
#spectrapath <- paste0(datapath,"/Baseline/")
modelpath <- paste0(mainpath,"/modeldata/")
figurepath <- paste0(mainpath,"/figures/")
setwd(mainpath)

library(ggplot2)
#library(hexbin)
library(viridis)
library(Rsenal)

modelC <- get(load(paste0(modelpath,"/model_C.RData")))

pred <- data.frame("pred"=modelC$pred$pred[modelC$pred$mtry==modelC$bestTune$mtry],
                   "obs"=modelC$pred$obs[modelC$pred$mtry==modelC$bestTune$mtry])

pred$Land_use <- factor(modelC$trainingData$Land_use,c("Cropland","Grassland","Forest"))

pred$all <- "All land use types"
   
summary(lm(pred$pred~pred$obs))
regressionStats(pred$pred,pred$obs)
                
nbin <- 60
allluc <- ggplot(pred, aes(obs,pred)) + 
  stat_binhex(bins=nbin)+ 
  xlab("Measured SR")+
  ylab("Estimated SR")+
  #  labs(title="(a)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  xlim(0,15)+ylim(0,15)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 2^(0:6),colors=viridis(10))

pred_crop <- pred[pred$Land_use=="Cropland",]
cropland <- ggplot(pred_crop, aes(obs,pred)) + 
  stat_binhex(bins=nbin)+ 
  xlab("Measured SR")+
  ylab("Estimated SR")+
  #  labs(title="(b)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  xlim(0,15)+ylim(0,15)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 2^(0:6),colors=viridis(10))



pred_grass <- pred[pred$Land_use=="Grassland",]
grassland <- ggplot(pred_grass, aes(obs,pred)) + 
  stat_binhex(bins=nbin)+ 
  xlab("Measured SR")+
  ylab("Estimated SR")+
  #  labs(title="(c)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  xlim(0,15)+ylim(0,15)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 2^(0:6),colors=viridis(10))

pred_forest <- pred[pred$Land_use=="Forest",]
forest <- ggplot(pred_forest, aes(obs,pred)) + 
  stat_binhex(bins=nbin)+ 
  xlab("Measured SR")+
  ylab("Estimated SR")+
  #  labs(title="(d)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  xlim(0,15)+ylim(0,15)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 2^(0:6),colors=viridis(10))


alllucplot <- allluc+ facet_grid(. ~ Land_use) + theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_rect(colour = "black"))+
  theme(axis.title = element_text(colour = "black"),
        axis.text =  element_text(color = "black"))


allluc <- allluc+ facet_grid(. ~ all)+ theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_rect(colour = "black"))+
  theme(axis.title = element_text(colour = "black"),
        axis.text =  element_text(color = "black"))

tiff(paste0(figurepath,"/prediction_basedOnC.tiff"),width=12,height=10,res=500,units="cm")
#grid.arrange(allluc,cropland,grassland,forest)
allluc
dev.off()

tiff(paste0(figurepath,"/prediction_individuals_basedOnC.tiff"),width=17,height=7,res=500,units="cm",
     pointsize = 10)
alllucplot
dev.off()
############################################################################
# Standardized conditions
############################################################################
load(paste0(modelpath,"/model_SI_basal_final.RData"))
pred <- data.frame("pred"=model_Basal$pred$pred[model_Basal$pred$mtry==model_Basal$bestTune$mtry],
                   "obs"=model_Basal$pred$obs[model_Basal$pred$mtry==model_Basal$bestTune$mtry])
regressionStats(pred$pred,pred$obs)

load(paste0(modelpath,"/rfemodel_SI_Q10_final.RData"))
pred10 <- data.frame("pred"=model_Q10$pred$pred[model_Q10$pred$mtry==model_Q10$bestTune$mtry],
                   "obs"=model_Q10$pred$obs[model_Q10$pred$mtry==model_Q10$bestTune$mtry])
regressionStats(pred10$pred,pred10$obs)

load(paste0(modelpath,"/model_SI_stabil_final.RData"))
pred_stabil <- data.frame("pred"=model_stabil$pred$pred[model_stabil$pred$mtry==model_stabil$bestTune$mtry],
                   "obs"=model_stabil$pred$obs[model_stabil$pred$mtry==model_stabil$bestTune$mtry])
regressionStats(pred_stabil$pred,pred_stabil$obs)

tiff(paste0(figurepath,"/prediction_standardized.tiff"),width=18,height=8,res=500,units="cm",
     pointsize = 10)
par(mfrow=c(1,3))
plot(pred$obs,pred$pred,pch=16,xlab="Measured SR",ylab="Estimated SR",
     xlim=c(0,15),ylim=c(0,15))
abline(0,1)
plot(pred10$obs,pred10$pred,pch=16,xlab="Measured Q10",ylab="Estimated Q10",
     xlim=c(1.2,2.7),ylim=c(1.2,2.7))
abline(0,1)
plot(pred_stabil$obs,pred_stabil$pred,pch=16,xlab="Measured Stability",ylab="Estimated Stability",
     xlim=c(0.45,3.4),ylim=c(0.45,3.4))
abline(0,1)
dev.off()

