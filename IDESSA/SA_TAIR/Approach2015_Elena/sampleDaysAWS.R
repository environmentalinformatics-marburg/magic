# Stationsdaten AWS auf Stichprobentage anpassen


sampleDaysAWS <- function(days, inpath, outpath){
  # Funktion zur Extraktion von einzelnen Tagen aus den AWS-Stationsdaten
  
  # Args:
  #   days = Vektor mit Strings von den beötigten Daten im Format YYYY-MM-DD
  #   inpath = Speicherort der Rohdaten
  #   outpath = Ausgabepfad für verarbeitete Daten
  
  # Returns:
  #   eine csv-Datei mit den benoetigten Daten am angegebenen Speicherort
  
  aws <- data.frame()
  
  #i <- list.files(path = inpath, pattern = "csv")[1]
  
  for(i in list.files(path = inpath, pattern = "csv")){
    # Datei einlesen
    df <- read.csv(paste0(inpath, i))
    
    #Zeitspalte umwandeln zu POSIXct
    df$time <- as.POSIXct(df$datetime, format = "%Y-%m-%dT%H:%M")
    
    #Zeitspalte umwandeln (nur Tag)
    df$day <- as.character(trunc(df$time, "day"))
    
    #subset an Stichprobentagen
    df <- df[df$day %in% days,]
    
    #mit dem Rest zusammenfuegen
    aws <- rbind(aws, df)
  }
  
  ##data.frame formatieren (spalten umbenennen und loeschen)
  aws$station <- aws$plotID
  aws$plotID <- NULL
  
  aws$TempAWS <- aws$Ta_200
  aws$Ta_200 <- NULL
  
  aws$timestamp <- NULL
  aws$datetime <- NULL
  aws$day <- NULL
  
  #datei ausschreiben
  write.csv(aws, file.path(outpath, "stichprobe_aws.csv"), row.names = F)

}



