library(ggplot2)
library(lubridate)


# Check your working directory
wd <- setwd("C:/Users/IOtte/Desktop/training/")

## Read data
iso <- read.csv2("iso_calc.csv", header = T)


##Preparation for plotting stuff
# color id for plotting later on
col.id <- c("orange", "red", "black", "yellow", "blue", "purple", "green", 
            "pink", "cornflowerblue", "white", "brown")
col.id.1 <- c("orange", "black", "blue", "purple", "green", "brown")


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

# plot for overview 

col.id.machame <- c("orange", "red", "black", "yellow", "purple")
sc.pl.machame <- qplot(d18_16, dD_H, data = iso.machame, color = plot_id_sp1, 
                       shape = type, xlab = "d18O%oGMWL", ylab = "d2H%oGMWL") + 
  scale_color_manual(values = col.id.machame)



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
iso.mns <- aggregate(cbind(iso$d18_16, iso$dD_H), by = list(iso$yrmn, iso$plot_id_sp1, iso$type),
                     FUN = "mean", na.rm = TRUE)
colnames(iso.mns) <- c("date", "plot_id_sp1", "type", "d18_16", "dD_H")

# build monthly sums of amount_mm
amnt.mns <- aggregate(iso$amount_mm, by = list(iso$yrmn, iso$plot_id_sp1, iso$type), 
                      FUN = "sum", na.rm = TRUE)
colnames(amnt.mns) <- c("date", "plot_id_sp1", "type", "amount_mm")


# merge monthly mean of d18-16 & dD_H and monthly sums of amount_mm
# to create graphik for publication
iso.mns.all <- merge(amnt.mns, iso.mns)


# plotting stuff

iso.mns.all$date <- factor(iso.mns.all$date)
### --> ???
iso.mns.all.pl <- ggplot(iso.mns.all, aes(x = date, y = d18_16, group = 1),
                         shape = type) + geom_line() 





