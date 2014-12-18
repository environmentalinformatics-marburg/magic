### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/envin/XChange/kilimanjaro/ndvi/"}, 
       "Windows" = {path.wd <- "F:/kilimanjaro/ndvi/"})
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

# Parallelization
registerDoParallel(cl <- makeCluster(3))


### Data import

## MODIS fire

# Confidence == "nominal"
fls_nom <- list.files("data/md14a1/aggregated", pattern = "aggsum_md14a1", 
                      full.names = TRUE)
rst_nom <- stack(fls_8day)

# Confidence == "low"
fls_low <- list.files("data/md14a1/low/aggregated", pattern = "aggsum_md14a1", 
                      full.names = TRUE)
rst_low <- stack(fls_low)

# Monthly rasters
fire.rst <- stack("out/fire_agg/fire_agg_mnth_01_13.tif")

# (Identify and) Import overall burnt pixels
# fire.rst.all <- overlay(fire.rst, fun = function(...) {
#   if (sum(..., na.rm = TRUE) == 0) return(NA) else return(1)
# }, filename = "out/fire_agg/fire_agg_all_01_13", format = "GTiff", overwrite = TRUE)

fire.rst.all <- raster("out/all_fire_cells_0013.tif")

# Convert noNA pixels to polygons and extract coordinates
fire.shp.all <- rasterToPolygons(fire.rst.all)

fire.df <- data.frame(x = coordinates(fire.shp.all)[, 1], 
                      y = coordinates(fire.shp.all)[, 2])


## Bing

# (Retrieve, save and) Import BING aerial image
kili.map <- openproj(openmap(upperLeft = c(-2.83, 36.975), 
                             lowerRight = c(-3.425, 37.72), type = "bing", 
                             minNumTiles = 40L), projection = "+init=epsg:32737")
# writeRaster(raster(kili.map), filename = "data/kili_bing_aerial", 
#             bylayer = FALSE, format = "GTiff", overwrite = TRUE)
# 
# kili.map <- stack("data/kili_bing_aerial.tif")


## Plotting

# Each pixel that burnt at least once
png("out/kili_topo_fire_00_13.png", units = "cm", width = 30, height = 30, 
    res = 300, pointsize = 14)
autoplot(kili.map) + 
  geom_tile(aes(x = x, y = y), data = fire.df, 
            colour = "red", fill = "transparent", size = 1.1) + 
  labs(x = "x", y = "y") +
  theme(axis.title.x = element_text(size = rel(1.4)), 
        axis.text.x = element_text(size = rel(1.1)), 
        axis.title.y = element_text(size = rel(1.4)), 
        axis.text.y = element_text(size = rel(1.1)))
dev.off()


# Each pixel that burnt at least once, divided into seasons (DJF, MAM, JJA, SON)
ssn <- rep(month.abb, nlayers(fire.rst)/12)
ssn[ssn %in% c("Dec", "Jan", "Feb")] <- "DJF"
ssn[ssn %in% c("Mar", "Apr", "May")] <- "MAM"
ssn[ssn %in% c("Jun", "Jul", "Aug")] <- "JJA"
ssn[ssn %in% c("Sep", "Oct", "Nov")] <- "SON"
ssn <- factor(ssn, levels = c("DJF", "MAM", "JJA", "SON"))

fire.ts.rst.cc.ssn <- 
  stackApply(fire.rst, 
             indices = as.numeric(ssn), 
             fun = function(x, ...) if (sum(x, ...) > 0) return(1) else return(NA),
             filename = "out/fire_agg/fire_agg_ssn_01_13", format = "GTiff", 
             overwrite = TRUE)
