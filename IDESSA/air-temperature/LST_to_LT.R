LST_to_LT <- function(input, lstm){
  # Umrechnung von Lokaler Sonnenzeit (LST) zu Lokaler Ortszeit (LT)
  # benoetigte Packages: insol
  
  # Args: 
  #   input: data.frame mit folgenden Spalten in der gleichen Reihenfolge
  #          Datum | Uhrzeit (LST) | Längengrad
  #   lstm = local standard time meridian (Mittelmeridian der Zeitzone)
  
  # Returns:
  #   Vektor mit korrigierten Daten
  
  # local solar time in UTC+2 umrechnen
  modtime <- input[[2]] - eqtime(JD(input[[1]]))/60 + (input[[3]] - lstm)/15
  
  #Ergebnis in Uhrzeitformat umrechnen
  modtime <- paste(floor(modtime), sprintf("%02d", round((modtime - floor(modtime))*60, 0)), sep = ":")
  
  # Kombination von Datum und Uhrzeit in POSIXct
  modtime <- paste(input[[1]], modtime)
  modtime <- as.POSIXct(modtime, format = "%Y-%m-%d %H:%M")
  
  # Uhrzeit auf volle Stunde setzen
  time <- as.POSIXct(trunc(modtime, "hour"))
  
  # modtime und time zusammenfuegen
  output <- data.frame("modtime" = modtime, "time" = time)
  
  #View(output)
  return(output)
  
}

#cols <- LST_to_LT(data.frame(etimelong$date, etimelong$solartime, etimelong$lon), 30)
#View(cols)

