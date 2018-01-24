#02 extractMSWEP
rm(list=ls())
library(raster)
mainpath <- "/media/hanna/data/MSWEP/"
datapath <- paste0(mainpath,"/raw/")
outpath <- paste0(mainpath,"/MSWEP_processed/")
tmppath <- paste0(mainpath,"/tmp/")

rasterOptions(tmpdir = tmppath)

locations <- read.csv("/home/hanna/Documents/Projects/Dendrodaten/coordinates/Koordinaten.csv")
locations <- SpatialPointsDataFrame(locations[,c(3,2)],data=data.frame(locations$X),
                                    proj4string = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))

years <- 2000:2016

files <- list.files(datapath,pattern="nc$",full.names = TRUE)
tiles <- gsub("_", "", substr(files,nchar(files)-10,nchar(files)-8))
years_tiles <- substr(files,nchar(files)-6,nchar(files)-3)

### load all tiles and extract

result_tiles <- list()
for (tile in unique(tiles)){
  files_tile <- files[tiles==tile]
  result_tiles <- data.frame()
  for (i in 1:length(files_tile)){
    result_tiles <- rbind(result_tiles,
                                 t(extract(stack(files_tile[i]),locations)))
  }
  save(result_tiles,file=paste0(outpath,"ts_",tile,".RData"))
}


### combine all data
tss <- list.files(outpath,full.names = TRUE)
result <- get(load(tss[[1]]))
for (i in 2:length(tss)){
  current <- get(load(tss[[i]]))
  if (!identical(row.names(current),row.names(result))){
    stop("dates dont fit")
  }
  result[is.na(result)] <- current[is.na(result)]
}
result <- data.frame("Date"=strptime(substr(row.names(result),2,nchar(row.names(result))),
                                     format="%Y.%m.%d"),
                     result)
names(result)[2:ncol(result)] <- as.character(locations$locations.X)
save(result,file=paste0(outpath,"rainfall_combined.RData"))
write.csv(result,paste0(outpath,"rainfall_combined.csv"),row.names = FALSE)
