### environment -----

## working directory
setwd("dfg_for_bale/c2/hdf5")

## packages and functions
library(ESD)

## reference extent
ext = readRDS("../../../../bafire/inst/extdata/uniformExtent.rds")

## modis options
lap = "/media/fdetsch/XChange/MODIS_ARC"
MODISoptions(lap, paste0(lap, "/PROCESSED"), outProj = "+init=epsg:4326")


### preprocessing -----

clc = getCollection("M*D13Q1", forceCheck = TRUE)
tfs = download(product = "M*D13Q1", collection = clc[[1]], extent = ext, 
               SDSstring = "111110000011", job = "ndvi-250m-bale")

tfs = readRDS("../inst/extdata/modis-files.rds")

fvc = preprocess(x = tfs, dsn = "/media/fdetsch/XChange/bale/modis", 
                 whit = FALSE, interval = "fortnight", cores = 3L)
