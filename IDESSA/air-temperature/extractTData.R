extractTData <- function(inpath, clim, colname, pat = NULL){
  # zieht aus einem Satz von Rasterdaten an bestimmten Punkten die Werte heraus
  # und speichert sie in einer Tabelle
  
  #Args
  #  inpath = Speicherort der Daten
  #  pat = ggf. Muster zur Erkennung der Daten (default = NULL)
  #  clim = SpatialPointsDataFrame der Klimadaten
  #  colname = Name der neuen Spalte
  #  
  # Returns:
  #   data.frame mit weiterem Datensatz, der dem bisherigen hinzugefuegt werden kann
  
  lst <- stack(c(list.files(pattern = pat)))
  
  ## daten rausziehen aus temperatur-stack
  etemp <- extract(lst, clim)
  etemp <- as.data.frame(etemp)
  
  cli <- as.data.frame(clim)
  
  #Spalten umbenennen und loeschen
  etemp$station <- cli$shpTbl_
  
  # Wide-To-Long  
  etemplong <- melt(etemp, id.vars = c("station"))
  
  # Temperaturdaten umrechnen
  celsius <- cleanTData(etemplong$value)
  cel <- data.frame(colname = celsius)
  colnames(cel)[1] <- colname
  
  #etemplong <- cbind(etemplong, cel)

  # Spalten loeschen
  #etemplong$value <- NULL
  #etemplong$variable <- NULL
  
  return(cel)
  #View(etemplong)
}

#ipath <- "E:/IDESSA/data/stichprobe/MODIS"
#pattern <- "_1km.tif$"
#col <- "TempMD"

#md <- extractTData(ipath, clim, col, pattern)