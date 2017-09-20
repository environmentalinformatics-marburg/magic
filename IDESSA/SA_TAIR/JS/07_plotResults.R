library(ggplot2)
library(viridis)

load("model_rf_LLTO.RData")
predictions <- model_rf_LLTO$pred[model_rf_LLTO$pred$mtry==model_rf_LLTO$bestTune$mtry,]
dat <- data.frame(pred=predictions$pred,obs=predictions$obs)

#pdf("validation.pdf",width=5,height=4) #zum ausschreiben als pdf aktivieren
ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
  xlim(-10,40)+ylim(-10,40)+
  xlab("Measured Tair in °C")+
  ylab("Estimated Tair in °C (cross-validated)")+
  geom_abline(slope=1, intercept=1,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:4),colors=viridis(10))
#dev.off() #zum ausschreiben als pdf aktivieren
