### environment -----

## workspace clearance
rm(list = ls(all = TRUE))

## packages
lib = c("opentraj", "doParallel", "reshape2", "Rsenal", "grid", "latticeExtra")
jnk = sapply(lib, function(x) library(x, character.only = TRUE))

## parallelization
cl <- makeCluster(.75 * detectCores())
registerDoParallel(cl)


### processing -----

## path to meteorological reanalysis data
rsv <- "/media/sd19006/data/users/fdetsch/R-Server" 
hsp = file.path(rsv, "data/bale/HYSPLIT")

KMetFiles = "/media/sd19006/data/satellite_data_world/ncep/"
KOutFiles <- file.path(hsp, "results/")

## hysplit installation path
KHySplitPath <- file.path(rsv, "apps/hysplit-886/")

# ## load and reformat point file
# dat <- read.csv(file.path(hsp, "p1/Master data sheet for Climate Station Data.csv"), 
#                 skip = 3L, header = FALSE, stringsAsFactors = FALSE)
# nms <- read.csv(file.path(hsp, "p1/Master data sheet for Climate Station Data.csv"), 
#                 skip = 2L, nrows = 1L, header = FALSE, stringsAsFactors = FALSE)
# nms[grep("Longitude", nms)] <- "Longitude"
# nms[1, 8:ncol(nms)] <- gsub("\\.", "/", nms[1, 8:ncol(nms)])
# names(dat) <- nms
# 
# mlt <- melt(dat, id.vars = 1:7, variable.name = "date", value.name = "prcp")
# mlt$date <- as.Date(mlt$date, "%d/%m/%Y")

# ## auxilliary plot elements
# rgb <- brick(file.path(hsp, "rgb.tif"))
# 
# coordinates(dat) <- ~ Longitude + Latitude 
# proj4string(dat) <- "+init=epsg:4326"

bmn = brick(file.path(rsv, "data/bale/chirps-2.0/chirps-2.0_bale_monthly.tif"))
bmn = as(extent(bmn), "SpatialPolygons")
proj4string(bmn) = "+init=epsg:4326"
bmn = rgeos::gCentroid(bmn)
crd = coordinates(bmn)

## loop over weather stations
dts = seq(as.Date("1979-09-01"), as.Date("1979-09-30"), "day")

ofl <- paste("iso", "bale", "197909", "", sep = "_")

trj <- ProcTraj(lat = crd[2], lon = crd[1], name = ofl,
                hour.interval = 1,
                met = KMetFiles, out = KOutFiles,
                hours = -24 * 5, height = 3000L, hy.path = KHySplitPath, ID = 1, 
                dates = dts,
                start.hour = "00:00", end.hour = "00:00")

sln <- Df2SpLines(trj, crs = "+init=epsg:4326")

## close parallel backend
stopCluster(cl)
