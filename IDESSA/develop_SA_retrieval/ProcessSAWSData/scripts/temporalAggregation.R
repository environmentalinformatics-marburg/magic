#### Temporal Aggregation of Climate Station data

station=read.csv("/media/hanna/ubt_kdata_0005/ClimateDataSAWS/perStation/ACS/ALIWAL-NORTH PLAATKOP.csv")
source("/home/hanna/Documents/release/environmentalinformatics-marburg/magic/IDESSA/ProcessSAWSData/functions/tempAgg.R")
date <- do.call( rbind , strsplit( as.character( station$Date ) , " " ) )
date <- data.frame( Date=date[,1] , Time = date[,2], dayY= strptime(date[,1], "%Y/%m/%d")$yday+1 )
station <- cbind(station[,names(station)!="Date"],date)


x=station$Rain
time=data.frame("Date"=station$Date,"Time"=station$Time)
#rename to 00:00 instead of 24:00
levels(time$Time)[levels(time$Time)=="24:00"] <- "00:00"


test=tempAgg(x,time)