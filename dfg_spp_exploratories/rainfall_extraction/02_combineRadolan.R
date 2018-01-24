# this script combines extracted time series of RADOLAN data for each plot 
#in the Exploratories
#Author: Hanna Meyer
#Date: 14.01.2018

rm(list=ls())
RadolanPath <- "/media/hanna/data/RADOLAN/results/"
outpath <- "/home/hanna/Documents/Projects/Exploratories/Radolan/"
files <- list.files(RadolanPath,pattern=".RData$")

result <- list()
for (i in 1:length(files)){
  tmp <- get(load(files[i]))
  result[[i]] <- data.frame(tmp$Date,tmp[,-which(names(tmp)=="Date")])
}
results <- data.frame(do.call("rbind",result))
names(results) <- c("Date",
                    gsub("\\s*\\([^\\)]+\\)","",names(tmp[,-which(names(tmp)=="Date")])))
results[,2:ncol(results)] <- results[,2:ncol(results)]/10
#save(results,file=paste0(outpath,"/RADOLAN.RData.gz"))
write.csv(results,paste0(outpath,"Radolan.csv"))


radolan <- read.csv(paste0(outpath,"Radolan.csv"))
radolan$Date <- strptime(radolan$Date, format="%Y-%m-%d %H:%M")
radolan$Date <- format(round(radolan$Date, units="hours"), format="%Y-%m-%d %H:%M")
radolan <- melt(radolan[,2:ncol(radolan)],id.vars=c("Date"))
save(radolan,file=paste0(outpath,"/radolan_melt.RData"))
