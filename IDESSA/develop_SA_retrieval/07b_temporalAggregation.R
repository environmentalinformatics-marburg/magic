#Aggregate spatial predictions
library(raster)

folder_raw <- "/media/memory01/data/IDESSA/Results/Predictions/Rate/"
outdir <- "/media/memory01/data/IDESSA/Results/Predictions/"


aggregationLevels <- c("hour","day","month")

aggregationfolder <- c(folder_raw,paste0(outdir,"agg_",aggregationLevels,"/"))
acc <- 0
for (level in aggregationLevels){
  acc <- acc+1
  setwd(aggregationfolder[acc])
  filelist <- list.files(,pattern=".tif$")
  if(level=="hour"){
    date <- substr(filelist,1,10)
  }
  if(level=="day"){
    date <- substr(filelist,1,8)
  }
  if(level=="month"){
    date <- substr(filelist,1,6)
  }
  dir.create(aggregationfolder[acc+1])
  for (uniqued in unique(date)){
    datestack <- stack(filelist[date==uniqued])
    aggregatedrain <- calc(datestack,sum,na.rm=TRUE)
    writeRaster(aggregatedrain,paste0(aggregationfolder[acc+1],uniqued,".tif"))
  }
}


