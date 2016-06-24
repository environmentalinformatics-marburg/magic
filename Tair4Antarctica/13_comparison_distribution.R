library(Rsenal)
setwd("/media/hanna/data/Antarctica/results/MLFINAL/")
load("dataset.RData")
load("trainData.RData")
load("testData.RData")
load("model_GBM.RData")
dataset$pred<-predict(model_GBM,data.frame("LST"=dataset$LST,month=dataset$month))

min(dataset$statdat,na.rm=T)
max(dataset$statdat,na.rm=T)
mean(dataset$statdat,na.rm=T)
sd(dataset$statdat,na.rm=T)


#boxplot(dataset$statdat,dataset$pred,ylab="Tair (°C)")

Comparison<-data.frame("Value"=c(dataset$statdat,dataset$pred),
                       "Score"=c(rep("Observed",nrow(dataset)),
                                 rep("Predicted",nrow(dataset))))
pdf("/media/hanna/data/Antarctica/visualizations/descriptive.pdf",width=5,height=5.5)
ggplot(Comparison, aes(x = Score, y = Value))+ 
#  geom_boxplot(outlier.size = 0.4,notch=F) +
  geom_violin()+
  geom_boxplot(width=0.1)+
  #facet_grid(Score~., scales = "free")+
 # facet_wrap(~Score , ncol = 2, scales = "free")+
  xlab("") + ylab("Tair (°C)")+
  theme(legend.title = element_text(size=12, face="bold"),
        legend.text = element_text(size = 12),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 12),
        strip.text.x = element_text(size = 12),
        axis.text=element_text(size=12),
        panel.margin = unit(1, "lines"))
dev.off()


compareDistributions(dataset$statdat,dataset$pred,ylab="Tair(°C)",
                     clrs=c("grey30","grey60"))


pdf("/media/hanna/data/Antarctica/visualizations/descriptive.pdf",width=5,height=5.5)
ggplot(Comparison, aes(x = Score, y = Value))+ 
  #  geom_boxplot(outlier.size = 0.4,notch=F) +
#  geom_violin()+
  geom_boxplot(,notch=TRUE)+
  theme_bw()+
  #facet_grid(Score~., scales = "free")+
  # facet_wrap(~Score , ncol = 2, scales = "free")+
  xlab("") + ylab("Tair (°C)")+
  theme(legend.title = element_text(size=12, face="bold"),
        legend.text = element_text(size = 12),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 12),
        strip.text.x = element_text(size = 12),
        axis.text=element_text(size=12),
        panel.margin = unit(1, "lines"))
dev.off()
