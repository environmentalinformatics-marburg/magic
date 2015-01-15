library(ggplot2)
library(lubridate)
# library(plyr) 


# Check your working directory
wd <- setwd("C:/Users/IOtte/Desktop/training/")

## Read data
iso <- read.csv2("iso_calc.csv", header = T)


##Preparation for plotting stuff
# color id for plotting
col.id <- c("orange", "blue", "purple", "black", "yellow", "red", "white", 
            "green", "brown","cornflowerblue", "pink")

col.id.machame <- c("orange", "purple", "black", "yellow", "red")

col.id.2 <- c("orange", "blue", "purple", "black", "yellow", "red", "white", 
              "green", "brown")

col.id.3 <- c("orange", "blue", "purple", "black", "yellow", "red", "darkgray", 
              "green", "brown")

# sort legends
leg <- c("fer0", "fpd0", "fpo0", "foc0", "foc6", "flm1", "nkw1", 
         "hom4", "sav5", "mnp1", "mnp2")

leg.ord <- c("fer0", "fpd0", "fpo0", "foc0", "foc6", "flm1", "nkw1", 
              "hom4", "sav5")


### Find regression line for all types of precipitation 
### for all data pairs available as well as differentiated 
### according to single sources (rainfall, fog and throughfall)

iso.sm <- summary(lm(dD_H ~ d18_16, data = iso))

## Plot all available data pairs and
## add local meteoric water line (lmwl) [Rsq 0.9348] and
## global meteoric water line (gmwl) according to Craig (1961) to plot

iso.all.lmwl.gmwl <- qplot(d18_16, dD_H, data = iso, color = plot_id_sp1, shape = type, 
                           xlab = "d18O%o \n
                           black line: LMWL dD = 14.87d18O + 7.44,
                           dashed: GMWL dD = 8d18O + 10",
                           ylab = "d2H%o") + 
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 14.87, slope = 7.44) + 
  geom_abline(intercept = 10, slope = 8, linetype = 2)

# print "iso.all.lmwl.gmwl"
png("out/iso.all.lmwl.gmwl.png", width = 22, height = 21, units = "cm", 
    res = 300, pointsize = 15)
print(iso.all.lmwl.gmwl)
dev.off()


# regressions for rain, fog & throughfall for all data pairs available
## -> lapply()
sm.rain <- summary(lm(dD_H ~ d18_16, data = subset(iso, iso$type == "rain")))
sm.fog <- summary(lm(dD_H ~ d18_16, data = subset(iso, iso$type == "fog"))) 
sm.tf <- summary(lm(dD_H ~ d18_16, data = subset(iso, iso$type == "tf")))


#test <- lapply(iso$type, lm(iso$dD_H ~ iso$d18_16))

#iso.all.lmwl.gmwl.diff <- qplot(d18_16, dD_H, data = iso, color = plot_id_sp1, shape = type,                                
#                                xlab = "d18O%o \n
#                                black line: LMWL dD = 14.87d18O + 7.44,
#                                dashed: GMWL dD = 8d18O + 10",
#                                ylab = "d2H%o") + 
#  facet_wrap( ~ type) +
#  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
#  geom_abline(intercept = 14.87, slope = 7.44) + 
#  geom_abline(intercept = 10, slope = 8, linetype = 2)




## Build mean values for every plot and each precipitation type
## and add GMWL and corresponding LMWL


d18.16.mns <- aggregate(iso$d18_16, by = list(iso$plot_id_sp1, iso$type), 
                        FUN = "mean", na.rm = TRUE)
colnames(d18.16.mns) <- c("plot_id_sp1", "type", "d18_16_mn")

dD.H.mns <- aggregate(iso$dD_H, by = list(iso$plot_id_sp1, iso$type), 
                      FUN = "mean", na.rm = TRUE)
colnames(dD.H.mns) <- c("plot_id_sp1", "type", "dD_H_mn")

iso.mns <- merge(d18.16.mns, dD.H.mns)

iso.mns.sm <- summary(lm(dD_H_mn ~ d18_16_mn, data = iso.mns))


#plot 
iso.mns.lmwl.gmwl <- qplot(d18_16_mn, dD_H_mn, data = iso.mns, shape = type,
                           colour = plot_id_sp1, xlab = "d18O%o \n 
                           black line: LMWL for mean values dD = 5.77d18O + 9.04, 
                           dotted: LMWL for each available data pair dD = 14.87d18O + 7.44,
                           dashed: GMWL dD = 8d18O + 10",
                           ylab = "d2H%o") + 
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 9.04, slope = 5.77) +
  geom_abline(intercept = 14.87, slope = 7.44, linetype = 3) +
  geom_abline(intercept = 10, slope = 8, linetype = 2) 


# print "iso.mns.lmwl.gmwl"
png("out/iso.mns.lmwl.gmwl.png", width = 22, height = 21, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.lmwl.gmwl)
dev.off()



iso.mns.lmwl.gmwl.diff <- qplot(d18_16_mn, dD_H_mn, data = iso.mns, shape = type,
                                colour = plot_id_sp1, xlab = "d18O%o \n 
                                black line: LMWL for mean values dD = 5.77d18O + 9.04, 
                                dotted: LMWL for each available data pair dD = 14.87d18O + 7.44,
                                dashed: GMWL dD = 8d18O + 10",
                                ylab = "d2H%o") + 
  facet_wrap( ~ type) +
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 9.04, slope = 5.77) +
  geom_abline(intercept = 14.87, slope = 7.44, linetype = 3) +
  geom_abline(intercept = 10, slope = 8, linetype = 2)


# print "iso.mns.lmwl.gmwl.diff"
png("out/iso.mns.lmwl.gmwl.diff.png", width = 30, height = 13, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.lmwl.gmwl.diff)
dev.off()



### Find regression line for all types of precipitation 
### of the machame transect for all data pairs available
###  for determing the influence of the amount effect

iso.machame <- subset(iso, iso$plot_id_sp1 %in% c("fer0", "fpo0", "foc0", 
                                                  "foc6", "flm1"))


### Regression machame transect only - test for "amount effect"
### of all available precipitation pairs, as well as differentiated 
### according to single sources (rainfall, fog and throughfall)

sm.all.machame <- summary(lm(dD_H ~ d18_16, data = iso.machame))

# machame rain
#rain.machame <- subset(iso.machame, iso.machame$type == "rain")
sm.rain.machame <- summary(lm(dD_H ~ d18_16, data = subset(iso.machame, iso.machame$type == "rain")))

# machame fog
#machame.fog <- subset(iso.machame, iso.machame$type == "fog")
sm.fog.machame <- summary(lm(dD_H ~ d18_16, data = subset(iso.machame, iso.machame$type == "fog")))  

# machame throughfall 
#machame.tf <- subset(iso.machame, iso.machame$type == "tf")
sm.tf.machame <- summary(lm(dD_H ~ d18_16, data = subset(iso.machame, iso.machame$type == "tf"))) 


# plot quick for overview 
sc.pl.machame <- qplot(d18_16, dD_H, data = iso.machame, color = plot_id_sp1, 
                       shape = type, xlab = "d18O%o", ylab = "d2H%o") + 
  scale_color_manual(values = col.id.machame, limits = c("fer0", "fpo0", "foc0", "foc6", "flm1")) +
  geom_abline(intercept = 10, slope = 8, linetype = 2) + 
  geom_abline(intercept = 16.88, slope = 7.78)


# faceting
# lmwl anpassen?
iso.machame.all <- qplot(d18_16, dD_H, data = iso.machame, color = plot_id_sp1, 
                           shape = type, xlab = "d18O%o \n 
                           black line fitted LMWL to all Machame data pairs dD = 7.78d18O + 16.88
                           dashed GMWL dD = 8d18O + 10",
                           ylab = "d2H%o") + 
  facet_wrap( ~ type) +
  scale_color_manual(values = col.id.machame, limits = c("fer0", "fpo0", "foc0", "foc6", "flm1"),
                     name = "Plot ID SP1") +
  geom_abline(intercept = 10, slope = 8, linetype = 2) + 
  geom_abline(intercept = 16.88, slope = 7.78)

# print "iso.machame.all"
png("out/iso.machame.all.png", width = 30, height = 11, units = "cm", 
    res = 300, pointsize = 15)
print(iso.machame.all)
dev.off()


### Regression machame transect only - test for "amount effect"
### of all available precipitation pairs, as well as differentiated 
### according to single sources (rainfall, fog and throughfall)
### --> compare highest (fer0) and lowest (flm1) plots 

## regression fer0 only

fer0 <- subset(iso.machame, iso.machame$plot_id_sp1 == "fer0")
sm.fer0 <- summary(lm(dD_H ~ d18_16, data = subset(iso.machame, iso.machame$plot_id_sp1 == "fer0")))  

# fer0 rain
#fer0.rain <- subset(fer0, fer0$type == "rain")
sm.fer0.rain <- summary(lm(dD_H ~ d18_16, data = subset(fer0, fer0$type == "rain")))

# fer0 fog
#fer0.fog <- subset(fer0, fer0$type == "fog")
sm.fer0.fog <- summary(lm(dD_H ~ d18_16, data = subset(fer0, fer0$type == "fog")))

# fer0 tf
#fer0.tf <- subset(fer0, fer0$type == "tf")
sm.fer0.tf <- summary(lm(dD_H ~ d18_16, data = subset(fer0, fer0$type == "tf")))


## regression flm1 only

flm1 <- subset(iso.machame, iso.machame$plot_id_sp1 == "flm1")
sm.flm1 <- summary(lm(dD_H ~ d18_16, data = subset(iso.machame, iso.machame$plot_id_sp1 == "flm1")))  

# flm1 rain
#flm1.rain <- subset(flm1, flm1$type == "rain")
sm.flm1.rain <- summary(lm(dD_H ~ d18_16, data = subset(flm1, flm1$type == "rain")))

# flm1 fog
#flm1.fog <- subset(flm1, flm1$type == "fog")
sm.flm1.fog <- summary(lm(dD_H ~ d18_16, data = subset(flm1, flm1$type == "fog")))

# flm1 tf
#flm1.tf <- subset(flm1, flm1$type == "tf")
sm.flm1.tf <- summary(lm(dD_H ~ d18_16, data = subset(flm1, flm1$type == "tf")))


## fpo0 foc0 und foc6 transparent?
## ansonsten ein plot mit nur fer0 & flm1 facet

iso.machame.bt.tp <- qplot(d18_16, dD_H, 
                           data = subset(iso.machame, iso.machame$plot_id_sp1 
                                         %in% c("fer0", "flm1")),
                           color = plot_id_sp1, 
                           shape = type, xlab = "d18O%o \n 
                           black line fitted LMWL to all Machame data pairs dD = 7.78d18O + 16.88
                           dashed GMWL dD = 8d18O + 10",
                           ylab = "d2H%o") + 
  facet_wrap( ~ type) +
  scale_color_manual(values = c("orange", "red"), limits = c("fer0", "flm1"),
                     name = "Plot ID SP1") +
  geom_abline(intercept = 10, slope = 8, linetype = 2) + 
  geom_abline(intercept = 16.88, slope = 7.78)

# print "iso.machame.bt.tp"
png("out/iso.machame.bt.tp.png", width = 30, height = 11, units = "cm", 
    res = 300, pointsize = 15)
print(iso.machame.bt.tp)
dev.off()



### No clear amount effect visible (yet), neither according to slope, 
### nor intercept build monthly sum of precipitation and monthly mean
### values of d18_16 & dD_H to check for seasonality
### volume-weighted neccessary? --> not implemented yet!!!


## formate iso date for aggregate/merging issues
iso$date_sample <- as.Date(iso$date_sample)
iso$year <- substr(iso$date_sample, 1, 4)
iso$mnth <- substr(iso$date_sample, 6, 7)
iso$yrmn <- paste(iso$year, iso$mnth, sep = "-")
iso$week <- week(iso$date_sample)
iso$yrweek <- paste(iso$year, iso$week, sep = "-")


# build monthly mean values of d18-16 & dD_H
iso.mns.mnth <- aggregate(cbind(iso$d18_16, iso$dD_H), by = list(iso$yrmn, iso$plot_id_sp1, 
                                                                 iso$type, iso$elevation),
                          FUN = "mean", na.rm = TRUE)

colnames(iso.mns.mnth) <- c("date", "plot_id_sp1", "type", "elevation","d18_16", "dD_H")

# build monthly sums of amount_mm
amnt.mns.mnth <- aggregate(iso$amount_mm, by = list(iso$yrmn, iso$plot_id_sp1, 
                                                    iso$type, iso$elevation), 
                           FUN = "sum", na.rm = TRUE)

colnames(amnt.mns.mnth) <- c("date", "plot_id_sp1", "type", "elevation","amount_mm")


# merge monthly mean of d18-16 & dD_H and monthly sums of amount_mm
# to create graphik
iso.mns.mnth.amnt <- merge(amnt.mns.mnth, iso.mns.mnth)


### d18_16O scale_x_continuous?
iso.mns.mnth.amnt.18O.pl <- ggplot(subset(iso.mns.mnth.amnt, 
                                  iso.mns.mnth.amnt$plot_id_sp1 != "mnp1" &
                                  iso.mns.mnth.amnt$plot_id_sp1 != "mnp2"), 
                         aes(x = date, y = d18_16, group = plot_id_sp1, 
                             colour = plot_id_sp1)) + 
  facet_grid(type ~ ., scales = "free") +
  geom_line() + 
  scale_color_manual(values = col.id.2, limits = leg.ord, name = "Plot ID SP1") + 
  ylab( expression(delta^{18}*O ~ "\u2030")) +
  xlab("") +
  scale_x_discrete(labels = c("12-11", "12-12", "13-01", "13-02", "13-03", "13-04",
                              "13-05", "13-06", "13-07", "13-08", "13-09", "13-10", 
                              "13-11", "13-12", "14-01", "14-02", "14-03", "14-04",
                              "14-05", "14-06", "14-07", "14-08", "14-09", "14-10",
                              "14-11")) +
  #scale_x_discrete(labels = substr(iso.mns.mnth.amnt$date, 3, 7)) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


# print "iso.mns.mnth.amnt.18O.pl"
png("out/iso.mns.mnth.amnt.18O.pl.png", width = 30, height = 20, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.mnth.amnt.18O.pl)
dev.off()




### dD_H
iso.mns.mnth.amnt.dDH.pl <- ggplot(subset(iso.mns.mnth.amnt, 
                                          iso.mns.mnth.amnt$plot_id_sp1 != "mnp1" &
                                          iso.mns.mnth.amnt$plot_id_sp1 != "mnp2"), 
                                   aes(x = date, y = dD_H, group = plot_id_sp1, 
                                       colour = plot_id_sp1)) + 
  facet_grid(type ~ .) +
  geom_line() + 
  scale_color_manual(values = col.id.2, limits = leg.ord, name = "Plot ID SP1") + 
  labs(x = "", y = expression(delta^{2}*H ~ "\u2030")) + 
  scale_x_discrete(labels = c("12-11", "12-12", "13-01", "13-02", "13-03", "13-04",
                              "13-05", "13-06", "13-07", "13-08", "13-09", "13-10", 
                              "13-11", "13-12", "14-01", "14-02", "14-03", "14-04",
                              "14-05", "14-06", "14-07", "14-08", "14-09", "14-10",
                              "14-11")) +
  #scale_x_discrete(labels = substr(iso.mns.mnth.amnt$date, 3, 7)) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


# print "iso.mns.mnth.amnt.dDH.pl"
png("out/iso.mns.mnth.amnt.dDH.pl.png", width = 30, height = 20, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.mnth.amnt.dDH.pl)
dev.off()

-----------------------------------------------

# strange values since 2014-05 --> visual check
iso.mns.mnth.amnt.18O.1405 <- ggplot(subset(iso.mns.mnth.amnt, 
                                            iso.mns.mnth.amnt$plot_id_sp1 != "mnp1" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "mnp2" & 
                                            iso.mns.mnth.amnt$plot_id_sp1 != "hom4" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "sav5" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "fpd0" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "nkw1" &
                                            iso.mns.mnth.amnt$date > "2014-05"),
                                     aes(x = date, y = d18_16, group = plot_id_sp1, 
                                         colour = plot_id_sp1)) + 
  facet_grid(type ~ .) +
  geom_line() + 
  scale_color_manual(values = col.id.machame) + 
  labs(x = "", y = expression(delta^{18}*O ~ "\u2030"))



# strange values since 2014-05 --> visual check
iso.mns.mnth.amnt.d2H.1405 <- ggplot(subset(iso.mns.mnth.amnt, 
                                            iso.mns.mnth.amnt$plot_id_sp1 != "mnp1" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "mnp2" & 
                                            iso.mns.mnth.amnt$plot_id_sp1 != "hom4" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "sav5" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "fpd0" &
                                            iso.mns.mnth.amnt$plot_id_sp1 != "nkw1" &
                                            iso.mns.mnth.amnt$date > "2014-05"),
                                     aes(x = date, y = dD_H, group = plot_id_sp1, 
                                         colour = plot_id_sp1)) + 
  facet_grid(type ~ .) +
  geom_line() + 
  scale_color_manual(values = col.id.machame) + 
  labs(x = "", y = expression(delta^{2}*H ~ "\u2030"))

--------------------------------------------------
--------------------------------------------------


  
  
### plot elevation gradient 
### d18_16O
iso.mns.mnth.elvtn.18O <- ggplot(subset(iso.mns.mnth.amnt, 
                                        iso.mns.mnth.amnt$plot_id_sp1 != "mnp1" &
                                        iso.mns.mnth.amnt$plot_id_sp1 != "mnp2"), 
                                 aes(x = elevation, y = d18_16, group = plot_id_sp1, 
                                     colour = plot_id_sp1)) + 
  facet_grid(type ~ ., scales = "free") +
  geom_boxplot() + 
  scale_color_manual(values = col.id.3, limits = leg.ord, name = "Plot ID SP1") + 
  ylab( expression(delta^{18}*O ~ "\u2030")) +
  xlab("elevation m a.s.l.") +
  scale_x_continuous(breaks = iso.mns.mnth.amnt$elevation) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


# print "iso.mns.mnth.elvtn.18O"
png("out/iso.mns.mnth.elvtn.18O.png", width = 30, height = 20, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.mnth.elvtn.18O)
dev.off()



### dD_H
iso.mns.mnth.elvtn.2DH <- ggplot(subset(iso.mns.mnth.amnt, 
                                        iso.mns.mnth.amnt$plot_id_sp1 != "mnp1" &
                                        iso.mns.mnth.amnt$plot_id_sp1 != "mnp2"), 
                                 aes(x = elevation, y = dD_H, group = plot_id_sp1, 
                                     colour = plot_id_sp1)) + 
  facet_grid(type ~ ., scales = "free") +
  geom_boxplot() + 
  scale_color_manual(values = col.id.3, limits = leg.ord, name = "Plot ID SP1") + 
  ylab( expression(delta^{2}*H ~ "\u2030")) +
  xlab("elevation m a.s.l.") +
  scale_x_continuous(breaks = iso.mns.mnth.amnt$elevation) +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


# print "iso.mns.mnth.elvtn.2DH"
png("out/iso.mns.mnth.elvtn.2DH.png", width = 30, height = 20, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.mnth.elvtn.2DH)
dev.off()


