################################################################################
################################################################################
#       erstelle Punktshape von MODIS 1km Mittelpunktskoordinaten
#diese können in einem weiteren Schritt in Polygone umgewandelt werden
#die als räumliche Vorlage für den download der google Bilder dienen


################################################################################
#Datapaths
################################################################################
#Pfad zu MODIS Daten
datapath="/home/hanna/Documents/Projects/IDESSA/vegetation/sampleMODISData/cover/"
#Pfad zu Vegetationsdaten:
vegpath="/home/hanna/Documents/Projects/IDESSA/GIS/Vegetation_CD/Data/"
################################################################################
#benötigte packages:
################################################################################
Packages=c("sp","raster","maptools",
           "plotKML","rgeos","dismo","maps",
           "rgdal","MODIS","gdistance")
#installiere vorher Pakete (falls noch nicht vorhanden)
lapply(Packages, library, character.only=T)

################################################################################
# MOSAIC erstellen
################################################################################

filelist=list.files(datapath,pattern=".hdf")

#lade alle Modis raster 
RasterLayer=list()
for (i in 1:length(filelist)){
  tmp=getSds(paste0(datapath,filelist[i]))
  RasterLayer[[i]]=raster(tmp$SDS4gdal[1])
}

###mosaic einzelne Raster
m=mosaic(RasterLayer[[1]],RasterLayer[[2]],RasterLayer[[3]],RasterLayer[[4]],
         RasterLayer[[5]],RasterLayer[[6]],RasterLayer[[7]],RasterLayer[[8]],fun=max)

###auf Grassland und Savanne zuschneiden
#m=crop(m,extent(1300000,3300000,-3900000,-2400000))
vegdata=readShapePoly(paste0(vegpath,"vegm2006_bioregions.shp"))
vegdata=vegdata[vegdata$BIOME=="Savanna Biome"|vegdata$BIOME=="Grassland Biome",]
proj4string(vegdata) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
vegdata=spTransform(vegdata, CRS(proj4string(m)))
vegraster=mask(m, vegdata)

### ID als Wert setzen
#values(vegraster)=1:ncell(vegraster)
################################################################################
# ###raster to point
################################################################################
Mittelpunkte=rasterToPoints(vegraster,spatial=TRUE)
Mittelpunkte$layer=1:length(Mittelpunkte)
ModisPixels=gBuffer(Mittelpunkte,capStyle = "SQUARE",width = res(vegraster)[1]/2-0.001)


spp <-SpatialPolygonsDataFrame(ModisPixels,data=as.data.frame(Mittelpunkte$layer))

writeSpatialShape(ModisPixels, "/home/hanna/Documents/Projects/IDESSA/vegetation/ModisPixels.shp")

#vektor ausschreiben:
writeOGR(Mittelpunkte, "/home/hanna/Documents/Projects/IDESSA/vegetation", "Mittelpunkte", driver="ESRI Shapefile",overwrite_layer = TRUE)

