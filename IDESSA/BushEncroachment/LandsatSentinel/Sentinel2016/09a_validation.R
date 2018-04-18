<<<<<<< HEAD
rm(list=ls())
library(caret)
library(randomForest)
#library(Rsenal)
source("/media/marvin/Seagate Expansion Drive/scripts/Rsenal_regressionStats.R")
library(viridis)

# todo: 
# predict on subsamples of testdata
# combine results in dataframe
# create one stat csv and graphic

# load rf model
model <- get(load(paste0("/media/marvin/Seagate Expansion Drive/model/sentinelmodel.RData")))
#Variable importance
pdf("/media/marvin/Seagate Expansion Drive/summary_results/varimp.pdf")
varImpPlot(model$finalModel,main="")
dev.off()

# load testdata
testdata <- readRDS("/media/marvin/Seagate Expansion Drive/model_validation/test_data.RDS")
testdata <- na.omit(testdata)
tiles <- as.character(unique(testdata$lcc_tile))
#tiles <- tiles[901:1103]
#testdata <- testdata[which(testdata$lcc_tile %in% tiles),]


# predict for each tile individually and calculate stats
tile_preds <- lapply(seq(length(tiles)), function(i){
  print(i)
  pred <- predict(model, newdata = testdata[testdata$lcc_tile == tiles[i], 1:48])
  stat <- regressionStats(pred, testdata[testdata$lcc_tile == tiles[i],]$bush_perc)
  stat$tile <- tiles[i]
  return(list(prediction = pred, stats = stat))
})

# separate the list
preds <- lapply(tile_preds, "[[", 1)
stats <- lapply(tile_preds, "[[", 2)

stat_df <- do.call(rbind, stats)

saveRDS(preds, "/media/marvin/Seagate Expansion Drive/model_validation/prediction_05.RDS")
write.csv(stat_df,"/media/marvin/Seagate Expansion Drive/model_validation/externalvalid_05.csv", row.names = FALSE)





# one validation

model <- get(load(paste0("D:/model/sentinelmodel.RData")))
testdata <- readRDS("D:/model_validation/test_data.RDS")
testdata <- na.omit(testdata)
source("D:/scripts/Rsenal_regressionStats.R")

pred <- predict(model, newdata = testdata[,1:48])
stat <- regressionStats(pred, testdata$bush_perc)

write.csv(stat, "D:/summary_results/external_valid_all.csv", row.names = FALSE)


=======
rm(list=ls())
library(caret)
library(randomForest)
#library(Rsenal)
source("/media/marvin/Seagate Expansion Drive/scripts/Rsenal_regressionStats.R")
library(viridis)

# todo: 
# predict on subsamples of testdata
# combine results in dataframe
# create one stat csv and graphic

# load rf model
model <- get(load(paste0("/media/marvin/Seagate Expansion Drive/model/sentinelmodel.RData")))
#Variable importance
pdf("/media/marvin/Seagate Expansion Drive/summary_results/varimp.pdf")
varImpPlot(model$finalModel,main="")
dev.off()

# load testdata
testdata <- readRDS("/media/marvin/Seagate Expansion Drive/model_validation/test_data.RDS")
testdata <- na.omit(testdata)
tiles <- as.character(unique(testdata$lcc_tile))
#tiles <- tiles[901:1103]
#testdata <- testdata[which(testdata$lcc_tile %in% tiles),]


# predict for each tile individually and calculate stats
tile_preds <- lapply(seq(length(tiles)), function(i){
  print(i)
  pred <- predict(model, newdata = testdata[testdata$lcc_tile == tiles[i], 1:48])
  stat <- regressionStats(pred, testdata[testdata$lcc_tile == tiles[i],]$bush_perc)
  stat$tile <- tiles[i]
  return(list(prediction = pred, stats = stat))
})

# separate the list
preds <- lapply(tile_preds, "[[", 1)
stats <- lapply(tile_preds, "[[", 2)

stat_df <- do.call(rbind, stats)

saveRDS(preds, "/media/marvin/Seagate Expansion Drive/model_validation/prediction_05.RDS")
write.csv(stat_df,"/media/marvin/Seagate Expansion Drive/model_validation/externalvalid_05.csv", row.names = FALSE)


>>>>>>> 0d7afbcdd96f3b0bc4a70532183a2c2f95e10fa2
