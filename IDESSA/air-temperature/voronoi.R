# Carson's Voronoi polygons function
voronoipolygons <- function(x) {
  require(deldir)
  require(sp)
  if (.hasSlot(x, 'coords')) {
    crds <- x@coords  
  } else crds <- x
  z <- deldir(crds[,1], crds[,2])
  w <- tile.list(z)
  polys <- vector(mode='list', length=length(w))
  for (i in seq(along=polys)) {
    pcrds <- cbind(w[[i]]$x, w[[i]]$y)
    pcrds <- rbind(pcrds, pcrds[1,])
    polys[[i]] <- Polygons(list(Polygon(pcrds)), ID=as.character(i))
  }
  SP <- SpatialPolygons(polys)
  voronoi <- SpatialPolygonsDataFrame(SP, data=data.frame(x=crds[,1],
                                                          y=crds[,2], row.names=sapply(slot(SP, 'polygons'), 
                                                                                       function(x) slot(x, 'ID'))))
}



# Read in a point shapefile to be converted to a Voronoi diagram
library(rgdal)
dsn <- system.file("vectors", package = "rgdal")[1]
cities <- readOGR(dsn=dsn, layer="cities")

#positionen der klimastationen einlesen
clim <- readShapePoints("E:/IDESSA/data/roh/shapes/AWS.shp")
#Projektion zuweisen
proj4string(clim) <- "+proj=longlat +datum=WGS84 +no_defs"

af <- readShapePoly("E:/IDESSA/data/roh/shapes/afrika_epsg4326.shp")
proj4string(af) <- "+proj=longlat +datum=WGS84 +no_defs"
af <- crop(af, clim)
spplot(af, zcol = "Y_1965")
v <- voronoipolygons(clim)

spplot(af, zcol="Y_1965") + as.layer(spplot(v, zcol = "x", col = "red",
                                            col.regions="transparent"))

plot(v)
