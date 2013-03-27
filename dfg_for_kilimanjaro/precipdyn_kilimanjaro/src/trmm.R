################################################################################
##  
##  This program converts TRMM NetCDF data to Idrisi RST format and evaluates
##  the TRMM time series against an in-situ record at Moshi, Tansania.
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

library("RNetCDF")
library("raster")
library("rgdal")
library("ncdf4")
library("ncdf")
library(lattice)

######################### CONVERT NETCDF TO IDRISI##############################
# Convert netCDF to Idrisi raster
# setwd("D:/temp/trmm_kilimandjaro/raw_data")
# setwd("/media/permanent/temp/trmm_kilimandjaro/raw_data")
# file_list <- list.files(pattern="*.nc")
# for (file in file_list) {
#   trmm_date <- substr(file,6,11)
#   trmm_hours <- as.numeric(format(as.Date(format(as.Date(format(as.Date(
#     trmm_date,"%y%m%d"), "%Y%m01"),
#                                                          "%Y%m%d")+31,"%Y%m01"), "%Y%m%d")-1, "%d")) * 24
#   out_fn <- paste('D:/temp/trmm_kilimandjaro/converted_data/', 
#                   substr(file,1,4), "_", substr(file,6,12), 'rst', sep="")
#   pcp <- raster(file, varname='pcp')
#   fun <- function(x) {x*trmm_hours}
#   pcp <- calc(pcp, fun)
#   projection(pcp) <- '+proj=longlat +datum=WGS84' 
#   print(out_fn)
#   writeRaster(pcp, filename=out_fn, format="IDRISI", overwrite=TRUE)
# }
################################### END ########################################



######################### TRMM vs. MOSHI RAINFALL ##############################
# Extract time seris for specific coordinate from TRMM dataset
# setwd("D:/temp/trmm_kilimandjaro/raw_data")
# setwd("/media/permanent/temp/trmm_kilimandjaro/raw_data")
# file_list <- list.files(pattern="*.nc")
# xtract <- function(file) {
#   trmm_date <- substr(file,6,11)
#   trmm_hours <- as.numeric(format(as.Date(format(as.Date(format(as.Date(
#     trmm_date,"%y%m%d"), "%Y%m01"),
#    "%Y%m%d")+31,"%Y%m01"), "%Y%m%d")-1, "%d")) * 24
#   ncf <- open.ncdf(file)
#   lat <- get.var.ncdf(ncf, "latitude")
#   lon <- get.var.ncdf(ncf, "longitude")
#   pcp <- get.var.ncdf(ncf, "pcp")
#   #fun <- function(x) {x*trmm_hours}
#   #pcp <- calc(pcp, fun)
#   lat_target = -3.363897
#   lon_target = 37.326444
#   lat_pos <- which.min(abs(lat-lat_target))
#   lon_pos <- which.min(abs(lon-lon_target))
#   pcp_target <- pcp[lon_pos, lat_pos] * trmm_hours
#   return(c(trmm_date, pcp_target))
# }
# 
# trmm_ts <- lapply(file_list, xtract)
# trmm_pcp <- as.numeric(sapply(trmm_ts, "[[", 2))
# trmm_time <- as.Date(sapply(trmm_ts, "[[", 1), "%y%m%d")
# 
# # Normal probability plot 
# hist(trmm_pcp)
# qqnorm(trmm_pcp)
# qqline(trmm_pcp)
# 
# # Shapiro test
# shapiro.test(trmm_pcp)
# 
# # Kolmogorov-Smirnov test
# ks.test(trmm_pcp, "pnorm", mean=mean(trmm_pcp), sd=sd(trmm_pcp))
# 
# # Moshi rainfall data
# setwd("/media/permanent/temp/trmm_kilimandjaro/station_data")
# ma <- read.csv("rainfall_moshi_airport_2000-2011_mm.csv")
# ma$Date <- as.Date(ma$Date , "%Y-%m-%d")
# summary(ma)
# class(ma)
# ma <- subset(ma, ma$Date <= "2011-06-01")
# 
# # Normal probability plot 
# hist(ma$Rainfall)
# qqnorm(ma$Rainfall)
# qqline(ma$Rainfall)
# 
# # Shapiro test
# shapiro.test(ma$Rainfall)
# 
# # Kolmogorov-Smirnov test
# ks.test(ma$Rainfall, "pnorm", mean=mean(ma$Rainfall), sd=sd(ma$Rainfall))
# 
# # Plot time series of Moshi and TRMM dataset
# plot(ma$Rainfall ~ ma$Date, type = 'o', col = 'red')
# lines(trmm_pcp ~ trmm_time)
# 
# # Compute correlation coefficients
# cor.test(ma$Rainfall,trmm_pcp, method="pearson")
# cor.test(ma$Rainfall,trmm_pcp, method="spearman")
# 
# # Linear regression
# lin_fit <- lm(ma$Rainfall ~ trmm_pcp)
# summary(lin_fit)
# ks.test(residuals(lin_fit), "pnorm", mean=mean(residuals(lin_fit)), sd=sd(residuals(lin_fit)))
# plot(ma$Rainfall~ trmm_pcp, asp=0.25)
# abline(lin_fit)
# 
# # Make scatterplot of time series of Moshi and TRMM dataset
# par(mfrow=c(2,2))
# plot(lin_fit)
# par(mfrow=c(1,1))
################################### END ########################################



####### BILINEAR INTERPOLATION vs. MOSHI RAINFALL ##############################
# Moshi rainfall data
setwd("/media/permanent/temp/trmm_kilimandjaro/station_data")
ma <- read.csv("rainfall_moshi_airport_2000-2011_mm.csv")
ma$Date <- as.Date(ma$Date , "%Y-%m-%d")
summary(ma)
class(ma)
ma <- subset(ma, ma$Date <= "2011-06-01")

# Normal probability plot 
hist(ma$Rainfall)
qqnorm(ma$Rainfall)
qqline(ma$Rainfall)

# Shapiro test
shapiro.test(ma$Rainfall)

# Kolmogorov-Smirnov test
ks.test(ma$Rainfall, "pnorm", mean=mean(ma$Rainfall), sd=sd(ma$Rainfall))

# Bilinear interpolated TRMM data for Moshi rainfall station 
setwd("/media/permanent/temp/trmm_kilimandjaro/point_data")
trmm_ma <- read.csv("3B43_00-11_moshi_airport_bilinear.csv", sep=";")
trmm_ma$Date <- as.Date(ma$Date , "3B43_%y%m%d")
summary(trmm_ma)

# Normal probability plot 
hist(trmm_ma$Rainfall)
qqnorm(trmm_ma$Rainfall)
qqline(trmm_ma$Rainfall)

# Shapiro test
shapiro.test(trmm_ma$Rainfall)

# Kolmogorov-Smirnov test
ks.test(trmm_ma$Rainfall, "pnorm", mean=mean(trmm_ma$Rainfall), sd=sd(trmm_ma$Rainfall))

# Plot time series of Moshi and TRMM dataset
plot(ma$Rainfall ~ ma$Date, type = 'o', col = 'red')
lines(trmm_ma$Rainfall ~ trmm_ma$Date)

# Compute correlation tests
cor.test(ma$Rainfall,trmm_ma$Rainfall, method="pearson")
cor.test(ma$Rainfall,trmm_ma$Rainfall, method="spearman")

# Linear regression
lin_fit <- lm(ma$Rainfall ~ trmm_ma$Rainfall)
summary(lin_fit)
ks.test(residuals(lin_fit), "pnorm", mean=mean(residuals(lin_fit)), sd=sd(residuals(lin_fit)))
plot(ma$Rainfall~ trmm_ma$Rainfall, asp=0.25)
abline(lin_fit)

# Make scatterplot of time series of Moshi and TRMM dataset
par(mfrow=c(2,2))
plot(lin_fit)
par(mfrow=c(1,1))
################################### END ########################################



############################# PLAYGROUND #######################################
# Subset of Moshi and TRMM without value 28, 99, 124
# ma_sub <- ma
# trmm_pcp_sub <- trmm_pcp
# exclude <- c(28,84,99)
# exclude <- c(121,23,16)
# exclude <- c(62,107,73)
# exclude <- c(16,127,72)
# exclude <- c(114,36,48)
# exclude <- c(29,24)
# exclude <- c(15,87)
# exclude <- c(98,76,75)
# exclude <- c(115,33)
# exclude <- c(83,3)
# exclude <- c(3,10,27)
# exclude <- c(65,46,67)
# ma_sub <- ma_sub[-exclude,]
# trmm_pcp_sub <- trmm_pcp_sub[-exclude]
# lin_fit_sub <- lm(ma_sub$Rainfall ~ trmm_pcp_sub)
# summary(lin_fit_sub)
# ks.test(residuals(lin_fit_sub), "pnorm", mean=mean(residuals(lin_fit_sub)), sd=sd(residuals(lin_fit_sub)))
# par(mfrow=c(2,2))
# plot(lin_fit_sub)
# par(mfrow=c(1,1))
# plot(ma)
# lines(ma_sub)
# 
# # Just a test to show the influence of data amount on normality tests
# a <- 140
# b <- 80
# c <- 0
# for(i in seq(b,a)) {
#   c <- c + choose(a,i)
# }
# print(c)
# p <- 1/(2^a)*c
# print(p)
# 
