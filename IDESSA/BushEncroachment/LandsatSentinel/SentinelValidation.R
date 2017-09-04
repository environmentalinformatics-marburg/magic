load("/home/hanna/Documents/Projects/IDESSA/SentinelClassification/testdata.RData")
load("/home/hanna/Documents/Projects/IDESSA/SentinelClassification/sentinelmodel.RData")
pred <- predict(model,testdata)
regressionStats(tmp,testdata$bush)

dat <- data.frame(pred=pred,obs=testdata$bush)

ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
#  xlim(-10,40)+ylim(-10,40)+
#  xlab("Measured Tair in °C")+
#  ylab("Estimated Tair in °C (cross-validated)")+
  geom_abline(slope=1, intercept=1,lty=2)+
  scale_fill_gradientn(name = "data points", trans = "log", 
                       breaks = 10^(0:4),colors=viridis(10))