### environmental stuff -----

## wipe out workspace
rm(list = ls(all = TRUE))

## load required packages
lib <- c("raster", "mapview", "foreach", "grid")
jnk <- sapply(lib, function(x) library(x, character.only = TRUE))


### display interactive map of active fires -----

## import yearly fires
# rst <- stack("data/MCD14A1.006/agg1yr/MCD14A1.A2000-2016.FireMask.tif")
fls = list.files("data/MCD14A1.006/agg1yr", pattern = "FireMask.tif$"
                 , full.names = TRUE)
fls = fls[1:grep("A2016.FireMask", fls)]
rst = stack(fls)

names(rst) <- paste0("active_fires_", 2000:2016)

## display interactive fire map, one layer for each year
m0 <- mapview(rst, at = seq(0.5, 5.5, 1), col.regions = "red", legend = FALSE, 
              map.types = rev(mapviewGetOption("basemaps")))
m0

## create a single fire layer for all years
rst_yrs <- rst
jnk <- foreach(i = 1:nlayers(rst), j = 2000:2016) %do% {
  rst_yrs[[i]][rst_yrs[[i]][] > 0] <- j
}
rst_agg <- overlay(rst_yrs, fun = function(...) max(..., na.rm = TRUE))
rst_agg = trim(projectRaster(rst_agg, crs = "+init=epsg:4326", method = "ngb"))
spy_agg <- rasterToPolygons(rst_agg)

## display interactive fire map, one layer for all years
m1 <- mapview(rst_agg, col.regions = rainbow(length(unique(rst_agg[]))), 
              at = seq(1999.5, 2016.5, 1), map.types = rev(mapviewGetOption("basemaps")))
m1


### display static map of active fires -----

## import satellite image
rgb <- stack("inst/extdata/rgb.tif")

p2.1 <- spplot(crp <- crop(rst_agg, rgb, snap = "in")
               , scales = list(draw = TRUE)
               , sp.layout = list(
                 rgb2spLayout(rgb, quantiles = c(0, 1), alpha = .6)
                 , list("sp.points", table, pch = 4, cex = 1.2, col = "black")
               ), at = seq(1999.5, 2016.5, 1), main = "Year of Last MODIS Fire" 
               , col.regions = envinmrPalette(length(unique(rst_agg[])))
               , alpha.regions = .6, colorkey = list(width = .8, height = .6)
               , maxpixels = ncell(crp))

## write resultant map to file
tiff("inst/extdata/wp_modis.tiff", width = 18, height = 16, units = "cm"
     , res = 500, compression = "lzw")
print(p2.1)
dev.off()


### image classification -----

## 3-by-3 focal matrix (incl. center)
mat_w3by3 <- matrix(c(1, 1, 1, 
                      1, 1, 1, 
                      1, 1, 1), nc = 3)

## 5-by-5 focal matrix (excl. center)
mat_w5by5 <- matrix(c(1, 1, 1, 1, 1, 
                      1, 1, 1, 1, 1, 
                      1, 1, 0, 1, 1, 
                      1, 1, 1, 1, 1, 
                      1, 1, 1, 1, 1), nc = 5)

## 5-by-5 focal mean
rgb_fcmu <- lapply(1:nlayers(rgb), function(i) {
  focal(rgb[[i]], w = mat_w5by5, fun = mean, na.rm = TRUE, pad = TRUE)
})
rgb_fcmu <- stack(rgb_fcmu)

## 5-by-5 focal sd
rgb_fcsd <- lapply(1:nlayers(rgb), function(i) {
  focal(rgb[[i]], w = mat_w5by5, fun = sd, na.rm = TRUE, pad = TRUE)
})
rgb_fcsd <- stack(rgb_fcsd)

## visible vegetation index
vi <- vvi(rgb)

## shadow mask
sm <- rgbShadowMask(rgb, 1)

## assemble relevant raster data
rgb_all <- stack(rgb, rgb_fcmu, rgb_fcsd, vi)

## convert to matrix
mat_all <- as.matrix(rgb_all)

## k-means clustering with 3 target groups
kmn_all <- kmeans(mat_all, centers = 6, iter.max = 100, nstart = 10)

## insert values into raster template
rst_tmp <- rgb[[1]]
rst_tmp[] <- kmn_all$cluster

## apply shadow mask
rst_tmp <- rst_tmp * sm
rst_tmp <- focal(rst_tmp, mat_w3by3, fun = modal, pad = TRUE)

rat_tmp <- ratify(rst_tmp)
rat <- rat_tmp@data@attributes[[1]]
rat$Class <- c("S", "C", "A", "B")
rat <- rat[order(rat$Class), , ]
levels(rat_tmp) <- rat


### highlight recurrent fires -----

## extract raster values 
mat <- as.matrix(rst)

## loop over available raster layers (i.e., years)
lst <- lapply(1:nlayers(rst), function(i) {
  
  # create base fire map
  m0 <- mapview(rst[[i]], map.types = "OpenTopoMap", 
                at = seq(.5, max(maxValue(rst) + .5)), col.regions = rainbow(5))
  
  # check if fire cells were registered during current year
  vls <- getValues(rst[[i]])
  cls <- which(vls > 0)
  
  # if so, check if in the detected fire cells, fires also occurred during the 
  # following years
  if (length(cls) > 0 & i != ncol(mat)) {
    ssq <- sapply(cls, function(j) {
      any(mat[j, (i+1):ncol(mat)] > 0)
    })
    
    # if so, add black margins around these particular cells
    cls <- cls[ssq]
    tmp <- rst[[i]]
    tmp[][-cls] <- NA
    shp <- rasterToPolygons(tmp)
    
    m1 <- mapview(shp, map.types = "OpenTopoMap", color = "black")
    m0 <- m1 + m0
  }
  
  return(m0)
})

## display data (e.g., from 2012; all cells that suffered from fire disturbance 
## during the following years have a black border)
lst[[13]]
