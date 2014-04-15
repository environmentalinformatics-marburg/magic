library(sp)
library(rgdal)

path <- "/media/HDEXTENSION/kilimanjaro_plot_control"
setwd(path)

### load functions to do rotation
source("code/calcPoles_wC.R")

### list and read .shp files with pole information
fls <- list.files("data/PlotPoles_ARC1960_mod_20140410_v02", 
                  pattern = glob2rx("*Pole*.shp"), full.names = TRUE)

dat.lst <- lapply(seq(fls), function(i) {
  lyr <- ogrListLayers(fls[i])
  tmp <- readOGR(fls[i], layer = lyr)
  print(proj4string(tmp))
  return(tmp)
})

### create new PoleType "AMP" for PoleName "A middle pole" (missing so far)
dat <- do.call("rbind", dat.lst)
dat$PoleType <- as.character(dat$PoleType)
dat$PoleType[dat$PoleName == "A middle pole"] <- "AMP"
dat$PoleType <- as.factor(dat$PoleType)

### subset AMPs
amps <- subset(dat, PoleType == "AMP")

### extract AMP coordinates
apole <- data.frame(PlotID = amps$PlotID,
                    x = coordinates(amps)[, 1],
                    y = coordinates(amps)[, 2])

### set up rotation parameters
to.rotate <- c("hom4", "mai4", "mai5", "sav5", "fpd4", "fer0")
rotation <- c(90, 0, 340, 270, 140, 45)
sizex <- c(50, 50, 50, 100, 50, 100)
sizey <- sizex
incl.c <- c(FALSE, FALSE, FALSE, TRUE, FALSE, TRUE)

### do rotation
out <- do.call("rbind", lapply(seq(to.rotate), function(i) {
#   i <- 5
  
  ax <- apole$x[apole$PlotID == to.rotate[i]]
  ay <- apole$y[apole$PlotID == to.rotate[i]]
  ori <- rotation[i]
  sx <- sizex[i]
  sy <- sizey[i]
  wc <- incl.c[i]
  
  poles.new <- calcPoles(ax, ay, ori, sx, sy, C = wc)
  
  tmp <- subset(dat, PlotID == to.rotate[i])
  
  for (j in seq(poles.new)) {
    pole <- names(poles.new)[j]
    tmp@coords[, 1][tmp$PoleName == pole] <- poles.new[[j]]$x
    tmp@coords[, 2][tmp$PoleName == pole] <- poles.new[[j]]$y
  }
  return(tmp)
}))

### hom5 special case (rotate A, B1- B8 and T1 - T4 by 180 deg)
hom5 <- subset(dat, PlotID == "hom5")
hom5$PoleName <- as.character(hom5$PoleName)
poles.oldname <- c(paste(LETTERS[1], 1:4, sep = ""),
                   paste(LETTERS[2], 1:8, sep = ""),
                   paste(LETTERS[20], 1:4, sep = ""))
poles.newname.tmp <- c(paste(LETTERS[1], 4:1, ".n", sep = ""),
                       paste(LETTERS[2], 8:1, ".n", sep = ""),
                       paste(LETTERS[20], 4:1, ".n", sep = ""))
poles.newname <- c(paste(LETTERS[1], 4:1, sep = ""),
                   paste(LETTERS[2], 8:1, sep = ""),
                   paste(LETTERS[20], 4:1, sep = ""))

for (i in seq(poles.oldname)) {
  hom5$PoleName[hom5$PoleName == poles.oldname[i]] <- poles.newname.tmp[i]
}

for (i in seq(poles.oldname)) {
  hom5$PoleName[hom5$PoleName == poles.newname.tmp[i]] <- poles.newname[i]
}

### combine all modified plots
out2 <- rbind(out, hom5)

### find and replace modified plots in original data
ind <- dat$PlotID %in% unique(out2$PlotID)
dat <- dat[!ind, ]
out3 <- rbind(dat, out2)

### write to .shp
writeOGR(out3, "./data/PlotPoles_ARC1960_mod_20140410_v02_rotated/", 
         "PlotPoles_ARC1960_mod_20140410_v02_rotated", 
         driver = "ESRI Shapefile")
