### Code taken from https://gist.github.com/mdsumner/e131f6d73aa02d49c7fd3357d94d3ad1

### helper functions -----

## quad index template
p4 <- function(xp, nc) {
  (xp + c(0, 0, rep(nc, 2)))[c(1, 2, 4, 3)]
}

## offset pairs from a vector
prs <- function(x) {
  cbind(head(x, -1), tail(x, -1))
}

## pixel corners from a raster
edgesXY <- function(x) {
  coordinates(shift(
    extend(x, 
           extent(xmin(x), xmax(x) + res(x)[1], ymin(x), ymax(x) + res(x)[2])), 
    x = -res(x)[1]/2, y = -res(x)[2]/2))
}

## build a quad mesh from a raster
bgl <- function(x, z = NULL, na.rm = FALSE) {
  x <- x[[1]]  ## just the oneth raster for now
  ##exy <- as.matrix(expand.grid(edges(x), edges(x, "y")))
  exy <- edgesXY(x)
  ind <- apply(prs(seq(ncol(x) + 1)), 1, p4, nc = ncol(x) + 1)
  ## all face indexes
  ind0 <- as.vector(ind) + 
    rep(seq(0, length = nrow(x), by = ncol(x) + 1), each = 4 * ncol(x))
  ## need to consider normalizing vertices here
  if (na.rm) {
    ind1 <- matrix(ind0, nrow = 4)
    ind0 <- ind1[,!is.na(values(x))]
  }
  ## dummy object from rgl
  ob <- rgl::oh3d()
  if (!is.null(z)) z <- extract(z, exy, method = "bilinear") else z <- 0
  ob$vb <- t(cbind(exy, z, 1))
  ob$ib <- matrix(ind0, nrow = 4)
  ob
}


## packages
library(raster)
library(dismo)
library(rgdal)
library(rgl)


### build mesh3d object -----

## read elevation grid and crop
lgg = data.frame(x = 596272.7, y = 760795.6, loc = "Lake Garba Guracha")
coordinates(lgg) = ~ x + y
proj4string(lgg) = "+init=epsg:32637"

bff = rgeos::gBuffer(lgg, width = 2000, quadsegs = 100L)
bff_ll = spTransform(bff, CRS("+init=epsg:4326"))
srtm <- raster("../../../../data/bale/dem/dem_srtm_01.tif")
srtm <- crop(srtm, bff_ll)

## rescale heights 
ro <- bgl(srtm, z = srtm / 50000)

# 0.7Mb
## download a google satellite image with dismo
gm <- gmap(x = srtm, type = "satellite", scale = 2)

## 1. Create PNG for texture
# we need RGB expanded (gmap gives a palette)
rgb1 <- col2rgb(gm@legend@colortable)
img <- brick(gm, gm, gm)
cells <- values(gm) + 1
img <- setValues(img, cbind(rgb1[1, cells], rgb1[2, cells], rgb1[3, cells]))
## finally, create RGB PNG image to act as a texture image
writeGDAL(as(img, "SpatialGridDataFrame"), "data/dsm-lgg.png", drivername = "PNG", type = "Byte", mvFlag = 255)

## 2. Remap the image coordinates (Mercator) onto elevation coordinates (longlat), 
## and convert to PNG [0, 1, 0, 1]
tcoords <- xyFromCell(setExtent(gm, extent(0, 1, 0, 1)), cellFromXY(gm, project(t(ro$vb[1:2, ]), projection(gm))))

## single pass plot for rgl
rgl.clear()
shade3d(ro, col = "white", texture = "data/dsm-lgg.png", texcoords = tcoords[ro$ib, ])
