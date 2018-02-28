#06_mergeWithDendro
#script merges Predictors and Dendro data

rm(list=ls())
library(lubridate)
library(dplR)
mainpath <- "/home/hanna/Documents/Projects/Dendrodaten/"
dendropath <- paste0(mainpath, "/data/dendrodata/")
predpath <- paste0(mainpath, "/data/T_Prec_basedata/")

dataset <- get(load(paste0(predpath,"/predictors.RData")))
################################################################################
# Initialize Target dataset: for each year and each tree the corresponding 
# predictors
################################################################################

#dendro <- aggregate(dataset$Dendro_year,by=list(dataset$tree,dataset$year),
#                    "mean",na.rm=T)

dendrodats <- list.files(dendropath,pattern="rwl$",full.names = TRUE)
predictors <- list()
for (i in 1:length(dendrodats)){
  dendrodat <- read.rwl(dendrodats[i])
  plotname <- substr(dendrodats[i],nchar(dendrodats[i])-9,nchar(dendrodats[i])-4)
  
  predictors[[i]] <- do.call(rbind, replicate(ncol(dendrodat), 
                                              dataset[dataset$Plot==plotname,], 
                                              simplify=FALSE))
  predictors[[i]]$Tree <- rep(names(dendrodat),
                              each=nrow(predictors[[i]])/ncol(dendrodat))
  
  dendrodat$years <- row.names(dendrodat)
  dendrodat <- melt(dendrodat)
  
  predictors[[i]] <- merge(predictors[[i]],dendrodat,
                           by.x=c("Tree","Year"),
                           by.y=c("variable","years"))
}
datamerged_all <- do.call(rbind,predictors)
names(datamerged_all)[names(datamerged_all)=="value"] <- "Dendro"
datamerged_all <- datamerged_all[complete.cases(datamerged_all),]
save(datamerged_all,file=paste0(predpath,"predictorsDendroMerged.RData"))

