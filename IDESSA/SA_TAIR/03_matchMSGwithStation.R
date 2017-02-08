#match temporally aggregated (1h) MSG images with station data

rm(list=ls())


msgstatmatch <- function (stationpath,MSG_extract,UTC=0){
  matchfun <- function (i,MSG_extract,stationpath,files,filenames,UTC){
    
    rainfall <- data.frame()
    statdatsub <- MSG_extract[MSG_extract$Station==unique(MSG_extract$Station)[i],]
    statdatsub$date <- as.character(statdatsub$date)
    statdat <- tryCatch(read.csv(paste0(stationpath,"/",
                                        files[which(filenames==unique(MSG_extract$Station)[i])])),
                        error = function(e)e)
    if(inherits(statdat, "error")) {
      print(paste0(unique(MSG_extract$Station)[i]," could not be processed"))
      next
    }
    statdat$datetime <- as.character(statdat$datetime)
    statdat$datetime <- gsub("-", "",statdat$datetime)
    statdat$datetime <- gsub("T", "",statdat$datetime)
    statdat$datetime <- gsub(":", "",statdat$datetime)
#    statdat$datetime <- as.POSIXct(statdat$datetime,format="%Y%m%d%H%M")+3600*(-UTC)
#    statdat$datetime <- as.character(gsub("-","",statdat$datetime))
#    statdat$datetime <- gsub(" ","",statdat$datetime)
#    statdat$datetime <- gsub(":","",statdat$datetime)
#    statdat$datetime <- substr(statdat$datetime,1,12)
    statdat$datetime <- paste0(statdat$datetime,"00")
    
    
    for (k in 1:nrow(statdatsub)){
      if (any(statdatsub$date[k]==statdat$datetime)==FALSE){next}
      if(sum(is.na(data.frame(statdatsub[k,],
                              statdat[statdatsub$date[k]==statdat$datetime,3])[3:13]))==11){next}
      rainfall <- rbind(rainfall,data.frame(statdatsub[k,],
                                            statdat[statdatsub$date[k]==statdat$datetime,3]))
    }
    print(paste0(i, "von ", length(unique(MSG_extract$Station))))
    return(rainfall)
  }
  
  
  
  lib <- c("raster","doParallel","foreach")
  sapply(lib, function(x) require(x, character.only = TRUE))
  crs <- detectCores()-1
  files <- list.files(path=stationpath,pattern=".csv")
  filenames <- substr(files,1,nchar(files)-4)
  names(MSG_extract)[2] <- "Station"
  
  MSG_extract <- MSG_extract[order(MSG_extract$Station, MSG_extract$date),]
  MSG_extract$Station <- as.character(MSG_extract$Station)
  MSG_extract$date <- paste0(MSG_extract$date,"00")
  
  
  
  cl <- makeCluster(crs, outfile = "debug.txt")
  registerDoParallel(cl)
  
  rslt <- foreach(i=1:length(unique(MSG_extract$Station)),.errorhandling = "remove",
                  .packages=lib,.combine = rbind)%dopar%{
                    matchfun(i,MSG_extract,stationpath,files,filenames,UTC=UTC)}
  stopCluster(cl)
  
    names(rslt)[ncol(rslt)]<-"Tair"
  return(rslt)
}


lib <- c("raster","doParallel","foreach","Rainfall")
sapply(lib, function(x) require(x, character.only = TRUE))

years <- 2010:2014
datapath <- "/media/memory01/data/IDESSA/Tair/Results/ExtractedData/"
outpath <- "/media/memory01/data/IDESSA/Tair/Results/ExtractedData/"

for (year in years){
  stationpath <- paste0("/media/memory01/data/IDESSA/Tair/statdat/",year,"/")
  MSG_extract <- get(load(paste0(datapath,"ExtractedData_agg_",year,".RData")))
  rslt <- msgstatmatch(stationpath,MSG_extract,UTC=2)
  save(rslt,file=paste0(outpath,"StationMatch_",year,".RData"))
}