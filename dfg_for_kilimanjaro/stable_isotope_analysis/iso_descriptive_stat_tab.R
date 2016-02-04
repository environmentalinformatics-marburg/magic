# library(foreach)


# Check your working directory
wd <- setwd("C:/Users/IOtte/Desktop/training/")

## Read data
iso <- read.csv2("iso_calc.csv", header = T)


## for each available plot_id_sp1 and type
## calculate min, mean, max and range
## for d18_16 and dD_H, respectively

# d18_16

stats.d18.16 <- lapply(c("fog", "rain", "tf"), function(i){
  sub <- subset(iso, iso$type == i)
  subsub <- lapply(c("sav5", "hom4", "nkw1", "flm1", "foc6", "foc0",
                     "fpo0", "fpd0", "fer0"), function(j){
                       id.sp1 <- subset(sub, sub$plot_id_sp1 == j)
                       mi <- min(id.sp1[, 8], na.rm = TRUE)
                       mn <- mean(id.sp1[, 8], na.rm = TRUE)
                       ma <- max(id.sp1[, 8], na.rm = TRUE)
                       rng <- range(id.sp1[, 8], na.rm = TRUE)
    
                       return(data.frame(mi, mn, ma, rng))
                       })
  }) 


# dD_H

stats.dD.H <- lapply(c("fog", "rain", "tf"), function(i){
  sub <- subset(iso, iso$type == i)
  subsub <- lapply(c("sav5", "hom4", "nkw1", "flm1", "foc6", "foc0",
                     "fpo0", "fpd0", "fer0"), function(j){
                       id.sp1 <- subset(sub, sub[, 4] == j)
                       mi <- min(id.sp1[, 10], na.rm = TRUE)
                       mn <- mean(id.sp1[, 10], na.rm = TRUE)
                       ma <- max(id.sp1[, 10], na.rm = TRUE)
                       rng <- range(id.sp1[, 10], na.rm = TRUE)
    
                       return(data.frame(mi, mn, ma, rng))
                       })
 })




##### testing #####


#test <- lapply(levels(iso.rain$plot_id_sp1), subset(iso.rain, levels(iso.rain$plot_id_sp1)))
#iso.tab <- data.frame()

#test.mn <- foreach(levels(iso.rain[, 4]) %do% mean(iso.rain[, 8], na.rm = TRUE))


#d18.16.rain <- lapply(levels(iso.rain[, 4]), function(i){
#  id.sp1 <- subset(iso.rain, iso.rain[, 4] == i)
#  mi <- min(id.sp1$d18_16, na.rm = TRUE)
#  mn <- mean(id.sp1$d18_16, na.rm = TRUE)
#  ma <- max(id.sp1$d18_16, na.rm = TRUE)
#  rng <- range(id.sp1$d18_16, na.rm = TRUE)
  
#  return(data.frame(mn, mn, ma, range))
#}) 




