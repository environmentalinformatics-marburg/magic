rm(list=ls())
library(ggplot2)
library(viridis)
library(gridExtra)


nbin <- 60

setwd("/home/hanna/Documents/Presentations/Paper/in_prep/Nele_MIRS/figures/")
pred <- read.csv("predtab.csv")
pred <- pred[complete.cases(pred[,c("pred","obs")]),]
pred$all <- "All land use types"
pred$Land_use <- factor(pred$Land_use,c("Cropland","Grassland","Forest"))

allluc <- ggplot(pred, aes(obs,pred)) + 
  stat_binhex(bins=nbin)+ 
  xlab("Measured SR")+
  ylab("Estimated SR")+
#  labs(title="(a)")+
  geom_abline(slope=1, intercept=0,lty=2)+
  xlim(0,15)+ylim(0,15)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 2^(0:6),colors=viridis(10))
#geom_text(aes(x=-Inf,y=Inf,vjust=1.5,hjust=-0.1),size = 4,
#          label=labraw)
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

tiff("prediction_all.tiff",width=12,height=10,res=500,units="cm")
#grid.arrange(allluc,cropland,grassland,forest)
allluc
dev.off()

tiff("prediction_individuals.tiff",width=17,height=7,res=500,units="cm",
      pointsize = 10)
alllucplot
dev.off()
