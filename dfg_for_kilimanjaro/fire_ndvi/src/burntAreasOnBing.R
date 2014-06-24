### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/pa_NDown/ki_modis_ndvi/"}, 
       "Windows" = {path.wd <- "F:/ki_modis_ndvi"})
setwd(path.wd)

# Required packages and functions
# library(devtools)
# install_github("Rsenal", "environmentalinformatics-marburg")
# library(Rsenal)

lib <- c("doParallel", "raster", "rgdal", "OpenStreetMap", "ggplot2")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

fun <- paste("src", c("kifiAggData.R", "probRst.R", "myMinorTick.R", 
                      "ndviCell.R", "evalTree.R", "kifiModisDownload.R"), sep = "/")
sapply(fun, source)

MODISoptions(localArcPath = paste0(getwd(), "/data/MODIS_ARC/"), 
             outDirPath = paste0(getwd(), "/data/MODIS_ARC/PROCESSED/"))

# Parallelization
registerDoParallel(cl <- makeCluster(3))


### Data import

## MODIS fire

# Daily data: import raster files and aggregate on 8 days
aggregate.exe <- FALSE

if (aggregate.exe) {
  # List files
  fire.fls <- list.files("data/reclass/md14a1", full.names = TRUE, pattern = ".tif$")
  
  # Setup time series
  fire.dates <- substr(basename(fire.fls), 8, 14)
  fire.years <- unique(substr(basename(fire.fls), 8, 11))
  
  fire.dly.ts <- do.call("c", lapply(fire.years, function(i) { 
    seq(as.Date(paste(i, "01", "01", sep = "-")), 
        as.Date(paste(i, "12", "31", sep = "-")), 1)
  }))
  
  # Merge time series with available fire data
  fire.dly.ts.fls <- merge(data.frame(date = fire.dly.ts), 
                           data.frame(date = as.Date(fire.dates, format = "%Y%j"), 
                                      file = fire.fls, stringsAsFactors = F), 
                           by = "date", all.x = T)
  
  fire.rst <- unlist(kifiAggData(
    data = fire.dly.ts.fls, 
    years = fire.years, 
    over.fun = function(...) max(..., na.rm = T), 
    dsn = "data/overlay/md14a1_agg/", 
    out.str = "md14a1", format = "GTiff", overwrite = T, 
    out.proj = "+init=epsg:32737", n.cores = 4
  ))
} 


# Aggregated data: list files
fire.fls <- list.files("data/overlay/md14a1_agg", pattern = "md14a1.*.tif$", 
                       full.names = TRUE)

# Setup time series
fire.dates <- substr(basename(fire.fls), 8, 14)
fire.years <- unique(substr(basename(fire.fls), 8, 11))

fire.ts <- do.call("c", lapply(fire.years, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 8)
}))

# Merge time series with available fire data
fire.ts.fls <- merge(data.frame(date = fire.ts), 
                     data.frame(date = as.Date(fire.dates, format = "%Y%j"), 
                                file = fire.fls, stringsAsFactors = FALSE), 
                     by = "date", all.x = TRUE)

# Import aggregated fire data
if (!exists("fire.rst"))
  fire.rst <- foreach(i = seq(nrow(fire.ts.fls)), .packages = lib) %dopar% {
    if (is.na(fire.ts.fls[i, 2])) {
      NA
    } else {
      raster(fire.ts.fls[i, 2])
    }
  }


## Plotting each pixel that burnt at least once over a BING aerial image
## from Mt. Kilimanjaro

# # Overlay single fire layers
# fire.rst.cc <- stack(fire.rst[!sapply(fire.rst, is.logical)])
# fire.rst.cc.all <- overlay(fire.rst.cc, fun = function(...) {
#   if (sum(..., na.rm = TRUE) == 0) return(0) else return(1)
# }, filename = "out/all_fire_cells", format = "GTiff", overwrite = TRUE)
# fire.rst.cc.all[which(fire.rst.cc.all[] == 0)] <- NA

fire.rst.cc.all <- raster("out/all_fire_cells.tif")

# Retrieve BING aerial image
kili.map <- openproj(openmap(upperLeft = c(-2.83, 36.975), 
                             lowerRight = c(-3.425, 37.72), type = "bing", 
                             minNumTiles = 40L), projection = "+init=epsg:32737")

# Convert noNA pixels to polygons and extract coordinates
fire.shp.cc.all <- rasterToPolygons(fire.rst.cc.all)

fire.df <- data.frame(x = coordinates(fire.shp.cc.all)[, 1], 
                      y = coordinates(fire.shp.cc.all)[, 2])

# Plotting
png("out/plots/kili_topo_fire.png", units = "mm", width = 300, res = 300, 
    pointsize = 14)
autoplot(kili.map) + 
  geom_tile(aes(x = x, y = y), data = fire.df, 
            colour = "red", fill = "transparent", size = 1.1) + 
  labs(x = "x", y = "y") +
  theme(axis.title.x = element_text(size = rel(1.4)), 
        axis.text.x = element_text(size = rel(1.1)), 
        axis.title.y = element_text(size = rel(1.4)), 
        axis.text.y = element_text(size = rel(1.1)))
dev.off()
