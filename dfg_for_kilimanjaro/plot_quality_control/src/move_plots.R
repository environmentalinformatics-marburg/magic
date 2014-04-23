# Required libraries
library(rgdal)
library(raster)

# Functions for dX and xY to move Whittaker plot with respect to other poles
set.dXW <- function(df, mv, pos){
  abs(df[df$PlotID == as.character(mv$PlotID[pos]) & 
           df$PoleName == "A middle pole", ]$coords.x1 - 
        df[df$PlotID == as.character(mv$PlotID[pos]) & 
             df$PoleName == "B7", ]$coords.x1 - 
        df[df$PlotID == as.character(mv$PlotID[pos]) & 
             df$PoleName == "A1", ]$coords.x1 + 
        df[df$PlotID == as.character(mv$PlotID[pos]) & 
             df$PoleName == "A3", ]$coords.x1) *
    mv$fX[pos] + 4.8211
}

set.dYW <- function(df, mv, pos){
  abs(df[df$PlotID == as.character(mv$PlotID[pos]) & 
           df$PoleName == "A middle pole", ]$coords.x2 - 
        df[df$PlotID == as.character(mv$PlotID[pos]) & 
             df$PoleName == "B7", ]$coords.x2) *
    mv$fY[pos]
}

# Working directory and data set
dsn <- switch(Sys.info()[["sysname"]], 
              "Linux" = "/media/permanent/",
              "Windows" = "D:/")
setwd(paste0(dsn, "active/kilimanjaro_plot_quality_control/data"))
input.filepath <- "plot_poles_arc1960_mod/PlotPoles_ARC1960_mod_20140410_v01_renamed.shp"
output.path <- paste(dirname(input.filepath), "moved", sep = "/")
output.filepath <- paste(output.path, basename(input.filepath), sep = "/")
layer <- sub("^([^.]*).*", "\\1", basename(input.filepath))

# Set moving parameters for each plot
C12hom4 <- c(332421.971, 9631318.771)  
C14hom4 <- c(332430.597, 9631269.741)
C15hom4 <- c(332435.394, 9631245.184)
dChom4 <- C14hom4 - C12hom4 - C15hom4 + C14hom4
 
move <- data.frame(PlotID = c("cof1", "fed2", "hom4"),
                   dX = c(9.385397, NaN, dChom4[1]),
                   dY = c(-5.396083, NaN, dChom4[2]),
                   fX = c(0.0, -1.0, 0.0),
                   fY = c(0.0, -1.0, 0.0),
                   Poles = c("*", "A, T", "C4, C15"))

# Move plots and write data to output data set
input.data <- readOGR(input.filepath, layer = layer)
prj.org <- projection(input.data)
data.df <- data.frame(input.data)
for(i in seq(nrow(move))){
  if(is.na(move$dX[i])) move$dX[i] <- set.dXW(data.df, move, i)
  if(is.na(move$dY[i])) move$dY[i] <- set.dYW(data.df, move, i)
  if(move$PlotID[i] == "hom4"){
    for(pole in gsub("\\s","", strsplit(as.character(move$Poles[i]), ",")[[1]])){
      data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                data.df$PoleName == pole &
                !is.na(data.df$PoleName), ]$coords.x1 <-
        data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                  data.df$PoleName == pole &
                  !is.na(data.df$PoleName), ]$coords.x1 + 
        move$dX[i]
      data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                data.df$PoleName == pole &
                !is.na(data.df$PoleName), ]$coords.x2 <-
        data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                  data.df$PoleName == pole &
                  !is.na(data.df$PoleName), ]$coords.x2 + 
        move$dY[i]
    }
  } else if(move$Poles[i] == "*"){
    data.df[data.df$PlotID == as.character(move$PlotID[i]), ]$coords.x1 <- 
      data.df[data.df$PlotID == as.character(move$PlotID[i]), ]$coords.x1 + 
      move$dX[i]
    data.df[data.df$PlotID == as.character(move$PlotID[i]), ]$coords.x2 <- 
      data.df[data.df$PlotID == as.character(move$PlotID[i]), ]$coords.x2 + 
      move$dY[i]
  } else {
    for(pole in gsub("\\s","", strsplit(as.character(move$Poles[i]), ",")[[1]])){
      data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                data.df$PoleType == pole &
                !is.na(data.df$PoleType), ]$coords.x1 <-
        data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                  data.df$PoleType == pole &
                  !is.na(data.df$PoleType), ]$coords.x1 + 
        move$dX[i]
      data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                data.df$PoleType == pole &
                !is.na(data.df$PoleType), ]$coords.x2 <-
        data.df[data.df$PlotID == as.character(move$PlotID[i]) &
                  data.df$PoleType == pole &
                  !is.na(data.df$PoleType), ]$coords.x2 + 
        move$dY[i]
    }
  }
}

coordinates(data.df) <- ~ coords.x1 + coords.x2
projection(data.df) <- prj.org
dir.create(output.path, showWarnings = FALSE)
writeOGR(data.df, output.filepath, 
         layer = layer,
         driver="ESRI Shapefile")
