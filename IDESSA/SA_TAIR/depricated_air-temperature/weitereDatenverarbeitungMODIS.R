# Weitere Datenverarbeitung der MODIS-Daten (filtern etc.)

setwd("F:/IDESSA/data/stichprobe/MODIS")

#checken, ob der Ordner existiert

validPath <- function(mainDir, subDir){

# Überprüfung, ob ein Ordner bereits existiert, falls nicht, wird dieser neu angelegt
# und in jedem Fall als Arbeitsverzeichnis gesetzt
# (Quelle:http://stackoverflow.com/questions/4216753/check-existence-of-directory-and-create-if-doesnt-exist)

# Args: 
#   mainDir = Hauptverzeichnis
#   subDir = Unterverzeichnis

# returns:
#   nothing

if (file.exists(paste(mainDir, subDir, "/", sep = "/", collapse = "/"))) {
    cat("subDir exists in mainDir and is a directory")
} else if (file.exists(paste(mainDir, subDir, sep = "/", collapse = "/"))) {
    cat("subDir exists in mainDir but is a file")
    # you will probably want to handle this separately
} else {
    cat("subDir does not exist in mainDir - creating")
    dir.create(file.path(mainDir, subDir))
}

if (file.exists(paste(mainDir, subDir, "/", sep = "/", collapse = "/"))) {
    # By this point, the directory either existed or has been successfully created
    setwd(file.path(mainDir, subDir))
} else {
    cat("subDir does not exist")
    # Handle this error as appropriate
}

}

filterData <- function(ipath, msize, funct = mean){
# filtert alle MODIS-LST-Daten, die sich in einem Ordner befinden und schreibt sie in einen eigenen Ordner 

# Args:
#   ipath = Pfad mit den Rohdaten
#   funct = the function to apply (default = mean)
#   msize = the size of the filter matrix
#   
# Returns:
#   einen Ordner mit den gefilterten Daten

# Name für den neuen Ordner
# Muster = MODIS03x03


mainDir <- "D:/IDESSA/data/stichprobe"
subDir <- paste0("MODIS", sprintf(msize, "%02d"), "x", sprintf(msize, "%02d"))

# überprüfen, ob der Ordner existiert, ggf. neu anlegen & dann diesen als Arbeitsverzeichnis setzen
validPath(mainDir, subDir)
# 

for(i in list.files(file.path = ipath, pattern = "_1km.tif$")){
  #Datei einlesen
  input <- raster(i)
  
  input[input == 0] <- NA
  
  #filtern
  out <- focal(input, w = matrix(1, nr=msize, nc=msize), fun = funct)
  
  #Datei ausschreiben
  writeRaster(out, paste0(i, sprintf(msize, "%02d"), "x", sprintf(msize, "%02d"), ".tif"), 
              overwrite = T)
}
}


