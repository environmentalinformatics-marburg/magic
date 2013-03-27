################################################################################
##  
##  Just a cheat slip for neuronal network handling.
##  
################################################################################
##
##  Copyright (C) 2013 Thomas Nauss
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

library("neuralnet")

age <-    c(1,2,3,4,5,6,7,8,9,10)
parity <- c(0,1,1,1,0,1,0,0,1,1)
target <- age * 2*(parity+1)
training <- cbind(age, parity, target)

test.age <- c(5,4,2,6,7,9,10,11,1)
test.parity <- c(0,1,1,0,0,0,1,1,1)
test.target <- test.age * 2*(test.parity+1)
test <- cbind(test.age, test.parity)

nn <- neuralnet(target ~ age + parity, data=training, hidden=5)
print(nn)
plot(nn)

test.nn <- compute(nn, test)

print(cbind(test.nn$net.result, test.target))
plot(cbind(test.nn$net.result, test.target), col="blue")
abline(0,1, col="red")


# Check operation system and set paths.
actsys <- Sys.info()['sysname']
path.gis.win <- "D:/temp/kilimanjaro_ndvi_dynamics/gis"
path.gis.lin <- "/media/permanent/temp/kilimanjaro_ndvi_dynamics/gis"

if (actsys == "Windows") {
  wd <- path.gis.win
  setwd(wd)
} else {
  wd <- path.gis.lin
  setwd(wd)
}

gndvi.org.pdat <- read.table(file="gndvi.org.pdat.csv", sep = ",", dec = ".")
mndvi.org.kdat <- read.table(file="mndvi.org.kdat.bfast.csv", 
                             sep = ",", dec = ".")


ndvi <- c(mndvi.org.kdat[1,]$cof1, mndvi.org.kdat[1,]$cof2, mndvi.org.kdat[1,]$cof3,
          mndvi.org.kdat[1,]$fer0, mndvi.org.kdat[1,]$fer1, mndvi.org.kdat[1,]$fer2,
          mndvi.org.kdat[1,]$flm1, mndvi.org.kdat[1,]$flm2, mndvi.org.kdat[1,]$flm3, 
          mndvi.org.kdat[1,]$foc1, mndvi.org.kdat[1,]$foc2, mndvi.org.kdat[1,]$foc3,
          mndvi.org.kdat[1,]$gra1, mndvi.org.kdat[1,]$gra2, mndvi.org.kdat[1,]$gra3,
          mndvi.org.kdat[2,]$cof1, mndvi.org.kdat[2,]$cof2, mndvi.org.kdat[2,]$cof3,
          mndvi.org.kdat[2,]$fer0, mndvi.org.kdat[2,]$fer1, mndvi.org.kdat[2,]$fer2,
          mndvi.org.kdat[2,]$flm1, mndvi.org.kdat[2,]$flm2, mndvi.org.kdat[2,]$flm3, 
          mndvi.org.kdat[2,]$foc1, mndvi.org.kdat[2,]$foc2, mndvi.org.kdat[2,]$foc3,
          mndvi.org.kdat[2,]$gra1, mndvi.org.kdat[2,]$gra2, mndvi.org.kdat[2,]$gra3,
          mndvi.org.kdat[30,]$cof1, mndvi.org.kdat[30,]$cof2, mndvi.org.kdat[30,]$cof3,
          mndvi.org.kdat[30,]$fer0, mndvi.org.kdat[30,]$fer1, mndvi.org.kdat[30,]$fer2,
          mndvi.org.kdat[30,]$flm1, mndvi.org.kdat[30,]$flm2, mndvi.org.kdat[30,]$flm3, 
          mndvi.org.kdat[30,]$foc1, mndvi.org.kdat[30,]$foc2, mndvi.org.kdat[30,]$foc3,
          mndvi.org.kdat[30,]$gra1, mndvi.org.kdat[30,]$gra2, mndvi.org.kdat[30,]$gra3)
lucl <- c("cof", "cof", "cof", "fer", "fer", "fer", 
          "flm", "flm", "flm", "foc", "foc", "foc",
          "gra", "gra", "gra",
          "cof", "cof", "cof", "fer", "fer", "fer", 
          "flm", "flm", "flm", "foc", "foc", "foc",
          "gra", "gra", "gra",
          "cof", "cof", "cof", "fer", "fer", "fer", 
          "flm", "flm", "flm", "foc", "foc", "foc",
          "gra", "gra", "gra")
lucl <- c(1, 1, 1, 2, 2, 2, 
          3, 3, 3, 4, 4, 4,
          5, 5, 5,
          1, 1, 1, 2, 2, 2, 
          3, 3, 3, 4, 4, 4,
          5, 5, 5,
          1, 1, 1, 2, 2, 2, 
          3, 3, 3, 4, 4, 4,
          5, 5, 5)
lucl.training <- cbind(ndvi,lucl)

nn.lucl <- neuralnet(lucl ~ ndvi, data=lucl.training, hidden=10, threshold=0.05)

print(nn.lucl)

test.ndvi <- c(mndvi.org.kdat[10,]$cof1, mndvi.org.kdat[10,]$cof2, mndvi.org.kdat[10,]$cof3,
               mndvi.org.kdat[10,]$fer0, mndvi.org.kdat[10,]$fer1, mndvi.org.kdat[10,]$fer2,
               mndvi.org.kdat[10,]$flm1, mndvi.org.kdat[10,]$flm2, mndvi.org.kdat[10,]$flm3, 
               mndvi.org.kdat[10,]$foc1, mndvi.org.kdat[10,]$foc2, mndvi.org.kdat[10,]$foc3,
               mndvi.org.kdat[10,]$gra1, mndvi.org.kdat[10,]$gra2, mndvi.org.kdat[10,]$gra3)
test.ndvi <- cbind(test.ndvi)
test.lucl <- c(1, 1, 1, 2, 2, 2, 
          3, 3, 3, 4, 4, 4,
          5, 5, 5)

test.nn <- compute(nn.lucl, test.ndvi)
print(cbind(test.nn$net.result, test.lucl))