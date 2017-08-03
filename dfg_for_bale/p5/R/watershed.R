library(rasterVis)
library(rgl)

## geographic location of lake garba guracha
lgg = data.frame(x = 39.870919, y = 6.882116, loc = "Lake Garba Guracha")
coordinates(lgg) = ~ x + y
proj4string(lgg) = "+init=epsg:4326"

## create 400 m buffer
lgg = spTransform(lgg, CRS("+init=epsg:32637"))
bff = rgeos::gBuffer(lgg, width = 400, quadsegs = 100L)

## import, clip and display 3d image of dem
dem = raster("../../data/bale/dem/dem_srtm_01_utm.tif")
dem = crop(dem, bff)

rasterVis::plot3D(dem, zfac = 1.5)
rgl.clear()


### example taken from https://stackoverflow.com/questions/38926796/adding-point-locations-to-a-3d-dem-plot-in-r -----

## extract sample points
xy <- sampleRandom(dem, 100, xy = TRUE)     

## display them
plot3D(dem, adjust = FALSE)
points3d(xy)
rgl.close()