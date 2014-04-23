kiliCoordsShp2Csv <- function(dsn = ".", 
                              layer = NULL, 
                              ...) {
  
  stopifnot(require(package = rgdal))
  
  if (is.null(layer))
    stop("Please supply the name of the required shapefile layer.\n")
  
  if (layer %in% c("APolygon", "BPolygon", "CPolygon", "TPolygon", "WB", "WC"))
    stop("Cannot create .csv file from a polygon shapefile.")
  
  fls.zip <- list.files(path = dsn, 
                        pattern = ".zip$")
  
  fls.unzip <- unzip(zipfile = fls, 
                     list = TRUE)$Name
  unzip(zipfile = fls, 
        files = fls.unzip[grep(layer, fls.unzip)], 
        junkpaths = TRUE)
  
  shp <- readOGR(dsn = dsn, 
                 layer = layer, 
                 verbose = FALSE)
  
  if (layer == "AMiddlePole") {
    df <- shp@data[order(shp@data$PlotID), ]
  } else if (layer == "CornerPole") {
    shp@data$PoleNumber <- 
      as.numeric(substr(x = as.character(shp@data$PoleName), 
                        start = 2, 
                        stop = nchar(as.character(shp@data$PoleName))))
    df <- shp@data[with(shp@data, order(PlotID, PoleType, PoleNumber)), 
                   -ncol(shp@data)]    
  } else {
    shp@data$PoleNumber <- 
      as.numeric(substr(x = as.character(shp@data$PoleName), 
                        start = 2, 
                        stop = nchar(as.character(shp@data$PoleName))))
    df <- shp@data[with(shp@data, order(PlotID, PoleNumber)), -ncol(shp@data)]
  }
  
  write.csv(x = df, 
            file = paste0(layer, ".csv"), 
            row.names = FALSE)
  
  return(df)
}
