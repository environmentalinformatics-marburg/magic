#Aggregate spatial predictions
library(raster)

folder_raw <- "/media/memory01/data/IDESSA/Results/Predictions/Rate/"
outdir <- "/media/memory01/data/IDESSA/Results/Predictions/"


aggregationLevels <- c("day","week","month")
#aggregationLevels <- c("month")

aggregationfolder <- c(folder_raw,paste0(outdir,"agg_",aggregationLevels,"/"))
#acc <- 0
for (level in aggregationLevels){
  print(level)
  #  acc <- acc+1
  if (level=="day"){
    setwd(folder_raw)
    filelist <- list.files(,pattern=".tif$")
  }else{
    setwd(paste0(outdir,"agg_day/"))
    filelist <- list.files(,pattern="._rainsum.tif$")
  }
  if(level=="day"){
    date <- substr(filelist,6,13)
  }
  if(level=="week"){
    date <- as.character(sprintf("%02d",as.numeric(strftime(
      as.POSIXlt(substr(filelist,1,8),format="%Y%m%d") ,format="%W"))+1))
  }
  if(level=="month"){
    date <- substr(filelist,1,6)
  }
  dir.create(outdir,"agg_",level,"/")
  for (uniqued in unique(date)){
    print(uniqued)
    datestack <- stack(filelist[date==uniqued])
    if(nlayers(datestack)<4){next}
    aggregatedrain <- calc(datestack,sum,na.rm=TRUE)
    if (level != "day"){
      values(datestack)[values(datestack)>0] <- 1
      rainy <- calc(datestack,sum,na.rm=TRUE)
    }
    writeRaster(aggregatedrain,paste0(outdir,"agg_",level,"/",uniqued,"_rainsum.tif"),overwrite=TRUE)
    if (level!="day"){
      writeRaster(rainy,paste0(outdir,"agg_",level,"/",uniqued,"_rainydays.tif"),overwrite=TRUE)
    }
  }
}


