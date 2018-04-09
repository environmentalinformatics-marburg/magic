# prediction of model for entire sentinel scene

library(raster)
library(rgeos)

# collect data and organize it:
model <- get(load(paste0("D:/model/sentinelmodel.RData")))

# sentinel 1:
fls_sen1 <- list.files("F:/ludwig/sentinel1", pattern = "_tap.img$", full.names = TRUE)
# sentinel 2:
fls_sen2_01 <- list.files("F:/ludwig/sentinel2/S2A_USER_MTD_SAFL2A_PDMC_20160114_resampled.data",
                          pattern = ".img$", full.names = TRUE)[1:15]
fls_sen2_04 <- list.files("F:/ludwig/sentinel2/S2A_USER_MTD_SAFL2A_PDMC_20160403_resampled.data",
                          pattern = ".img$", full.names = TRUE)[1:15]
fls_sen2_07 <- list.files("F:/ludwig/sentinel2/S2A_USER_MTD_SAFL2A_PDMC_20160722_resampled.data",
                          pattern = ".img$", full.names = TRUE)[1:15]


# create satellite stack with propper names
sen1_01 <- raster(fls_sen1[1])
sen1_04 <- raster(fls_sen1[2])
sen1_07 <- raster(fls_sen1[3])
names(sen1_01) <- "sen1_01"
names(sen1_04) <- "sen1_04"
names(sen1_07) <- "sen1_07"
sen1 <- stack(sen1_01, sen1_04, sen1_07)
sen2_01 <- stack(fls_sen2_01)
sen2_04 <- stack(fls_sen2_04)
sen2_07 <- stack(fls_sen2_07)
names(sen2_01) <- paste0(names(sen2_01), "_01")
names(sen2_04) <- paste0(names(sen2_04), "_04")
names(sen2_07) <- paste0(names(sen2_07), "_07")
sen2 <- stack(sen2_01, sen2_04, sen2_07)

# one stack with all sentinel 1 & 2 bands
sen <- stack(sen1, sen2)
names(sen)
# clean up environment
rm(sen2_01, sen2_04, sen2_07, sen2, sen1, sen1_01, sen1_04, sen1_07, fls_sen1, fls_sen2_01, fls_sen2_04, fls_sen2_07)
gc()

# prediction
pre <- raster::predict(sen, model)
writeRaster(pre, "D:/summary_results/sentinel_prediction.tif")

