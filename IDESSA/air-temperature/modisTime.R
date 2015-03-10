

modisTime <- function(inpath, clim, LT = T){
  # liest aus einem Eingabeordner alle Dateien mit Zeitangaben, ordnet diese den
  # Klimastationen zu
  
  # Args:
  #   inpath = Ordner mit den MODIS-Daten
  #   clim = SpatialPointsDataFrame mit den Klimastationen
  #   LT = soll die Zeit von lokaler Sonnenzeit in lokale Zeit umgerechnet 
  #        werden? (default = T)
  
  # Returns:
  #   bei LT = F einen data.frame mit folgender struktur:
  #   Station | MODIS-Produkt MYD/MOD | Datum | lokale Sonnenzeit
  #
  #   bei LT = T einen data.frame mit folgender struktur:
  #   Station | MODIS-Produkt MYD/MOD | Datum + lok. Zeit | Datum + lok. Zeit (zur vollen Std.)
  
  setwd(inpath)
  
  # Uhrzeit in stacks schieben
  time <- stack(c(list.files(pattern = "view_time.tif$")))
  
  ## daten rausziehen aus zeit-stack tag
  etime <- extract(time, clim)
  etime <- as.data.frame(etime)
  
  cli <- as.data.frame(clim)
  
  # Wide To Long
  etime$station <- cli$shpTbl_
  etime$lat <- cli$y
  etime$lon <- cli$x
  etimelong <- melt(etime, id.vars = c("station", "lat", "lon"))
  
  #Spalte für Produkt (MOD11A1/MYD11A1) anlegen
  etimelong$product <- substr(etimelong$variable, 1, 7)
  
  #Spalte mit Datum anlegen
  etimelong$date <- substr(etimelong$variable, 9, 18)
  etimelong$date <- as.POSIXct(etimelong$date, format = "%Y.%m.%d")
  
  #Spalte für Uhrzeit anlegen
  etimelong$value[etimelong$value == 255] <- NA
  etimelong$solartime <- etimelong$value/10
  etimelong$variable <- NULL
  etimelong$value <- NULL
  
  if(LT == T){
    res <- LST_to_LT(data.frame(etimelong$date, etimelong$solartime, etimelong$lon), 30)  
    etimelong <- cbind(etimelong, res)
    etimelong$solartime <- NULL
    etimelong$date <- NULL
  }
    
  #View(etimelong)
  return(etimelong)
  
}

