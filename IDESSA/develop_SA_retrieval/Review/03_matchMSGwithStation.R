#match temporally aggregated (1h) MSG images with station data

rm(list=ls())
lib <- c("raster","doParallel","foreach","Rainfall")
sapply(lib, function(x) require(x, character.only = TRUE))
source("/home/hmeyer/magic/IDESSA/develop_SA_retrieval/Review/msgstatmatch.R")
years <- 2013
datapath <- "/media/memory01/data/IDESSA/Results/Review/ExtractedData/"
outpath <- "/media/memory01/data/IDESSA/Results/Review/ExtractedData/"

for (year in years){
  stationpath <- paste0("/media/memory01/data/IDESSA/statdat/",year,"/")
  MSG_extract <- get(load(paste0(datapath,"ExtractedData_agg_",year,".RData")))
  rslt <- msgstatmatch(stationpath,MSG_extract,UTC=2)
  save(rslt,file=paste0(outpath,"StationMatch_",year,".RData"))
}
