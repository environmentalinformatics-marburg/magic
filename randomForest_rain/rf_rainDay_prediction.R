##################################################
#### random forest regression #####
##################################################
# Clear workspace
rm(list=ls(all=TRUE))

## SET WORKING DIRECTORY
path.wd <- ("/home/mkuehnlein/randomForest/rf_regression/")
setwd(path.wd)

path.out <- "/home/mkuehnlein/randomForest/rf_regression/results/20130319_rain_day_vp02_"
path.dat <- "/home/mkuehnlein/randomForest/rf_input/dat/vp/rain_day_vp02/rfInput_day_vp02_"

## LOAD LIBRARY
library(raster)
library(latticeExtra)
library(randomForest)
library(foreach)
library(doSNOW)
library(parallel)

nummer <- c("v01","v02","v03","v04","v05","v06","v07","v08","v09","v10")
#for (i in 1:length(nummer[i])){
i = 5


### RandomForest stratiform

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainS/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)

## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)


###############################################################################################
### RandomForest convective

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainC/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)


## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)

##########################################################################################################
nummer <- c("v01","v02","v03","v04","v05","v06","v07","v08","v09","v10")
#for (i in 1:length(nummer[i])){
i = 8


### RandomForest stratiform

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainS/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)

## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)


###############################################################################################
### RandomForest convective

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainC/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)


## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)

####################################################################################################################################
nummer <- c("v01","v02","v03","v04","v05","v06","v07","v08","v09","v10")
#for (i in 1:length(nummer[i])){
i = 9


### RandomForest stratiform

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainS/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)

## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)


###############################################################################################
### RandomForest convective

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainC/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)


## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)

################################################################################################################################################
nummer <- c("v01","v02","v03","v04","v05","v06","v07","v08","v09","v10")
#for (i in 1:length(nummer[i])){
i = 10


### RandomForest stratiform

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainS/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainS_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)

## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)


###############################################################################################
### RandomForest convective

outpath <- paste(paste(path.out,nummer[i],sep=""),"/rainC/",sep="")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)
dir.create(paste(outpath,"rain_predicted/", sep = ""), recursive = FALSE, showWarnings = TRUE)
dir.create(paste(outpath,"rain_radolan/", sep = ""), recursive = FALSE, showWarnings = TRUE)
 

# READ DATA
filename <- paste(paste(paste(path.dat, "trainRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
trainData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")
 
 
unique(trainData$chDate)
nrow(trainData)
 

## training

set.seed(41)
## Parallel execution of randomForest via package 'foreach'
 
## Number of cores
n.cores <- detectCores() 
 
## Register SNOW parallel backend with 'foreach' package
registerDoSNOW(makeCluster(n.cores, type="SOCK"))
 
## Define desired parameters
n.tree <- 500
m.try <- 6
 
## Parallel execution of randomForest
system.time(train.rf <- foreach(ntree=rep(ceiling(n.tree/n.cores), n.cores), .combine=combine, .packages="randomForest") %dopar%
   randomForest(trainData[,5:ncol(trainData)-1], 
 	       trainData[ , names(trainData) %in% c("Rain")], 
 	       ntree=ntree, 
 	       mtry=m.try, 
 	       importance=TRUE, 
 	       do.trace = FALSE))

#rm(trainData)


## prediction 
 
## READ testData
filename <- paste(paste(paste(path.dat,"testRainC_",sep=""),nummer[i], sep=""),".dat",sep="")
testData <- read.table(filename, 
                    header=T, 
                    row.names=NULL, 
                    na.strings="-99.000000")

unique(testData$chDate)

##  predict Rain for new data set
test.predict <- predict(train.rf, testData[,1:ncol(testData)])

## writing prediction 
## convert factor to array 
Rain.predict <- test.predict
result <- cbind(testData,Rain.predict)
names(result)

# WRITE DATA
write.table(cbind(result$chDate,result$x,result$y,result$Rain,result$Rain.predict), 
file=paste(outpath,"prediction.dat", sep = "/"),
row.names = FALSE,
col.names = FALSE,
append = FALSE)


## copy and remove Rout
file.copy("rf_rainDay_prediction.Rout", outpath, copy.mode = TRUE)
file.remove("rf_rainDay_prediction.Rout")
