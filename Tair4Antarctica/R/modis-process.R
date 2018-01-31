### environment -----

library(MODIS)
library(parallel)

## 'MODIS' package options
lap = "../../data/MODIS_ARC"
MODISoptions(lap, outDirPath = file.path(lap, "PROCESSED")
             , MODISserverOrder = c("LPDAAC", "LAADS"), quiet = TRUE)

## parallelization
cl = makePSOCKcluster(4L)
jnk = clusterEvalQ(cl, { library(MODIS); MODISoptions() })


### download and extract -----

## target extent and projection (taken from 
## https://wiki.openstreetmap.org/wiki/Antarctica/Creating_a_map#Projection)
antarctica = getData(country = "ATA", level = 0, path = "../../data")
antarctica = spTransform(antarctica, CRS("+init=epsg:3031"))

ata_tls = getTile(antarctica)
clusterExport(cl, "ata_tls")

## download (in parallel) and extract 500-m bands 1 to 7 including quality 
## information
mod09ga_hdf = parLapply(cl, 2000:2018, function(year) {
  getHdf("MOD09GA", extent = ata_tls, collection = "006"
         , begin = paste0(year, ".01.01"), end = paste0(year, ".12.31")
         , checkIntegrity = FALSE, forceDownload = TRUE)
})

mod09ga_tfs = parLapply(cl, 2000:2018, function(year) {
  runGdal("MOD09GA", extent = ata_tls, collection = "006"
          , SDSstring = "0100000000011111111000"
          , job = file.path("mod09ga-antarctica", year)
          , begin = paste0(year, ifelse(year == 2000, ".02.24", ".01.01"))
          , end = paste0(year, ".12.31")
          , checkIntegrity = FALSE)
})

# ## 5600-m climate modeling grid (cmg) bands 1 to 7
# cmg = runGdal("MOD09CMG", extent = ata_tls, collection = "006"
#               , begin = "2000.02.24", end = "2000.02.24"
#               , SDSstring = "1111111000000000011100000"
#               , job = "mod09cmg-antarctica")

## deregister parallel backend
stopCluster(cl)