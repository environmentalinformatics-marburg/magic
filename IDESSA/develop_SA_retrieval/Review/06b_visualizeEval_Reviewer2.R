# This scripts visualizes the model comparison. Use the results of evaluateModels.R

rm(list=ls())
library(reshape2)
library(latticeExtra)
library(Rsenal)

mainpath <- "/media/hanna/data/CopyFrom181/Results/"
#mainpath <- "/media/hanna/data/CopyFrom181/Results/"
datapath <- paste0(mainpath, "Evaluation/")
#figurepath <- paste0(mainpath,"Figures/")
figurepath <-"/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_SARetrieval/Submission2/Revision/additionals/"

#load(paste0(datapath,"eval_rate.RData"))
#load(paste0(datapath,"eval_area.RData"))
load(paste0(datapath,"evaluationData_all.RData"))
################################################################################
# POD bei untersch. gemessenen Niederschlagsmengen
################################################################################
rainresults <- results_all[results_all$RA_obs=="Rain",]

class1 <- rainresults[rainresults$RR_obs<=0.2,]
class2 <- rainresults[rainresults$RR_obs>0.2&rainresults$RR_obs<=1.6,]
class3 <- rainresults[rainresults$RR_obs>1.6,]

c1 <- classificationStats(class1$RA_pred,class1$RA_obs)$POD
c2 <- classificationStats(class2$RA_pred,class2$RA_obs)$POD
c3 <- classificationStats(class3$RA_pred,class3$RA_obs)$POD

barplot(c(c1,c2,c3))

################################################################################
# FAR bei untersch. predicteten Niederschlagsmengen
################################################################################
rainresults <- results_all[results_all$RA_pred=="Rain",]
class1 <- rainresults[rainresults$RR_pred<=0.2,]
class2 <- rainresults[rainresults$RR_pred>0.2&rainresults$RR_pred<=1.6,]
class3 <- rainresults[rainresults$RR_pred>1.6,]

c1b <- classificationStats(class1$RA_pred,class1$RA_obs)$FAR
c2b <- classificationStats(class2$RA_pred,class2$RA_obs)$FAR
c3b <- classificationStats(class3$RA_pred,class3$RA_obs)$FAR


#dat <- data.frame("value"=c(c1,c2,c3),
#                  "class"=c("<0.2 mm","0.2-1.6 mm",">1.6 mm"),
#                  "Type"= rep("POD",3))
#dat <- rbind(dat,data.frame("value"=c(c1b,c2b,c3b),
#                            "class"=c("<0.2 mm","0.2-1.6 mm",">1.6 mm"),
#                            "Type"= rep("FAR",3)))
#dat$class <- factor(dat$class, levels=c("<0.2 mm","0.2-1.6 mm",">1.6 mm"))

#pdf(paste0(figurepath,"classdependentperf.pdf"),
#    width=6,height=4)
#barchart(class ~ value | Type, data=dat,col="grey40",
#         par.settings = list(strip.background=list(col="grey90")))
#dev.off()

#################################################
#RMSE
#################################################
rainresults <- results_all
rainresults$RR_obs[rainresults$RR_obs>500] <- NA #remove outliers

class1 <- rainresults[rainresults$RR_obs<=0.2,]
class2 <- rainresults[rainresults$RR_obs>0.2&rainresults$RR_obs<=1.6,]
class3 <- rainresults[rainresults$RR_obs>1.6,]

c1c <- regressionStats(class1$RR_pred,class1$RR_obs)$RMSE
c2c <- regressionStats(class2$RR_pred,class2$RR_obs)$RMSE
c3c <- regressionStats(class3$RR_pred,class3$RR_obs)$RMSE


dat <- data.frame("value"=c(c1,c2,c3),
                  "class"=c("<0.2 mm","0.2-1.6 mm",">1.6 mm"),
                  "Type"= rep("POD",3))
dat <- rbind(dat,data.frame("value"=c(c1b,c2b,c3b),
                            "class"=c("<0.2 mm","0.2-1.6 mm",">1.6 mm"),
                            "Type"= rep("FAR",3)))
dat <- rbind(dat,data.frame("value"=c(c1c,c2c,c3c),
                            "class"=c("<0.2 mm","0.2-1.6 mm",">1.6 mm"),
                            "Type"= rep("RMSE",3)))
dat$class <- factor(dat$class, levels=c("<0.2 mm","0.2-1.6 mm",">1.6 mm"))


pdf(paste0(figurepath,"classdependentperf_2.pdf"),
    width=8,height=4)
barchart(class ~ value | Type, scales=list(alternating=T, x=list(relation="free")),data=dat,col="grey40",
         par.settings = list(strip.background=list(col="grey90")))
dev.off()

