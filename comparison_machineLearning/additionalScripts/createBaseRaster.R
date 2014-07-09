
y=raster("/home/hanna/Documents/Projects/IDESSA/Precipitation/skrips/meteosat_de/000000000000_00000_ml01danb1_na001_1000_rg01de_003000.rst", 
         native = T, crs = "+proj=longlat +datum=WGS84")
x=raster("/home/hanna/Documents/Projects/IDESSA/Precipitation/skrips/meteosat_de/000000000000_00000_ml02danb1_na001_1000_rg01de_003000.rst", 
         native = T, crs = "+proj=longlat +datum=WGS84")


rasterframe=data.frame("x"=values(x),"y"=values(y))
write.csv(rasterframe,"/media/hanna/ubt_kdata_0005/pub_rapidminer/rasterframe.csv",row.names=FALSE) 

#saga shape from xyz
#shape to grid
#exort als tiff
