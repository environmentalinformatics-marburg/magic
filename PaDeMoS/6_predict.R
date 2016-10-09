#Prediction


setwd("/home/hanna/Documents/Presentations/Paper/PaDeMoS Paper/data/")
load("Speclib20112012.RData")
load("sat_data_points.RData.gz")
load("/home/hanna/Dropbox/paper_biomasse/aktuelles/rfeModel_Biomass.RData")
load("/home/hanna/Dropbox/paper_biomasse/aktuelles/rfeModel_Vegcover.RData")
load("/home/hanna/Documents/Presentations/Paper/PaDeMoS Paper/results/trainData/FeatureFrame.RData")

library(hsdar)
library(caret)
library(randomForest)
################################################################################
####################PREDICT ON SAT VALUES
################################################################################

Speclib_QB_sat<- Speclib_all$attributes[albedo_vals[[1]][,1],]
Speclib_RE_sat<- Speclib_all$attributes[albedo_vals[[2]][,1],]
Speclib_WV_sat<- Speclib_all$attributes[albedo_vals[[3]][,1],]

Speclib_QB_sat<-speclib(as.matrix(albedo_vals[[1]][,-1]),wavelength=c(485,560,660,830),attributes=Speclib_QB_sat, fwhm = c(70 , 80,  60 ,140))
Speclib_RE_sat<-speclib(as.matrix(albedo_vals[[2]][,-1]),wavelength=c(475.0,555.0,657.5,710.0,805.0),attributes=Speclib_RE_sat, fwhm = c(70, 70 ,55 ,40 ,90))
Speclib_WV_sat<-speclib(as.matrix(albedo_vals[[3]][,-1]),wavelength=c(427,478,546,608,659,724,831,908),attributes=Speclib_WV_sat, fwhm = c(52,  60 , 70 , 38  ,60 , 40 ,118 , 92))

NBI_QB_sat<-nri(Speclib_QB_sat,recursive=TRUE)
NBI_RE_sat<-nri(Speclib_RE_sat,recursive=TRUE)
NBI_WV_sat<-nri(Speclib_WV_sat,recursive=TRUE)

nriData <- list(NBI_QB_sat,NBI_RE_sat,NBI_WV_sat)
PredictionFrame=list()
for (l in 1:length(nriData)){
  PredictionFrame[[l]]<-data.frame(matrix(nrow=nriData[[l]]@nri@nlyr))
  for (i in 2:(nriData[[l]]@nri@ncol)){
    for (k in 1:(i-1)){
      featureName <- paste0(nriData[[l]]@dimnames$Band_1[i],"_",nriData[[l]]@dimnames$Band_2[k])
      PredictionFrame[[l]] <- data.frame(PredictionFrame[[l]],nriData[[l]]@nri[i,k])
      names(PredictionFrame[[l]])[ncol(PredictionFrame[[l]])]=featureName
      print(featureName)
    }
  }
  PredictionFrame[[l]]<-PredictionFrame[[l]][,-1]
}
names(PredictionFrame)<-c("QB","RE","WV")

PredictionFrame[[1]] <-data.frame( PredictionFrame[[1]],attribute(Speclib_QB_sat))
PredictionFrame[[2]] <-data.frame( PredictionFrame[[2]],attribute(Speclib_RE_sat))
PredictionFrame[[3]] <-data.frame( PredictionFrame[[3]],attribute(Speclib_WV_sat))


predicted_sat=list()
for (i in 1:3){
  if (any(names(PredictionFrame[[i]])=="VegType")){
    PredictionFrame[[i]]$VegType<-as.factor(PredictionFrame[[i]]$VegType)
  }
  predicted_sat[[i]]=data.frame("VegCoverPred"=predict(rfeModel_Vegcover[[i+1]],
                                                       PredictionFrame[[i]]),
                                "VegCoverObs"=PredictionFrame[[i]]$VegCover,
                                "BiomassPred"=predict(rfeModel_Biomass[[i+1]],
                                                      PredictionFrame[[i]]),
                                "BionmassObs"=PredictionFrame[[i]]$biomass)
}


################################################################################
####################PREDICT ON SIMULATED VALUES
################################################################################
features_QB<- data.frame(featureFrame[[2]][albedo_vals[[1]][,1],],
                         attribute(Speclib_QB_sat))
features_RE<- data.frame(featureFrame[[3]][albedo_vals[[2]][,1],],
                         attribute(Speclib_RE_sat))
features_WV<- data.frame(featureFrame[[4]][albedo_vals[[3]][,1],],
                         attribute(Speclib_WV_sat))

PredictionFrame_sim=list(features_QB,features_RE,features_WV)


predicted_sim=list()
for (i in 1:3){
  if (any(names(PredictionFrame_sim[[i]])=="VegType")){
    PredictionFrame_sim[[i]]$VegType<-as.factor(PredictionFrame_sim[[i]]$VegType)
  }
  predicted_sim[[i]]=data.frame("VegCoverPred"=predict(rfeModel_Vegcover[[i+1]],
                                                       PredictionFrame_sim[[i]]),
                                "VegCoverObs"=PredictionFrame_sim[[i]]$VegCover,
                                "BiomassPred"=predict(rfeModel_Biomass[[i+1]],
                                                       PredictionFrame_sim[[i]]),
                                "BionmassObs"=PredictionFrame_sim[[i]]$biomass)
}

sim<-rbind(predicted_sim[[1]],predicted_sim[[2]],predicted_sim[[3]])
sat<-rbind(predicted_sat[[1]],predicted_sat[[2]],predicted_sat[[3]])
##############################################################################
##############################################################################
################################################################################
####################PLOT
################################################################################
##############################################################################
##############################################################################
pdf("/home/hanna/Documents/Presentations/PaDeMoS Paper/manuscript/figures/validation_vegcover.pdf",
    width=9,height=8)
par(mfrow=c(2,2),oma=c(0,0,0,0),mar=c(5,5,0.5,0.5))
lmsim<-lm(sim$VegCoverPred~sim$VegCoverObs)
lmsat<-lm(sat$VegCoverPred~sat$VegCoverObs)
plot(sim$VegCoverPred~sim$VegCoverObs,pch=16,col="grey30",
     xlab="Observed",ylab="Predicted",xlim=c(0,100),ylim=c(0,100))
points(sat$VegCoverPred~sat$VegCoverObs,col="grey60",pch=16)
abline(0,1, col = "black",lwd=2)
legend("topleft",pch=c(16,16),col=c("grey30","grey60"),legend=
        c(paste0("R² = ", round(summary(lmsim)$r.squared,3)),
       paste0("R² = ", round(summary(lmsat)$r.squared,3))),bg="white")



lmsim<-lm(predicted_sim[[1]]$VegCoverPred~predicted_sim[[1]]$VegCoverObs)
lmsat<-lm(predicted_sat[[1]]$VegCoverPred~predicted_sat[[1]]$VegCoverObs)
plot(predicted_sim[[1]]$VegCoverPred~predicted_sim[[1]]$VegCoverObs,pch=16,
     col="grey30",xlab="Observed",ylab="Predicted",xlim=c(0,100),ylim=c(0,100))
points(predicted_sat[[1]]$VegCoverPred~predicted_sat[[1]]$VegCoverObs,
       col="grey60",pch=16)
abline(0,1, col = "black",lwd=2)
legend("topleft",pch=c(16,16),col=c("grey30","grey60"),legend=
         c(paste0("R² = ", round(summary(lmsim)$r.squared,3)),
           paste0("R² = ", round(summary(lmsat)$r.squared,3))),bg="white")



lmsim<-lm(predicted_sim[[2]]$VegCoverPred~predicted_sim[[2]]$VegCoverObs)
lmsat<-lm(predicted_sat[[2]]$VegCoverPred~predicted_sat[[2]]$VegCoverObs)
plot(predicted_sim[[2]]$VegCoverPred~predicted_sim[[2]]$VegCoverObs,
     pch=16,col="grey30",xlab="Observed",ylab="Predicted",xlim=c(0,100),ylim=c(0,100))
points(predicted_sat[[2]]$VegCoverPred~predicted_sat[[2]]$VegCoverObs,col="grey60",pch=16)
abline(0,1, col = "black",lwd=2)
legend("topleft",pch=c(16,16),col=c("grey30","grey60"),legend=
         c(paste0("R² = ", round(summary(lmsim)$r.squared,3)),
           paste0("R² = ", round(summary(lmsat)$r.squared,3))),bg="white")

lmsim<-lm(predicted_sim[[3]]$VegCoverPred~predicted_sim[[3]]$VegCoverObs)
lmsat<-lm(predicted_sat[[3]]$VegCoverPred~predicted_sat[[3]]$VegCoverObs)
plot(predicted_sim[[3]]$VegCoverPred~predicted_sim[[3]]$VegCoverObs,
     pch=16,col="grey30",xlab="Observed",ylab="Predicted",xlim=c(0,100),ylim=c(0,100))
points(predicted_sat[[3]]$VegCoverPred~predicted_sat[[3]]$VegCoverObs,col="grey60",pch=16)
abline(0,1, col = "black",lwd=2)
legend("topleft",pch=c(16,16),col=c("grey30","grey60"),legend=
         c(paste0("R² = ", round(summary(lmsim)$r.squared,3)),
           paste0("R² = ", round(summary(lmsat)$r.squared,3))),bg="white")
dev.off()

##############################################################################
##############################################################################
##############################################################################
##############################################################################





pdf("/home/hanna/Documents/Presentations/PaDeMoS Paper/manuscript/figures/validation_biomass.pdf",
    width=6,height=5.5)
lmsim<-lm(sim$BiomassPred~sim$BionmassObs)
lmsat<-lm(sat$BiomassPred~sat$BionmassObs)
plot(sim$BiomassPred~sim$BionmassObs,pch=16,col="grey30",
     xlab="Observed",ylab="Predicted",xlim=c(0,100),ylim=c(0,100))
points(sat$BiomassPred~sat$BionmassObs,col="grey60",pch=16)
abline(0,1, col = "black",lwd=2)
legend("topleft",pch=c(16,16),col=c("grey30","grey60"),legend=
         c(paste0("R² = ", round(summary(lmsim)$r.squared,3)),
           paste0("R² = ", round(summary(lmsat)$r.squared,3))),bg="white")
dev.off()
