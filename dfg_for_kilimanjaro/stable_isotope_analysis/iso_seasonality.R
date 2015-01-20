library(ggplot2)
library(lubridate)

# Check your working directory
wd <- setwd("C:/Users/IOtte/Desktop/training/")

# Read data
iso.ssnl <- read.csv2("iso_calc.csv", header = T)

## iso.ssnl.ssnl Date
iso.ssnl$date_sample <- as.Date(iso.ssnl$date_sample)
iso.ssnl$year <- substr(iso.ssnl$date_sample, 1, 4)
iso.ssnl$mnth <- substr(iso.ssnl$date_sample, 6, 7)
iso.ssnl$yrmn <- paste(iso.ssnl$year, iso.ssnl$mnth, sep = "-")
iso.ssnl$week <- week(iso.ssnl$date_sample)
iso.ssnl$yrweek <- paste(iso.ssnl$year, iso.ssnl$week, sep = "-")

# col.id
col.id <- c("orange", "blue", "purple", "black", "yellow", "red", "white", 
            "green", "brown","cornflowerblue", "pink")

leg <- c("fer0", "fpd0", "fpo0", "foc0", "foc6", "flm1", "nkw1", 
         "hom4", "sav5", "mnp1", "mnp2")


## Subset MAM, JJA, SON, DJF
iso.ssnl.mam <- subset(iso.ssnl, iso.ssnl$mnth %in% c("03", "04", "05"))
iso.ssnl.jjas <- subset(iso.ssnl, iso.ssnl$mnth %in% c("06", "07", "08", "09"))
iso.ssnl.ond <- subset(iso.ssnl, iso.ssnl$mnth %in% c("10", "11", "12")) 
iso.ssnl.jf <- subset(iso.ssnl, iso.ssnl$mnth %in% c("01", "02"))
                   

## get linear model of each season
# MAM
summary(lm(dD_H ~ d18_16, data = iso.ssnl.mam))

sc.pl.mam <- qplot(d18_16, dD_H, data = iso.ssnl.mam, color = plot_id_sp1, 
                   shape = type, 
                   xlab = expression(delta^{18}*O ~ "\u2030"),
                   ylab = expression(delta^{2}*H ~ "\u2030")) + 
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") +  
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 15.68, slope = 7.65)


#JJAS
summary(lm(dD_H ~ d18_16, data = iso.ssnl.jjas))

sc.pl.jjas <- qplot(d18_16, dD_H, data = iso.ssnl.jjas, color = plot_id_sp1, 
                    shape = type, 
                    xlab = expression(delta^{18}*O ~ "\u2030"),
                    ylab = expression(delta^{2}*H ~ "\u2030")) + 
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 14.21, slope = 6.94)


# OND
summary(lm(dD_H ~ d18_16, data = iso.ssnl.ond))

sc.pl.ond <- qplot(d18_16, dD_H, data = iso.ssnl.ond, color = plot_id_sp1, 
                   shape = type, 
                   xlab = expression(delta^{18}*O ~ "\u2030"),
                   ylab = expression(delta^{2}*H ~ "\u2030")) +
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 12.22, slope = 7.08)


# JF
summary(lm(dD_H ~ d18_16, data = iso.ssnl.jf))

sc.pl.jf <- qplot(d18_16, dD_H, data = iso.ssnl.jf, color = plot_id_sp1, 
                  shape = type, 
                  xlab = expression(delta^{18}*O ~ "\u2030"),
                  ylab = expression(delta^{2}*H ~ "\u2030")) +
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 14.77, slope = 7.03)



## aggregate monthly type mean
# MAM
d18.16.mns.mam <- aggregate(iso.ssnl.mam$d18_16, 
                            by = list(iso.ssnl.mam$yrmn, iso.ssnl.mam$plot_id_sp1, 
                                      iso.ssnl.mam$type), FUN = "mean", na.rm = TRUE)
colnames(d18.16.mns.mam) <- c("yrmn", "plot_id_sp1", "type", "d18_16_mn")

dD.H.mns.mam <- aggregate(iso.ssnl.mam$dD_H, 
                          by = list(iso.ssnl.mam$yrmn, iso.ssnl.mam$plot_id_sp1, 
                                    iso.ssnl.mam$type), FUN = "mean", na.rm = TRUE)
colnames(dD.H.mns.mam) <- c("yrmn", "plot_id_sp1", "type", "dD_H_mn")

mns.agg.mam <- merge(d18.16.mns.mam, dD.H.mns.mam)
summary(lm(dD_H_mn ~ d18_16_mn, data = mns.agg.mam))

sc.pl.mam <- qplot(d18_16_mn, dD_H_mn, data = mns.agg.mam, color = plot_id_sp1, 
                   shape = type, 
                   xlab = expression(delta^{18}*O ~ "\u2030"),
                   ylab = expression(delta^{2}*H ~ "\u2030")) +
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 14.43, slope = 7.51)


# JJAS
d18.16.mns.jjas <- aggregate(iso.ssnl.jjas$d18_16, 
                             by = list(iso.ssnl.jjas$yrmn, iso.ssnl.jjas$plot_id_sp1, 
                                       iso.ssnl.jjas$type), FUN = "mean", na.rm = TRUE)
colnames(d18.16.mns.jjas) <- c("yrmn", "plot_id_sp1", "type", "d18_16_mn")

dD.H.mns.jjas <- aggregate(iso.ssnl.jjas$dD_H, 
                           by = list(iso.ssnl.jjas$yrmn, iso.ssnl.jjas$plot_id_sp1, 
                                     iso.ssnl.jjas$type), FUN = "mean", na.rm = TRUE)
colnames(dD.H.mns.jjas) <- c("yrmn", "plot_id_sp1", "type", "dD_H_mn")

mns.agg.jjas <- merge(d18.16.mns.jjas, dD.H.mns.jjas)
summary(lm(dD_H_mn ~ d18_16_mn, data = mns.agg.jjas))

sc.pl.jjas <- qplot(d18_16_mn, dD_H_mn, data = mns.agg.jjas, color = plot_id_sp1, 
                    shape = type, 
                    xlab = expression(delta^{18}*O ~ "\u2030"),
                    ylab = expression(delta^{2}*H ~ "\u2030")) +
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 13.23, slope = 6.51)



# OND
d18.16.mns.ond <- aggregate(iso.ssnl.ond$d18_16, 
                            by = list(iso.ssnl.ond$yrmn, iso.ssnl.ond$plot_id_sp1, 
                                      iso.ssnl.ond$type), FUN = "mean", na.rm = TRUE)
colnames(d18.16.mns.ond) <- c("yrmn", "plot_id_sp1", "type", "d18_16_mn")

dD.H.mns.ond <- aggregate(iso.ssnl.ond$dD_H, 
                          by = list(iso.ssnl.ond$yrmn, iso.ssnl.ond$plot_id_sp1, 
                                    iso.ssnl.ond$type), FUN = "mean", na.rm = TRUE)
colnames(dD.H.mns.ond) <- c("yrmn", "plot_id_sp1", "type", "dD_H_mn")

mns.agg.ond <- merge(d18.16.mns.ond, dD.H.mns.ond)
summary(lm(dD_H_mn ~ d18_16_mn, data = mns.agg.ond))

sc.pl.ond <- qplot(d18_16_mn, dD_H_mn, data = mns.agg.ond, color = plot_id_sp1, 
                   shape = type, 
                   xlab = expression(delta^{18}*O ~ "\u2030"),
                   ylab = expression(delta^{2}*H ~ "\u2030")) +
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 8.97, slope = 6.41)



# JF
d18.16.mns.jf <- aggregate(iso.ssnl.jf$d18_16, 
                           by = list(iso.ssnl.jf$yrmn, iso.ssnl.jf$plot_id_sp1, 
                                     iso.ssnl.jf$type), FUN = "mean", na.rm = TRUE)
colnames(d18.16.mns.jf) <- c("yrmn", "plot_id_sp1", "type", "d18_16_mn")

dD.H.mns.jf <- aggregate(iso.ssnl.jf$dD_H, 
                         by = list(iso.ssnl.jf$yrmn, iso.ssnl.jf$plot_id_sp1, 
                                   iso.ssnl.jf$type), FUN = "mean", na.rm = TRUE)
colnames(dD.H.mns.jf) <- c("yrmn", "plot_id_sp1", "type", "dD_H_mn")

mns.agg.jf <- merge(d18.16.mns.jf, dD.H.mns.jf)
summary(lm(dD_H_mn ~ d18_16_mn, data = mns.agg.jf))

sc.pl.jf <- qplot(d18_16_mn, dD_H_mn, data = mns.agg.jf, color = plot_id_sp1, 
                  shape = type, 
                  xlab = expression(delta^{18}*O ~ "\u2030"),
                  ylab = expression(delta^{2}*H ~ "\u2030")) +
  scale_color_manual(values = col.id, limits = leg, name = "Plot ID SP1") + 
  # text verbessern!
  annotate("text", x = -1.5, y = 17.5, parse = TRUE, size = 4,
           label = "expression(delta^{2}*H ~ "\u2030") == 14.18*d18O + 6.71") +
  geom_abline(intercept = 10, slope = 8, linetype = 2) +
  geom_abline(intercept = 14.18, slope = 6.71)


