### environment -----

library(MODIS)
library(doParallel)

## parallelization
cl = makeCluster(18L)
registerDoParallel(cl)

## 'MODIS' package options
lap = "../../data/MODIS_ARC"
MODISoptions(lap, outDirPath = file.path(lap, "PROCESSED")
             , MODISserverOrder = c("LAADS", "LPDAAC"), quiet = FALSE)


### download and extract -----

## target extent and projection (taken from 
## https://wiki.openstreetmap.org/wiki/Antarctica/Creating_a_map#Projection)
antarctica = getData(country = "ATA", level = 0, path = "../../data")
antarctica = spTransform(antarctica, CRS("+init=epsg:3031"))

## download (in parallel) and extract 500-m bands 1 to 7 including quality 
## information
mod09ga_hdf = foreach(year = 2000:2017, .packages = "MODIS") %dopar% {
  getHdf("MOD09GA", extent = antarctica, collection = "006"
         , begin = paste0(year, ".01.01"), end = paste0(year, ".12.31")
         , checkIntegrity = FALSE)
}

mod09ga_tfs = runGdal("MOD09GA", extent = antarctica, collection = "006"
                      , SDSstring = "0100000000011111111000"
                      , job = "mod09ga-antarctica")

# ## 5600-m climate modeling grid (cmg) bands 1 to 7
# cmg = runGdal("MOD09CMG", extent = antarctica, collection = "006"
#               , begin = "2000.02.24", end = "2000.02.24"
#               , SDSstring = "1111111000000000011100000"
#               , job = "mod09cmg-antarctica")

## deregister parallel backend
stopCluster(cl)