rm(list=ls())
mainpath <- "/home/hmeyer/hmeyer/Nele_MIRS/version2/"
datapath <- paste0(mainpath,"data/")
spectrapath <- paste0(datapath,"/Baseline/")
modelpath <- paste0(mainpath,"/modeldata/")
setwd(mainpath)

library(hsdar)

inputdat <- get(load(paste0(modelpath,"inputtable.RData")))

dontkeep <- which((as.numeric(names(inputdat)[6:ncol(inputdat)])>4000)==TRUE)+5
inputdat <- inputdat[,-dontkeep]

inputdat[,6:ncol(inputdat)] <- inputdat[,6:ncol(inputdat)][, rev(seq_len(ncol(inputdat[,6:ncol(inputdat)])))]

names(inputdat)[6:ncol(inputdat)] <- rev(names(inputdat)[6:ncol(inputdat)])

names(inputdat)[6:ncol(inputdat)] <- as.character(round(as.numeric(names(inputdat)[6:ncol(inputdat)]),0))

inputdat <- inputdat[complete.cases(inputdat),]

specci <- speclib(as.matrix(inputdat[,6:ncol(inputdat)]), 
                  wavelength=as.numeric(names(inputdat)[6:ncol(inputdat)]))
attribute(specci) <- inputdat[,1:5]



save(specci,file=paste0(modelpath,"specLib.RData"))


