################################################################################
##  
##  This program computes the air temperature gradient based on in-situ station
##  observations.
##  
################################################################################
##
##  Copyright (C) 2013 Thomas Nauss, Tim Appelhans
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##  Please send any comments, suggestions, criticism, or (for our sake) bug
##  reports to admin@environmentalinformatics-marburg.de
##
################################################################################

library(lattice)
library(latticeExtra)

path.gis.win <- "D:/temp/gradient"
path.data.win <- "D:/temp/gradient/data"

actsys <- Sys.info()['sysname']
if (actsys == "Windows") {
  wd <- path.gis.win
  datapath <- path.data.win
  setwd(wd)
} else {
  wd <- path.gis.lin
  datapath <- path.data.lin
  setwd(wd)
}


plots.org <- read.csv("plots.csv", header=TRUE, sep = ";")

setwd(datapath)
plots.clim.ext <- list()
plots.ids <- list()
for (plotid in plots.org$PlotId) {
  print(plotid)
  pattern <- paste("*",plotid,"*",sep="")
  fl.clim <- list.files(datapath, recursive = T, pattern = glob2rx(pattern))
  print(fl.clim)
  for (i in seq(fl.clim)){
    tmp <- read.csv(fl.clim[i], header=TRUE, sep = ",",
                    stringsAsFactors = FALSE)
    plots.ids <- c(plots.ids, tmp$PlotId)
    plots.clim.ext <- c(plots.clim.ext,
                        list(data.frame(PlotId = factor(tmp$PlotId),
                                    Ta_min = mean(tmp$Ta_200_min, na.rm = TRUE),
                                    Ta_max = mean(tmp$Ta_200_max, na.rm = TRUE),
                                    Ta_025 = mean(tmp$Ta_200_25, na.rm = TRUE),
                                    Ta_075 = mean(tmp$Ta_200_75, na.rm = TRUE))))
  }
}
plots.clim.ext <- data.frame(sapply(data.frame(do.call("rbind", plots.clim.ext)),
                                  unlist))
plots.clim.ext$PlotId <- plots.ids
plots.clim.ext$lct <- factor(substr(plots.clim.ext$PlotId,1,3))

bw01 <- bwplot(plots.clim.ext$Ta_max ~ plots.clim.ext$lct, col = "red")
bw02 <- bwplot(plots.clim.ext$Ta_min ~ plots.clim.ext$lct, col = "blue")
bw <- bw01 + bw02
plot(bw)

       
       
plots.lc <- c("sav", "mai", "cof", "sun", "gra", "hom", "flm", "foc", "fod", "fpo",
              "fpd", "fer", "hel")


clim.ext <- list()
clim.p.ext <- list()
clim.ext.tmp <- list()
lc <- "sav"
for (lc in plots.lc) {
  pattern <- paste("*",lc,"*",sep="")
  print(pattern)
  clim.fl <- list.files(datapath, recursive = T, pattern = glob2rx(pattern))
  setwd(datapath)
  clim.tmp <- list()
  plots <- list()
  tmp.plotid <- list()
  i <- 1
  for (i in seq(clim.fl)){
    tmp <- read.csv(clim.fl[i], header=TRUE, sep = ",", 
                    stringsAsFactors = FALSE)
    tmp.plotid <- c(tmp.plotid, tmp$PlotId)
    clim.ext.tmp <- c(clim.ext.tmp,
                  list(data.frame(PlotId = tmp$PlotId,
                                  Ta_min = mean(tmp$Ta_200_25, na.rm = TRUE),
                                  Ta_max = mean(tmp$Ta_200_75, na.rm = TRUE))))
  }
  clim.ext.tmp <- data.frame(sapply(data.frame(do.call("rbind", clim.ext.tmp)),
                               unlist))
  clim.ext.tmp$PlotId <- tmp.plotid
  temp.min <- mean(clim.ext.tmp$Ta_min)
  temp.max <- mean(clim.ext.tmp$Ta_max)
  
  clim.p.ext <- c(clim.p.ext,
                  list(data.frame(Plot = clim.ext.tmp$PlotId,
                                  Ta_min = clim.ext.tmp$Ta_min,
                                  Ta_max = clim.ext.tmp$Ta_max)))
  clim.ext <- c(clim.ext,
                list(data.frame(Plot = lc,
                                Ta_min = temp.min,
                                Ta_max = temp.max)))
}

clim.p.ext <- data.frame(sapply(data.frame(do.call("rbind", clim.p.ext)), unlist))


clim.ext <- data.frame(sapply(data.frame(do.call("rbind", clim.ext)), unlist))
clim.ext$Plot <- plots.lc
clim.ext$dT <- clim.ext$Ta_max - clim.ext$Ta_min

plot(factor(clim.ext$Plot),clim.ext$dT)


bwplot(clim.ext$Ta_max)





clim.ma.elev <- list()
clim.ma.elev.grad <- list()
par(new=FALSE)
lc <- "sav"
for (lc in plots.lc) {
  pattern <- paste("*",lc,"*",sep="")
  clim.fl <- list.files(datapath, recursive = T, pattern = glob2rx(pattern))
  setwd(datapath)
  clim.tmp <- list()
  plots <- list()
  i <- 1
  for (i in seq(clim.fl)){
    tmp <- read.csv(clim.fl[i], header=TRUE, sep = ",", 
                    stringsAsFactors = FALSE)
    plots <- c(plots,
               list(tmp$PlotId[i]))
    clim.tmp <- c(clim.tmp,
                  list(data.frame(Plot = tmp$PlotId[1],
                                  Ta_mm = mean(tmp$Ta_200, na.rm = TRUE))))
  }
  clim.mm <- data.frame(sapply(data.frame(do.call("rbind", clim.tmp)),
                               unlist))
  clim.mm$PlotId <- plots
  
  clim.ma <- aggregate(clim.mm$Ta_mm, by=list(clim.mm$Plot),
                       FUN=mean)
  colnames(clim.ma) <- c("PlotId", "Ta_ma")
  
  for (i in seq(NROW(clim.ma))) {
    clim.ma$PlotId[i] <- paste(lc, toString(clim.ma$PlotId[i]), sep="")
    
  }
  clim.ma.tmp <- merge(clim.ma, plots.org, by="PlotId")
  
  clim.ma.tmp.ord <- clim.ma.tmp[order(clim.ma.tmp$Elevation),]
#   clim.ma.tmp.ord.grad <- (min(clim.ma.tmp.ord$Ta_ma) - 
#      max(clim.ma.tmp.ord$Ta_ma)) /
#     (clim.ma.tmp.ord$Elevation[1] - 
#        clim.ma.tmp.ord$Elevation[length(clim.ma.tmp.ord$Elevation)]) * 100
  
   clim.ma.tmp.ord.grad <- (clim.ma.tmp.ord$Ta_ma[1] - 
                              clim.ma.tmp.ord$Ta_ma[length(clim.ma.tmp.ord$Ta_ma)]) /
     (clim.ma.tmp.ord$Elevation[1] - 
        clim.ma.tmp.ord$Elevation[length(clim.ma.tmp.ord$Elevation)]) * 100

  print(c(lc, clim.ma.tmp.ord$Elevation[1], 
          clim.ma.tmp.ord$Elevation[length(clim.ma.tmp.ord$Elevation)],
          clim.ma.tmp.ord$Elevation[1] - 
            clim.ma.tmp.ord$Elevation[length(clim.ma.tmp.ord$Elevation)],
          clim.ma.tmp.ord.grad[1]))
  clim.ma.elev.grad <- c(clim.ma.elev.grad,
                    list(data.frame(Plot = lc,
                                    dT = clim.ma.tmp.ord.grad)))
  clim.ma.elev <- c(clim.ma.elev,
                   list(clim.ma.tmp))
  
}
  par(new=FALSE)
clim.ma.elev <- data.frame(sapply(data.frame(do.call("rbind", clim.ma.elev)),
                             unlist))
clim.ma.elev.grad <- data.frame(sapply(data.frame(do.call("rbind", 
                                                          clim.ma.elev.grad)),
                                       unlist))
clim.ma.elev.grad$Plot <- plots.lc

plot(factor(clim.ma.elev.grad$Plot),clim.ma.elev.grad$dT)
abline(h=0)

plot(clim.ma.elev.grad$dT)
plots.lc

par(new=FALSE)
plot(wxt.ts.minute.mean$x ~ wxt.ts.minute.mean$Hour,
     col = "brown", ylim = c(miny, maxy))
par(new=TRUE)
plot(wxt.ta.minute.mean$x ~ wxt.ta.minute.mean$Hour,
     col = "red", ylim = c(miny, maxy))

plots.lc
