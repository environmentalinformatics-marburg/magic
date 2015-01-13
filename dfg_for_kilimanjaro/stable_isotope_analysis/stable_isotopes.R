library(ggplot2)
library(lubridate)
# library(plyr) 


# Check your working directory
wd <- setwd("C:/Users/IOtte/Desktop/training/")

## Read data
iso <- read.csv2("iso_calc.csv", header = T)


##Preparation for plotting stuff
# color id for plotting later on
col.id <- c("orange", "red", "black", "yellow", "blue", "purple", "green", 
            "pink", "cornflowerblue", "white", "brown")
col.id.1 <- c("orange", "black", "blue", "purple", "green", "brown")
col.id.2 <- c("orange", "blue", "purple", "black", "yellow", "red", "white", 
              "green", "brown")
col.id.3 <- c("orange", "red", "black", "yellow", "purple")

# sort legend
legend.order <- c("fer0", "fpd0", "fpo0", "foc0", "foc6", "flm1", "nkw1", 
                  "hom4", "sav5")


### Find regression line for all types of precipitation 
### for all data pairs available as well as differentiated 
### according to single sources (rainfall, fog and throughfall)

sc.pl <- qplot(d18_16, dD_H, data = iso, color = plot_id_sp1, shape = type, 
               xlab = "d18O%oGMWL", ylab = "d2H%oGMWL") + scale_color_manual(values = col.id)
sm.all <- summary(lm(dD_H ~ d18_16, data = iso))

# add local meteoric water line (lmwl) to plot
sc.pl.lmwl <- qplot(d18_16, dD_H, data = iso, xlab = "d18O%oGMWL", ylab = "d2H%oGMWL", 
                    geom = c("point", "smooth"), method = "lm", se = FALSE, 
                    formula = y ~ x) 

# add global meteoric water line (gmwl) according to Craig (1961) to plot
sc.pl.lmwl.gmwl <- sc.pl.lmwl + geom_abline(intercept = 10, slope = 8) 


## mean over all + regression line?



# regressions for rain, fog & throughfall for all data pairs available
## -> lapply()
sm.rain <- summary(lm(dD_H ~ d18_16, data = subset(iso, iso$type == "rain")))
sm.fog <- summary(lm(dD_H ~ d18_16, data = subset(iso, iso$type == "fog"))) 
sm.tf <- summary(lm(dD_H ~ d18_16, data = subset(iso, iso$type == "tf")))




### Find regression line for all types of precipitation 
### of the machame transect for all data pairs available
###  for determing the influence of the amount effect

iso.machame <- subset(iso, iso$plot_id_sp1 != "hom4" &
                        iso$plot_id_sp1 != "sav5" &
                        iso$plot_id_sp1 != "fpd0" &
                        iso$plot_id_sp1 != "nkw1" &
                        iso$plot_id_sp1 != "mnp1" &
                        iso$plot_id_sp1 != "mnp2")





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


# plot for overview 

col.id.machame <- c("orange", "purple", "black", "yellow", "red")

# Achsenbeschriftung formatieren --> Sonderzeichen???
# --> ??
sc.pl.machame <- qplot(d18_16, dD_H, data = iso.machame, color = plot_id_sp1, 
                       shape = type, xlab = "d18O%o", ylab = "d2H%o") + 
  scale_color_manual(values = col.id.machame, limits = c("fer0", "fpo0", "foc0", "foc6", "flm1")) +
  geom_abline(intercept = 10, slope = 8, linetype = 2) + 
  geom_abline(intercept = 16.88, slope = 7.78)




sc.pl.machame.all <- qplot(d18_16, dD_H, data = iso.machame, color = plot_id_sp1, 
                       shape = type, xlab = "d18O%o", ylab = "d2H%o") + 
  facet_wrap( ~ type) +
  scale_color_manual(values = col.id.machame, limits = c("fer0", "fpo0", "foc0", "foc6", "flm1")) +
  geom_abline(intercept = 10, slope = 8, linetype = 2) + 
  geom_abline(intercept = 16.88, slope = 7.78)




### Regression machame transect only - test for "amount effect"
### of all available precipitation pairs, as well as differentiated 
### according to single sources (rainfall, fog and throughfall)
### --> compare highest (fer0) and lowest (flm1) plots 

## regression fer0 only

#fer0 <- subset(iso.machame, iso.machame$plot_id_sp1 == "fer0")
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

#flm1 <- subset(iso.machame, iso.machame$plot_id_sp1 == "flm1")
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
iso.mns <- aggregate(cbind(iso$d18_16, iso$dD_H), by = list(iso$yrmn, iso$plot_id_sp1, iso$type, 
                                                            iso$elevation),
                     FUN = "mean", na.rm = TRUE)
colnames(iso.mns) <- c("date", "plot_id_sp1", "type", "d18_16", "dD_H")

# build monthly sums of amount_mm
amnt.mns <- aggregate(iso$amount_mm, by = list(iso$yrmn, iso$plot_id_sp1, iso$type, iso$elevation), 
                      FUN = "sum", na.rm = TRUE)
colnames(amnt.mns) <- c("date", "plot_id_sp1", "type", "amount_mm")


# merge monthly mean of d18-16 & dD_H and monthly sums of amount_mm
# to create graphik for publication
iso.mns.all <- merge(amnt.mns, iso.mns)


# plotting stuff

iso.mns.all$date <- factor(iso.mns.all$date)

### d18_16O
iso.mns.all.18O.pl <- ggplot(subset(iso.mns.all, 
                                  iso.mns.all$plot_id_sp1 != "mnp1" &
                                  iso.mns.all$plot_id_sp1 != "mnp2"), 
                         aes(x = date, y = d18_16, group = plot_id_sp1, 
                             colour = plot_id_sp1)) + 
  facet_grid(type ~ ., scales = "free") +
  geom_line() + 
  scale_color_manual(values = col.id.2, limits = legend.order, name = "Plot ID SP1") + 
  labs(x = "", y = "d18O%o") +
  theme(
    panel.grid.major = element_line(color = "lightgray", size = 0.01),
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(color = "gray", fill = NA))


# print "iso.mns.all.18O.pl"
png("out/iso.mns.all.18O.pl.2.png", width = 30, height = 20, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.all.18O.pl)
dev.off()


# strange values since 2014-05 --> visual check
iso.mns.all.18O.1405.pl <- ggplot(subset(iso.mns.all, 
                                    iso.mns.all$plot_id_sp1 != "mnp1" &
                                      iso.mns.all$plot_id_sp1 != "mnp2" & 
                                      iso.mns.all$plot_id_sp1 != "hom4" &
                                      iso.mns.all$plot_id_sp1 != "sav5" &
                                      iso.mns.all$plot_id_sp1 != "fpd0" &
                                      iso.mns.all$plot_id_sp1 != "nkw1" &
                                      iso.mns.all$date > "2014-05"),
                             aes(x = date, y = d18_16, group = plot_id_sp1, 
                                 colour = plot_id_sp1)) + 
  facet_grid(type ~ .) +
  geom_line() + 
  scale_color_manual(values = col.id.3) + 
  labs(x = "", y = "d18O%o")





### dD_H
iso.mns.all.dDH.pl <- ggplot(subset(iso.mns.all, 
                                    iso.mns.all$plot_id_sp1 != "mnp1" &
                                    iso.mns.all$plot_id_sp1 != "mnp2"), 
                             aes(x = date, y = dD_H, group = plot_id_sp1, 
                                 colour = plot_id_sp1)) + 
  facet_grid(type ~ .) +
  geom_line() + 
  scale_color_manual(values = col.id.2) + 
  labs(x = "", y = "d2H%o")


# print "iso.mns.all.dDH.pl"
png("out/iso.mns.all.dDH.pl.png", width = 30, height = 20, units = "cm", 
    res = 300, pointsize = 15)
print(iso.mns.all.dDH.pl)
dev.off()


# strange values since 2014-05 --> visual check
iso.mns.all.d2H.1405.pl <- ggplot(subset(iso.mns.all, 
                                         iso.mns.all$plot_id_sp1 != "mnp1" &
                                           iso.mns.all$plot_id_sp1 != "mnp2" & 
                                           iso.mns.all$plot_id_sp1 != "hom4" &
                                           iso.mns.all$plot_id_sp1 != "sav5" &
                                           iso.mns.all$plot_id_sp1 != "fpd0" &
                                           iso.mns.all$plot_id_sp1 != "nkw1" &
                                           iso.mns.all$date > "2014-05"),
                                  aes(x = date, y = dD_H, group = plot_id_sp1, 
                                      colour = plot_id_sp1)) + 
  facet_grid(type ~ .) +
  geom_line() + 
  scale_color_manual(values = col.id.3) + 
  labs(x = "", y = "d2H%o")

