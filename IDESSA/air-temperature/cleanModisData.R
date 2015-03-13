cleanModisData <- function(stk, type){
  # Umrechnung und Bereinigung der Modis-Daten nach Tabelle auf
  # http://www.icess.ucsb.edu/modis/LstUsrGuide/usrguide_1dtil.html
  
  # Args:
  #   stk = einen Stack mit MODIS-Aufnahmen im raster-Format
  #   type = handelt es sich um LST/QC/VT (View time)/VTA (View angle)
  # 
  
  if (mode(stk) != mode(stack())){
    stop("falscher Datentyp für stk")
  }
        
  out <- stack()
  
  for(i in 1:nlayers(stk)){
    data <- stk[[i]]
    
    # QC
    if(type == "QC"){
      data[data < 0] <- NA
      data[data > 255] <- NA
      out <- stack(out, data)
    }
    
    #View time angle
    else if(type == "VA"){
      data[data < 0] <- NA
      data[data > 130] <- NA
      
      data <- data - 65
      out <- stack(out, data)
    }
    
    # Vdataew time
    else if(type =="VT"){
      data[data < 0] <- NA
      data[data > 240] <- NA
      out <- stack(out, data)
    }
    
    # Temperatur LST
    else if(type == "LST"){
      data[data < 7500] <- NA
      data[data > 65535] <- NA
      
      data <- data * 0.02 - 273.15
      out <- stack(out, data)
    }
    
    else {
      stop("type invalid")
    }
    
  }
    
  return(out)
  
}

#clean <- cleanModisData(time, "VT")
