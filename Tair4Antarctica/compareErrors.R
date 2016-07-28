rm(list=ls())
library(Rsenal)
load("/media/hanna/data/Antarctica/results/MLFINAL/model_GBM.RData")
load("/media/hanna/data/Antarctica/results/MLFINAL/dataset.RData")
source("/home/hanna/Documents/release/environmentalinformatics-marburg/magic/IDESSA/comparison_machineLearning/additionalScripts/scriptsForPublication/geom_boxplot_noOutliers.R")

dat <- data.frame(dataset,
                  "pred"=predict(model_GBM,
                          dataset[,which(names(dataset)%in%c("LST","month"))]))
dat <- dat[complete.cases(dat),]
rmse_time <- data.frame()
rmse_month <- data.frame()
rmse_ice <- data.frame()
for (i in 1:length(unique(dat$station))){
  subs <- data.frame("obs"=dat$statdat[dat$station==unique(dat$station)[i]],
                     "pred"=dat$pred[dat$station==unique(dat$station)[i]],
                     "month"=dat$month[dat$station==unique(dat$station)[i]],
                     "ice"=dat$ice[dat$station==unique(dat$station)[i]],
                     "time"=dat$time[dat$station==unique(dat$station)[i]])
  for (k in 1:length(unique(subs$month))){
  rmse_month <- rbind(rmse_month,
                      data.frame("rmse"=regressionStats(subs$pred[subs$month==unique(subs$month)[k]],
                               subs$obs[subs$month==unique(subs$month)[k]])$RMSE,
                               "month"=unique(subs$month)[k]))
  }

  for (k in 1:length(unique(subs$time))){
    rmse_time <- rbind(rmse_time,
                        data.frame("rmse"=regressionStats(subs$pred[subs$time==unique(subs$time)[k]],
                                                          subs$obs[subs$time==unique(subs$time)[k]])$RMSE,
                                   "time"=unique(subs$time)[k]))
  }
  
  rmse_ice[i,1] <- regressionStats(subs$pred,subs$obs)$RMSE
  rmse_ice[i,2] <- unique(subs$ice)

#names(rmse_month)<-unique(subs$month)
}




grd <- data.frame(matrix(nrow=12,ncol=12))
for (i in 1:length(unique(rmse_month$month))){
  if(i==12){next()}
  for (k in (i+1):length(unique(rmse_month$month))){
  grd[i,k] <- round(t.test(rmse_month$rmse[rmse_month$month==unique(rmse_month$month)[i]],
                     rmse_month$rmse[rmse_month$month==unique(rmse_month$month)[k]])$p.value,2)
  }}
colnames(grd) <- unique(rmse_month$month)
rownames(grd) <- unique(rmse_month$month)
write.csv(grd,"/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_Antarctica/Submission2/ReviewII/significance.csv")

t.test(rmse_ice$V1[rmse_ice$V2=="Ice"],
       rmse_ice$V1[rmse_ice$V2=="NoIce"])$p.value



p1 <- ggplot(rmse_ice, aes(x = V2, y = V1))+ 
  xlab("")+ 
  ylab("RMSE (°C)")+
  geom_boxplot(outlier.shape = NA) +
  scale_y_continuous(limits =c(4,20))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))

p2 <- ggplot(rmse_month, aes(x = month, y = rmse))+ 
  xlab("")+ 
  ylab("RMSE (°C)")+
  geom_boxplot(outlier.shape = NA) +
  scale_y_continuous(limits = c(2,25))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))



library(ggplot2)
library(gridExtra)
pdf("/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_Antarctica/Submission2/ReviewII/errorcomp.pdf",
    width=8,height=4)
#grid.arrange(p2b,p2c,p1b,p1c)
grid.arrange(p2,p1,ncol=2)
dev.off()



################################################################################
relErrorK <- function(obs,pred){100*(abs((obs+273.15-pred+273.15)/(obs+273.15)))}

relError <- function(obs,pred){100*(abs((obs-pred)/obs))}

dat$relErr <- relErrorK(dat$statdat,dat$pred)
dat$absError <- abs(dat$statdat-dat$pred)
dat$meanerr <- dat$statdat-dat$pred
levels(dat$ice)<-c("No ice","Ice")






############
p1 <- ggplot(dat, aes(x = ice, y = relErr))+ 
  xlab("")+ 
  ylab("relative error (%)")+
  geom_boxplot(outlier.shape = NA,notch=TRUE) +
  scale_y_continuous(limits = quantile(dat$relErr, c(0.1, 0.9),na.rm=TRUE))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))

p1b <- ggplot(dat, aes(x = ice, y = absError))+ 
  xlab("")+ 
  ylab("absolute error (°C)")+
#  geom_boxplot(outlier.shape = NA,notch=TRUE) +
  geom_boxplot(notch=TRUE) +
#  scale_y_continuous(limits = quantile(dat$absError, c(0.1, 0.9),na.rm=TRUE))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))


p1c <- ggplot(dat, aes(x = ice, y = meanerr))+ 
  xlab("")+ 
  ylab("mean error (°C)")+
  geom_boxplot(outlier.shape = NA,notch=TRUE) +
  scale_y_continuous(limits = quantile(dat$meanerr, c(0.1, 0.9),na.rm=TRUE))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))

p2 <- ggplot(dat, aes(x = month, y = relErr))+ 
  xlab("")+ 
  ylab("relative error (%)")+
  geom_boxplot(outlier.shape = NA,notch=TRUE) +
  scale_y_continuous(limits = quantile(dat$relErr, c(0.1, 0.9),na.rm=TRUE))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))

p2b <- ggplot(dat, aes(x = month, y = absError))+ 
  xlab("")+ 
  ylab("absolute error (°C)")+
#  geom_boxplot(outlier.shape = NA,notch=TRUE)+
  geom_boxplot(notch=TRUE)+
#  scale_y_continuous(limits = c(0, 35))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))

p2c <- ggplot(dat, aes(x = month, y = meanerr))+ 
  xlab("")+ 
  ylab("mean error (°C)")+
  geom_boxplot(outlier.shape = NA,notch=TRUE)+
  scale_y_continuous(limits = c(0, 35))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))

library(ggplot2)
library(gridExtra)
pdf("/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_Antarctica/Submission2/Review/errorcomp.pdf",
    width=8,height=4)
#grid.arrange(p2b,p2c,p1b,p1c)
grid.arrange(p2b,p1b,ncol=2)
dev.off()

statagg <- aggregate(data.frame(dat$relErr,dat$absError),
                     by=list(dat$station),FUN=median)
rmse <- data.frame()
for (i in unique(dat$station)){
  subs <- dat[dat$station==i,]
  rmse <- rbind(rmse, data.frame("station"=i,"RMSE"=
                                 regressionStats(subs$pred,
                                      subs$statdat)$RMSE))
  }

statloc <- readOGR("/media/hanna/data/Antarctica/data/ShapeLayers/StationsFinal.shp",
                   "StationsFinal")
statloc@data$Name <- gsub("([.])", "", statloc@data$Name)
statloc@data$Name <- gsub("([ ])", "", statloc@data$Name)

#statloc<-merge(statloc,statagg,by.x="Name",
#               by.y="Group.1")
statloc<-merge(statloc,rmse,by.x="Name",
                              by.y="station")
writeOGR(statloc, "/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_Antarctica/Submission2/Review/",
         "statloc_b", driver="ESRI Shapefile")
#############################################

sts_rel <- boxplot.stats(dat$relErr)$stats
sts_abs <- boxplot.stats(dat$absError)$stats
comp <- data.frame("VALUE"=c(dat$relErr[dat$relErr>sts_rel[1]&dat$relErr<sts_rel[5]],
                             dat$absError[dat$absErr>sts_abs[1]&dat$absErr<sts_abs[5]]),
                   "SCORE"=c(rep("relative error",nrow(dat[dat$relErr>sts_rel[1]&dat$relErr<sts_rel[5],])),
                             rep("absolute error",nrow(dat[dat$absErr>sts_abs[1]&dat$absErr<sts_abs[5],]))),
                   "Month"=c(as.character(dat$month[dat$relErr>sts_rel[1]&dat$relErr<sts_rel[5]]),
                             as.character(dat$month[dat$absErr>sts_abs[1]&dat$absErr<sts_abs[5]])))

#comp <- rbind(comp,comp)
comp$ICE<-factor(as.character(c(as.character(dat$ice[dat$relErr>sts_rel[1]&dat$relErr<sts_rel[5]]),
                                as.character(dat$ice[dat$absErr>sts_abs[1]&dat$absErr<sts_abs[5]]))))
levels(comp$ICE)<-c("Ice","Dry Valleys")
comp$Month <- factor(comp$Month,levels=c("Jan","Feb","Mar","Apr","Mai",
                                         "Jun","Jul","Aug","Sep","Oct",
                                         "Nov","Dec"))                

p1 <- ggplot(comp, aes(x = Month, y = VALUE))+ 
  geom_boxplot(outlier.shape = NA,notch=TRUE) +
  theme_bw()+
  xlab("")+ 
  ylab("")+
  facet_grid(SCORE~.,scales = "free")

p2 <- ggplot(comp, aes(x = ICE, y = VALUE))+ 
  geom_boxplot(outlier.shape = NA,notch=TRUE) +
  theme_bw()+
  xlab("")+ 
  ylab("")+
  facet_grid(SCORE~.,scales = "free")+
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust=1))


#library(ggplot2)
#pdf("/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_Antarctica/Submission2/Review/errorcomp.pdf")
#grid.arrange(p1,p2,nrow=1)
#dev.off()




