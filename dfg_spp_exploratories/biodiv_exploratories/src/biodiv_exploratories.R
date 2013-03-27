################################################################################
##  
##  This program evaluates RapidEye-based land-cover indices against in situ
##  biodiversity datasets.
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
##  reports to admin@environmentalinformatics-marburg.de.
##
################################################################################

library(lattice)
library(latticeExtra)

path.data.win <- "D:/temp/biodiv"
path.data.lin <- "/media/permanent/temp/biodiv"

actsys <- Sys.info()['sysname']
if (actsys == "Windows") {
  wd <- path.data.win
  setwd(wd)
} else {
  wd <- path.data.lin
  setwd(wd)
}

plots.filename <- "6340.csv"     # "6340.csv" "5400.csv"
rpeye.filenames <- c("hai_30.csv")
rpeye.filenames <- c("sch_30.csv", "hai_30.csv")

lutid.org <- read.csv("plot_biomasse_nr_id.csv", header=TRUE, sep = ",")

plots.org <- read.csv(plots.filename, header=TRUE, sep = ",")
plots.org$GPID <- gsub(" ","",plots.org$GPID)

rpeye.id <- lapply(seq(length(rpeye.filenames)), function(i) {
  print(rpeye.filenames[i]) 
  rpeye.org <- read.csv(rpeye.filenames[i], header=TRUE, sep = ",")
  rpeye.org.id <- merge(lutid.org, rpeye.org, by="PlotID")
  rpeye.org.id$GPID <- gsub(" ","",rpeye.org.id$GPID)
  return(rpeye.org.id)
})

str(rpeye.id)
rpeye.id.comb <- as.data.frame(t(data.frame(
  sapply(data.frame(t(do.call("rbind", rpeye.id))), unlist))))
rpeye.id.comb$GPID <- as.character(rpeye.id.comb$GPID)

eval <- merge(plots.org, rpeye.id.comb, by="GPID")
eval$Range <- as.numeric(as.character(eval$Range))
eval$TA <- as.numeric(as.character(eval$TA))
eval$PR <- as.numeric(as.character(eval$PR))
eval$PRD <- as.numeric(as.character(eval$PRD))
eval$SHDI <- as.numeric(as.character(eval$SHDI))

eval.0045 <- subset(eval, eval$Range == 45)
eval.0100 <- subset(eval, eval$Range == 100)
eval.0200 <- subset(eval, eval$Range == 200)

cor(eval.0045$shannon_vascular_plants, eval.0045$SHDI, method = "spearman")
#cor(eval.0045$Diversitaet_Hs, eval.0045$SHDI, method = "spearman")

cor(eval.0100$shannon_vascular_plants, eval.0100$SHDI, method = "spearman")
#cor(eval.0100$Diversitaet_Hs, eval.0100$SHDI, method = "spearman")

cor(eval.0200$shannon_vascular_plants, eval.0200$SHDI, method = "spearman")
#cor(eval.0200$Diversitaet_Hs, eval.0200$SHDI, method = "spearman")

eval.lm <- lm(eval.0050$SHDI~eval.0050$shannon_vascular_plants)
summary(eval.lm)

plot(eval.0045$shannon_vascular_plants ~ eval.0045$SHDI,
     xlab = "Shannon-Index, Satellite", ylab = "Shannon-Index, in-situ")

plot(eval.0045$number_grasses ~ eval.0045$TA,
     xlab = "Shannon-Index, Satellite", ylab = "Shannon-Index, in-situ")


plot(eval.0100$shannon_vascular_plants ~ eval.0100$SHDI,
     xlab = "Shannon-Index, Satellite", ylab = "Shannon-Index, in-situ")

plot(eval.0200$shannon_vascular_plants ~ eval.0200$SHDI,
     xlab = "Shannon-Index, Satellite", ylab = "Shannon-Index, in-situ")
