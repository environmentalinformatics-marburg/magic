mainpath <- "/home/hmeyer/hmeyer/Nele_MIRS/version2/"
datapath <- paste0(mainpath,"data/")
spectrapath <- paste0(datapath,"/Baseline/")
modelpath <- paste0(mainpath,"/modeldata/")
setwd(mainpath)

dattab <- read.table(paste0(datapath,
                            "Ergebnisse_Tabelle2_SR.txt"),
                     header=TRUE)

################################################################################
# Merge data with spectra
################################################################################
spectrafiles <- list.files(spectrapath,pattern=".dpt$")



spectrafile <- spectrafiles[substr(spectrafiles,1,5)==unique(dattab$Labornummer)[1]]
spec <- read.csv(paste0(spectrapath,spectrafile),header=FALSE)
results<-data.frame(matrix(ncol=nrow(spec),nrow=nrow(dattab)))
names(results) <- c(as.character(spec[,1]))

library(plyr)

for (i in unique(dattab$Labornummer)){
  spectrafile <- spectrafiles[substr(spectrafiles,1,5)==i]
  spec <- read.csv(paste0(spectrapath,spectrafile),header=FALSE)
  for (k in which(dattab$Labornummer==i)){
    results[k,1:ncol(results)] <- spec[,2]
  }
#  results[which(dattab$Labornummer==i),1:ncol(dattab)]<-dattab[which(dattab$Labornummer==i),]
}


results <- data.frame(dattab,results)
names(results)[(ncol(dattab)+1):ncol(results)] <- c(as.character(spec[,1]))

save(results,file=paste0(modelpath,"inputtable.RData"))

