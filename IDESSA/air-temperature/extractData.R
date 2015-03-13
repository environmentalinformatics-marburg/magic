
extractData <- function(inpath, clim, colname, type, pat = NULL){
  # zieht aus einem Satz von Rasterdaten an bestimmten Punkten die Werte heraus
  # und speichert sie in einer Tabelle
  
  #Args
  #  inpath = Speicherort der Daten
  #  pat = ggf. Muster zur Erkennung der Daten (default = NULL)
  #  clim = SpatialPointsDataFrame der Klimadaten
  #  colname = Name der neuen Spalte
  #  type = sind es Daten zu Temperatur (LST), Aufnahmezeit (VT) oder zenitwinkel (VTA)
  #  
  # Returns:
  #   data.frame mit weiterem Datensatz, der dem bisherigen hinzugefuegt werden kann
  
  input <- stack(c(list.files(path = ipath, pattern = pat)))
  input <- cleanModisData(input, type)
  
  ## daten rausziehen aus stack
  extr <- extract(input, clim)
  extr <- as.data.frame(extr)
  
  cli <- as.data.frame(clim)
  
  #Spalten umbenennen und loeschen
  extr$station <- cli$shpTbl_
  
  # Wide-To-Long  
  extrlong <- melt(extr, id.vars = c("station"))
  
  # Spalten loeschen
  #extrlong$value <- NULL
  #extrlong$variable <- NULL
  
  out <- data.frame(colname = extrlong$value)
  colnames(out)[1] <- colname
  
  return(out)
  #View(extrlong)
}

#ipath <- "D:/IDESSA/data/stichprobe/MODIS"

#input <- "D:/IDESSA/data/stichprobe/MODIS"
#pattern <- "_1km.tif$"
#pat <- "_1km.tif$"
#col <- "TempMD07"
#type <- "LST"

#md <- extractData(ipath, clim, col, pattern, type)

