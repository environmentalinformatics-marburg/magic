library(ggplot2)
library(lubridate)
library(reshape)
library(gridExtra)
library(RColorBrewer)

require(RcolorBrewer)
col <- brewer.pal(8, "brBG")



# set working directory
wd <- setwd("C:/Users/IOtte/Desktop/training/")


### load data

iso <- read.csv2("iso_calc_copy.csv", header = T)
  
ta200 <- read.csv("C:/Users/IOtte/Desktop/plot_air_temperatur/iso_ta200_monthly.csv", header = TRUE)

## Sort temperature data 
ta200 <- melt(ta200)
colnames(ta200) <- c("plotID", "date", "ta200")
ta200$year <- substr(ta200$date, 26,29)
ta200$mon <- substr(ta200$date, 31,32)
ta200 <- ta200[, -2]
ta200$date <- paste(ta200$year, ta200$mon, sep = "-")
ta200 <- ta200[, -3]
ta200 <- ta200[, -3]


## Aggregate iso plot data to monthly mean values
# build monthly mean values of d18-16, dD_H & dexcess

iso.mns <- aggregate(cbind(iso$d18_16, iso$dD_H, iso$d.excess), 
                          by = list(substr(iso$date_sample, 1, 7), 
                                    iso[, 4], iso[, 5], iso[, 6]),
                          FUN = "mean", na.rm = TRUE)

colnames(iso.mns) <- c("date", "plotID", "type", "elevation","d18_16", "dD_H", "dexcess")

# build monthly sums of amount_mm
amnt.smm <- aggregate(iso$amount_mm, 
                      by = list(substr(iso$date_sample, 1, 7), 
                                iso[, 4], iso[, 5], iso[, 6]), 
                      FUN = "sum", na.rm = TRUE)

colnames(amnt.smm) <- c("date", "plotID", "type", "elevation", "amount")


# merge monthly mean of d18-16 & dD_H and monthly sums of amount_mm
iso.mnth <- merge(iso.mns, amnt.smm)


## Merge iso.mns and ta200 to iso.ta200

iso.ta200 <- merge(iso.mnth, ta200)


## subsetting for better facility of instruction

#type <- lapply(types, function(i){
#  sub <- subset(iso, iso$type == i)
#})


### build plot for presentation
### each plot seperately

col.id.rn <- c("#3288bd", "#66c2a5", "#abdda4", "#e6f598", "#fee08b", "#fdae61", 
               "#f46d43", "#d53e4f")

leg.rn <- c("fer0", "fpd0", "fpo0", "foc0", "foc6", "flm1", "hom4", "sav5")


col.id.fg <- c("#3288bd", "#66c2a5", "#abdda4", "#e6f598", "#fee08b", "#fdae61", 
                "#f46d43")

leg.fg <- c("fer0", "fpd0", "fpo0", "foc0", "foc6", "flm1", "nkw1")


## d18O

iso.dD <- ggplot(subset(iso.ta200, iso.ta200[, 3] == "rain"), 
                  aes(x = date, y = d18_16, group = plotID, 
                      colour = plotID)) + 
  geom_line() + 
  scale_color_manual(values = col.id.rn, limits = leg.rn, name = "Plot ID SP1") + 
  ylab( expression(delta^{2}*D ~ "\u2030")) +
  xlab("") +
  scale_x_discrete(labels = c("11", "12", "01", "02", "03", "04", "05", "06", 
                              "07", "08", "09", "10", "11", "12", "01", "02", 
                              "03", "04", "05", "06", "07", "08", "09", "10",
                              "11")) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


## dexcess

iso.dexcess <- ggplot(subset(iso.ta200, iso.ta200[, 3] == "rain"), 
                      aes(x = date, y = dexcess, group = plotID, 
                      colour = plotID)) + 
  geom_line() + 
  scale_color_manual(values = col.id.rn, limits = leg.rn, name = "Plot ID SP1") + 
  ylab( expression(dexcess ~ "\u2030")) +
  xlab("") +
  scale_y_reverse() +
  scale_x_discrete(labels = c("11", "12", "01", "02", "03", "04", "05", "06", 
                              "07", "08", "09", "10", "11", "12", "01", "02", 
                              "03", "04", "05", "06", "07", "08", "09", "10",
                              "11")) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


## temperature

iso.ta.200 <- ggplot(subset(iso.ta200, iso.ta200[, 3] == "rain"), 
                    aes(x = date, y = ta200, group = plotID, 
                    colour = plotID)) + 
  geom_line() + 
  scale_color_manual(values = col.id.rn, limits = leg.rn, name = "Plot ID SP1") + 
  ylab("ta200 [??C]") +
  xlab("") +
  scale_x_discrete(labels = c("11", "12", "01", "02", "03", "04", "05", "06", 
                              "07", "08", "09", "10", "11", "12", "01", "02", 
                              "03", "04", "05", "06", "07", "08", "09", "10",
                              "11")) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


## amount

amount <- ggplot(subset(iso.ta200, iso.ta200[, 3] == "fog"), 
                    aes(x = date, y = amount, group = plotID, 
                        colour = plotID)) + 
  geom_line() + 
  scale_color_manual(values = col.id.fg, limits = leg.fg, name = "Plot ID SP1") + 
  ylab("fog [mm]") +
  xlab("") +
  scale_x_discrete(labels = c("11", "12", "01", "02", "03", "04", "05", "06", 
                              "07", "08", "09", "10", "11", "12", "01", "02", 
                              "03", "04", "05", "06", "07", "08", "09", "10",
                              "11")) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


## wind direction

## afterwards merging

d18.dex.amn.fg <- arrangeGrob(iso.d18, iso.dexcess, amount, ncol = 1, nrow = 3)

# print "iso.mns.mnth.amnt.18O"
png("out/iso_d18_dex_amn_fg.png", width = 20, height = 30, units = "cm", 
    res = 300, pointsize = 15)
print(d18.dex.amn.fg)
dev.off()
