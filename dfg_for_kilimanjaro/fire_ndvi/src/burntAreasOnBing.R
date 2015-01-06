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

lib <- c("doParallel", "raster", "rgdal", "OpenStreetMap", "ggplot2", 
         "RColorBrewer", "grid", "rasterVis")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

fun <- paste("src", c("kifiAggData.R", "probRst.R", "myMinorTick.R", 
                      "ndviCell.R", "evalTree.R", "kifiModisDownload.R"), sep = "/")
sapply(fun, source)

# Parallelization
registerDoParallel(cl <- makeCluster(3))


### Data import

## MODIS fire

# # Confidence == "nominal"
# fls_nom <- list.files("data/md14a1/aggregated", pattern = "aggsum_md14a1", 
#                       full.names = TRUE)
# rst_nom <- stack(fls_8day)
# 
# # Confidence == "low"
# fls_low <- list.files("data/md14a1/low/aggregated", pattern = "aggsum_md14a1", 
#                       full.names = TRUE)
# rst_low <- stack(fls_low)

# Monthly rasters
fls_agg <- list.files("data/md14a1/low/aggregated", pattern = "aggsum_md14a1", 
                      full.names = TRUE)
rst_agg <- stack(fls_agg)

# (Identify and) Import overall burnt pixels
# rst_agg_all <- overlay(rst_agg, fun = function(...) {
#   if (sum(..., na.rm = TRUE) == 0) return(NA) else return(1)
# }, filename = "out/fire_agg/fire_agg_all_01_13", format = "GTiff", overwrite = TRUE)

rst_agg_all <- raster("out/fire_agg/fire_agg_all_01_13.tif")

# Convert noNA pixels to polygons and extract coordinates
fire.shp.all <- rasterToPolygons(rst_agg_all)

fire.df <- data.frame(x = coordinates(fire.shp.all)[, 1], 
                      y = coordinates(fire.shp.all)[, 2])


## Bing

# (Retrieve, save and) Import BING aerial image
kili.map <- openproj(openmap(upperLeft = c(-2.83, 36.975), 
                             lowerRight = c(-3.425, 37.72), type = "bing", 
                             minNumTiles = 40L), projection = "+init=epsg:21037")
# kili.map <- writeRaster(raster(kili.map), filename = "data/kili_bing_aerial", 
#                         bylayer = FALSE, format = "GTiff", overwrite = TRUE)
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
ssn <- rep(month.abb, nlayers(rst_agg)/12)
ssn[ssn %in% c("Dec", "Jan", "Feb")] <- "DJF"
ssn[ssn %in% c("Mar", "Apr", "May")] <- "MAM"
ssn[ssn %in% c("Jun", "Jul", "Aug")] <- "JJA"
ssn[ssn %in% c("Sep", "Oct", "Nov")] <- "SON"
ssn <- factor(ssn, levels = c("DJF", "MAM", "JJA", "SON"))

fire.ts.rst.cc.ssn <- 
  stackApply(rst_agg, 
             indices = as.numeric(ssn), 
             fun = function(x, ...) if (sum(x, ...) > 0) return(1) else return(NA),
             filename = "out/fire_agg/fire_agg_ssn_01_13", format = "GTiff", 
             overwrite = TRUE)



# Number of burns per pixel
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

np_old <- readOGR(dsn = "data/protected_areas/", 
                  layer = "fdetsch-kilimanjaro-national-park-1420535670531", 
                  p4s = "+init=epsg:4326")
np_old_utm <- spTransform(np_old, CRS("+init=epsg:21037"))

np_new <- readOGR(dsn = "data/protected_areas/", 
                  layer = "fdetsch-kilimanjaro-1420532792846", 
                  p4s = "+init=epsg:4326")
np_new_utm <- spTransform(np_new, CRS("+init=epsg:21037"))

rst_agg_sum <- overlay(rst_agg, fun = function(...) {
  val <- sum(..., na.rm = TRUE)
  return(val)
}, filename = "out/fire_agg/fire_agg_sum_01_13", format = "GTiff", overwrite = TRUE)

rst_agg_sum <- raster("out/fire_agg/fire_agg_sum_01_13.tif")
rst_agg_sum[rst_agg_sum[] == 0] <- NA

reds <- colorRampPalette(brewer.pal(9, "Reds"))

# spplot(rst_agg_sum, col.regions = reds(140)[seq(20, 140, 15)], at = seq(1, 17, 2), 
#        sp.layout = list("sp.lines", rasterToContour(dem), col = "grey50"), 
#        scales = list(draw = TRUE))

img_agg_sum <- 
  levelplot(rst_agg_sum, col.regions = reds(116)[seq(20, 116, 12)], 
            FUN.margin = sum, at = seq(1, 17, 2), scales = list(draw = TRUE), 
            xlab = list(label = "x", cex = 1.4), ylab = list(label = "y", cex = 1.4), 
            par.settings = list(layout.heights = list(bottom.padding = 8))) + 
  as.layer(contourplot(dem, labels = FALSE, cuts = 10)) + 
  layer(sp.polygons(np_old_utm, lwd = 1.6, lty = 2)) + 
  layer(sp.polygons(np_new_utm, lwd = 1.6))

png("out/proposal/fire_agg_sum_01_13.png", width = 26, height = 24, units = "cm", 
    res = 300, pointsize = 15)
print(img_agg_sum)
trellis.focus("legend", side = "bottom", clipp.off = TRUE, highlight = FALSE)
grid.text("No. of active fires", 0.5, 0, hjust = 0.5, vjust = 2)
trellis.unfocus()
dev.off()
