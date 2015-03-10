# Weitere Datenverarbeitung der MODIS-Daten (filtern etc.)

setwd("F:/IDESSA/data/stichprobe/MODIS")

for(i in list.files(pattern = "_1km.tif$")){
  #Datei einlesen
  input <- raster(i)
  
  input[input == 0] <- NA
  
  #filtern
  out <- focal(input, w = matrix(1, nr=15, nc=15), fun = mean)
  
  #Datei ausschreiben
  writeRaster(out, paste0("F:/IDESSA/data/stichprobe/MODIS15x15/", i, "15x15.tif"), 
              overwrite = T)
}