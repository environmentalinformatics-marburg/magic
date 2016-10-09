library(hsdar)
load("/home/hanna/Documents/Presentations/PaDeMoS Paper/data/Speclib20112012.RData")
Speclib_all<-speclib(spectra=Speclib_all$spectra,wavelength=Speclib_all$wavelength,attributes=Speclib_all$attributes)

setwd("/home/hanna/Documents/Presentations/PaDeMoS Paper/results/nri/")


files <- list.files()
nriData <- lapply(files,function(x) get(load(x)))
featureFrame=list()
for (l in 1:length(nriData)){
featureFrame[[l]]<-data.frame(matrix(nrow=nriData[[l]]@nri@nlyr))
for (i in 2:(nriData[[l]]@nri@ncol)){
  for (k in 1:(i-1)){
    featureName <- paste0(nriData[[l]]@dimnames$Band_1[i],"_",nriData[[l]]@dimnames$Band_2[k])
    featureFrame[[l]] <- data.frame(featureFrame[[l]],nriData[[l]]@nri[i,k])
    names(featureFrame[[l]])[ncol(featureFrame[[l]])]=featureName
    print(featureName)
  }
}
featureFrame[[l]]<-featureFrame[[l]][,-1]
}

names(featureFrame)<-substr(files,5,6)
featureFrame$attributes <- attribute(Speclib_all)

save(featureFrame,file="/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/FeatureFrame.RData")





TrId <- createDataPartition(featureFrame$attributes$VegCover, list = FALSE, p=0.75)
TrainData <- lapply(featureFrame,function(x) x[TrId,])
TestData <- lapply(featureFrame,function(x) x[-TrId,])
save(TrainData,file="/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/TrainData.RData")
save(TestData,file="/home/hanna/Documents/Presentations/PaDeMoS Paper/results/trainData/TestData.RData")
