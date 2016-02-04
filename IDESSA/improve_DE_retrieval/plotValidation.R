###analyze overall model performance (not on scene basis)
library(lattice)
library(ggplot2)
library(grid)
library(proto)
source("geom_boxplot_noOutliers.R")


resultpath="/media/hanna/ubt_kdata_0005/improve_DE_retrieval/"
load(paste0(resultpath,"globalComp_validation.RData"))
load(paste0(resultpath,"globalComp_training.RData"))
load(paste0(resultpath,"evaluation_training_day_Rain.Rdata"))
load(paste0(resultpath,"evaluation_validation_day_Rain.Rdata"))

ddf_valid<-data.frame("pred"=comp_validation$pred,"obs"=comp_validation$obs)
ddf_training<-data.frame("pred"=comp_training$pred,"obs"=comp_training$obs)

model_valid<-lm(ddf_valid$obs~ddf_valid$pred)
model_training<-lm(ddf_training$obs~ddf_training$pred)

pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/globalComp.pdf")

xyplot(pred ~ obs, ddf_valid, grid=T, xlim=c(0,15),ylim=c(0,15),
       panel=function(...){
  panel.smoothScatter(nbin = 500, cuts = 1000, 
                      colramp = colorRampPalette(c(
                        "white","blue","green","yellow","red")), ...)
  panel.lmline(...)
  panel.text(13,14.5,labels=paste0("Rsq= ", round(summary(
    model_valid)$r.squared,2)),cex=1.5)
})

xyplot(pred ~ obs, ddf_training, grid=T, xlim=c(0,15),ylim=c(0,15),
       panel=function(...){
  panel.smoothScatter(nbin = 500, cuts = 1000, 
                      colramp = colorRampPalette(c(
                        "white","blue","green","yellow","red")), ...)
  panel.lmline(...)
  panel.text(13,14.5,labels=paste0("Rsq= ", round(summary(
    model_training)$r.squared,2)),cex=1.5)
})
dev.off()

####on scene basis


#boxplot(evaluation_training$Rsq,evaluation_validation$Rsq,ylab="Rsq",
#        names=c("training","validation"))
#boxplot(evaluation_training$RMSE,evaluation_validation$RMSE,ylim=c(0,4),
#        ylab="RMSE",names=c("training","validation"))
valid<-data.frame(rbind(evaluation_training,evaluation_validation))
valid$type <- factor(c(rep("training",nrow(evaluation_training)),
                       rep("validation",nrow(evaluation_validation))))
valid$season <- NA
valid$season[substr(valid$scene,5,6)%in%c("05","06","07","08","09")]="summer"
valid$season[!substr(valid$scene,5,6)%in%c("05","06","07","08","09")]="winter"

valid<-rbind(cbind(valid,"value"=valid$Rsq,"score"=rep("Rsq",nrow(valid))),
             cbind(valid,"value"=valid$RMSE,"score"=rep("RMSE",nrow(valid)))#,
            # cbind(valid,"value"=valid$ME,"score"=rep("ME",nrow(valid))),
            # cbind(valid,"value"=valid$MAE,"score"=rep("MAE",nrow(valid)))
             )
valid<-valid[,9:12]


number_ticks <- function(n) {function(limits) pretty(limits, n)}

pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/Comp_tr_valid.pdf",
    width=4,height=7)
ggplot(valid, aes(x = type, y = value))+ 
  geom_boxplot_noOutliers(outlier.size = NA) +
  theme_bw()+
  scale_y_continuous(breaks=number_ticks(5))+
  facet_grid(score ~ .,scales = "free")+
  xlab("") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=14),
        panel.margin = unit(0.7, "lines"))
dev.off()


pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/Comp_season.pdf",
    width=4,height=7)
ggplot(valid, aes(x = season, y = value))+ 
  geom_boxplot_noOutliers(outlier.size = NA) +
  theme_bw()+
  scale_y_continuous(breaks=number_ticks(5))+
  facet_grid(score ~ .,scales = "free")+
  xlab("") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=14),
        panel.margin = unit(0.7, "lines"))
dev.off()







################################################################################
#Comparison
################################################################################
resultpath<-"/media/hanna/ubt_kdata_0005/improve_DE_retrieval/copy183/results/validation/"

load(paste0(resultpath,"evaluation_validation_oneSE_day_Rain.Rdata"))
evaluation_val_onese <- evaluation_validation
load(paste0(resultpath,"evaluation_validation_day_RainOnlySpectral.Rdata"))
evaluation_spectral <- evaluation_validation
load(paste0(resultpath,"evaluation_validation_day_RainSpectralPlus.Rdata"))
evaluation_spectralPlus <- evaluation_validation
load(paste0(resultpath,"evaluation_validation_day_RainSpectral+Szen.Rdata"))
evaluation_spectralPlusSzen <- evaluation_validation
load(paste0(resultpath,"evaluation_validation_day_RainonlyChannels.Rdata"))
evaluation_onlyChannels <- evaluation_validation
load(paste0(resultpath,"evaluation_validation_day_Rainmean.Rdata"))
evaluation_mean <- evaluation_validation
evaluation_mean$Rsq<-NA
load(paste0(resultpath,"evaluation_validation_day_Rain.Rdata"))

valid<-data.frame(rbind(evaluation_validation,
                        evaluation_val_onese,
                        evaluation_spectral,
                        evaluation_spectralPlus,
                        evaluation_spectralPlusSzen,
                        evaluation_onlyChannels,
                        evaluation_mean))
valid$type <- factor(c(rep("best Fit",nrow(evaluation_validation)),
                       rep("within one SE",nrow(evaluation_val_onese)),
                       rep("only Spectral",nrow(evaluation_spectral)),
                       rep("Spectral+jday&Szen",nrow(evaluation_spectralPlus)),
                       rep("Spectral+Szen",nrow(evaluation_spectralPlusSzen)),
                       rep("only Channels",nrow(evaluation_onlyChannels)),
                       rep("mean",nrow(evaluation_mean))
                       ),levels=c("best Fit", "within one SE", "only Spectral", 
                                  "Spectral+jday&Szen","Spectral+Szen",
                                  "only Channels","mean"))

valid<-rbind(cbind(valid,"value"=valid$Rsq,"score"=rep("Rsq",nrow(valid))),
             cbind(valid,"value"=valid$RMSE,"score"=rep("RMSE",nrow(valid)))#,
             # cbind(valid,"value"=valid$ME,"score"=rep("ME",nrow(valid))),
             # cbind(valid,"value"=valid$MAE,"score"=rep("MAE",nrow(valid)))
)
valid<-valid[,8:10]



pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/ComparisonModels.pdf",
    width=9.5,height=8)
ggplot(valid, aes(x = type, y = value))+ 
  geom_boxplot_noOutliers(outlier.size = NA) +
  theme_bw()+
  facet_grid(score ~ .,scales = "free")+
  xlab("") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=10),
        panel.margin = unit(0.7, "lines"))
dev.off()


