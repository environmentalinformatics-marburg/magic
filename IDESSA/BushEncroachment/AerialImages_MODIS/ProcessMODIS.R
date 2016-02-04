library(raster)
library(rgdal)


datapath <- "/media/memory01/casestudies/hmeyer/IDESSA_LandCover/PROCESSED/MOD09A1.005_20151209024127/"
setwd(datapath)

files <- list.files(,pattern="b0")
files <- files[substr(files,nchar(files)-3,nchar(files))==".tif"]


filelist <- data.frame ("file"=files, "jday" =substr(files,14,16),
                        "month"=format(strptime(substr(files,14,16), 
                                                format="%j"), format="%m") )

for (i in 1:length(unique(filelist$month))){
  selectedday <- filelist$jday[filelist$month==filelist$month[i]][1]
  selectedchannels <- as.character(filelist$file[filelist$month==filelist$month[i][1]&filelist$jday==
                                                   selectedday])
  scene <- stack(selectedchannels)
  ###Extract Data (Location of aerial images)
  ###add % of the aerial images
}


