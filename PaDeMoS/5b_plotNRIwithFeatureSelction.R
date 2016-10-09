library(randomForest)
library(hsdar)
library(caret)

###plot nri and feature selction

##load rfe model and find best performing bands
load("/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/rfeModel_Biomass.RData")
load("/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/rfeModel_Vegcover.RData")



imp<-list()
for (i in 1:length(rfeModel_Biomass)){
  tmp1<-importance(rfeModel_Biomass[[i]]$fit)
  tmp1<- data.frame("names"=row.names(data.frame(tmp1)),"value"=as.numeric(tmp1))
  tmp1<-tmp1[order(tmp1[,2],decreasing=TRUE),] 
  if (nrow(tmp1)>=35){
    tmp<-tmp1[1:100,]
  }else{
    tmp<-tmp1
  }
  if (any(tmp[,1]=="VegType")){
    tmp<- tmp[-which(tmp[,1]=="VegType"),]
  }
  if (any(tmp[,1]=="VegCover")){
    tmp<- tmp[-which(tmp[,1]=="VegCover"),]
  }
  if(i!=1&i!=3){
    imp[[i]]<-data.frame("band1"=as.numeric(substr(tmp[,1],3,5)),
                         "band2"=as.numeric(substr(tmp[,1],9,11)))
  }
  if(i==1){
    imp[[i]]<-data.frame("band1"=as.numeric(substr(tmp[,1],3,7)),
                         "band2"=as.numeric(substr(tmp[,1],11,15)))
  }
  if(i==3){
    imp[[i]]<-data.frame("band1"=as.numeric(substr(tmp[,1],3,5)),
                         "band2"=as.numeric(substr(tmp[,1],9,13)))
  }
}


##load lmnri data

setwd("/home/hanna/Documents/Presentations/PaDeMoS Paper/results/LMnri/")
load("LM_NRI_Bio_All.RData")
load("LM_NRI_Bio_WV.RData")
load("LM_NRI_Bio_QB.RData")
load("LM_NRI_Bio_RE.RData")

lmnridata<-list(lm_nri_Bio_All,lm_nri_Bio_QB,lm_nri_Bio_RE,lm_nri_Bio_WV)
##draw polygons around best performing bands

pdf("/home/hanna/Documents/Presentations/PaDeMoS Paper/manuscript/figures/rfeResults_Bio.pdf",
    width=8,height=7)
par(mfrow=c(2,2),oma=c(0,0,0,0),mar=c(5,5,0.5,0.5))
for (i in 1:length(imp)){
  range.of.wavelength <- lmnridata[[i]]@fwhm
  indices <- imp[[i]]
  plot(lmnridata[[i]],range=c(0,1))
  lwd=3
  if(i==1){lwd=1}
  for (k in 1:nrow(indices)) {
    Rangex <-  range.of.wavelength [which(lmnridata[[i]]@wavelength == 
                                            indices[k, 2])]
    Rangey <-  range.of.wavelength [which(lmnridata[[i]]@wavelength == 
                                            indices[k, 1])]
    polygon(c(indices[k, 1] + Rangey/2, 
              indices[k, 1] - Rangey/2, 
              indices[k, 1] - Rangey/2, 
              indices[k, 1] + Rangey/2),
            c(indices[k, 2] - Rangex/2, 
              indices[k, 2] - Rangex/2, 
              indices[k, 2] + Rangex/2, 
              indices[k, 2] + Rangex/2),
            lwd=lwd,border="red")
  }
}
dev.off()

################################################################################
################################################################################
################################################################################
rm(list=ls())
##load rfe model and find best performing bands
load("/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/rfeModel_Vegcover.RData")


imp<-list()
for (i in 1:length(rfeModel_Vegcover)){
  tmp1<-importance(rfeModel_Vegcover[[i]]$fit)
  tmp1<- data.frame("names"=row.names(data.frame(tmp1)),"value"=as.numeric(tmp1))
  tmp1<-tmp1[order(tmp1[,2],decreasing=TRUE),] 
  if (nrow(tmp1)>=35){
    tmp<-tmp1[1:100,]
  }else{
    tmp<-tmp1
  }
  if (any(tmp[,1]=="VegType")){
    tmp<- tmp[-which(tmp[,1]=="VegType"),]
  }
  if(i!=1&i!=3){
    imp[[i]]<-data.frame("band1"=as.numeric(substr(tmp[,1],3,5)),
                         "band2"=as.numeric(substr(tmp[,1],9,11)))
  }
  if(i==1){
    imp[[i]]<-data.frame("band1"=as.numeric(substr(tmp[,1],3,7)),
                         "band2"=as.numeric(substr(tmp[,1],11,15)))
  }
  if(i==3){
    imp[[i]]<-data.frame("band1"=as.numeric(substr(tmp[,1],3,5)),
                         "band2"=as.numeric(substr(tmp[,1],9,13)))
    imp[[i]][4,1]<-657.5 #achtung! manuell
    imp[[i]][4,2]<-555
    imp[[i]][10,1]<-657.5
    imp[[i]][10,2]<-475
  }
}


##load lmnri data

setwd("/home/hanna/Documents/Presentations/PaDeMoS Paper/results/LMnri/")
load("LM_NRI_Veg_All.RData")
load("LM_NRI_Veg_WV.RData")
load("LM_NRI_Veg_QB.RData")
load("LM_NRI_Veg_RE.RData")

lmnridata<-list(lm_nri_Veg_All,lm_nri_Veg_QB,lm_nri_Veg_RE,lm_nri_Veg_WV)
##draw polygons around best performing bands

pdf("/home/hanna/Documents/Presentations/PaDeMoS Paper/manuscript/figures/rfeResults_VegCover.pdf",
    width=8,height=7)
par(mfrow=c(2,2),oma=c(0,0,0,0),mar=c(5,5,0.5,0.5))
for (i in 1:length(imp)){
  range.of.wavelength <- lmnridata[[i]]@fwhm
  indices <- imp[[i]]
  plot(lmnridata[[i]],range=c(0,1))
  lwd=3
  if(i==1){lwd=1}
  for (k in 1:nrow(indices)) {
    Rangex <-  range.of.wavelength [which(lmnridata[[i]]@wavelength == 
                                            indices[k, 2])]
    Rangey <-  range.of.wavelength [which(lmnridata[[i]]@wavelength == 
                                            indices[k, 1])]
    polygon(c(indices[k, 1] + Rangey/2, 
              indices[k, 1] - Rangey/2, 
              indices[k, 1] - Rangey/2, 
              indices[k, 1] + Rangey/2),
            c(indices[k, 2] - Rangex/2, 
              indices[k, 2] - Rangex/2, 
              indices[k, 2] + Rangex/2, 
              indices[k, 2] + Rangex/2),
            lwd=lwd,border="red")
  }
}
dev.off()
