#match temporally aggregated (1h) MSG images with station data

rm(list=ls())
lib <- c("raster","doParallel","foreach","Rainfall")
sapply(lib, function(x) require(x, character.only = TRUE))

years <- 2010:2014
datapath <- "/media/memory01/data/IDESSA/Results/ExtractedData/"
outpath <- "/media/memory01/data/IDESSA/Results/ExtractedData/"

for (year in years){
  stationpath <- paste0("/media/memory01/data/IDESSA/statdat/",year,"/")
  MSG_extract <- get(load(paste0(datapath,"ExtractedData_agg_",year,".RData")))
  rslt <- msgstatmatch(stationpath,MSG_extract)
  save(rslt,file=paste0(outpath,"StationMatch_test_",year,".RData"))
}