# sentinel bush extraction
library(raster)
library(rgeos)
# collect data and organize it:

# classified tiles
tiles <- list.files("D:/classifiedTiles/", pattern = ".tif$", full.names = TRUE)

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

funex <- function(sat, brgb, out){
  # reproject lcc
  brgb <- raster::projectRaster(brgb, crs = crs("+init=epsg:32734"), method = "ngb")
  # calculate buffer size based on satellite data resolution
  widthb <- res(sat)[1] / 2
  
  
  # check if the tile overlaps with the satellite data
  if(is.null(intersect(extent(sat), extent(brgb)))){
    return(NULL)
  }
  else{
    # crop the satellite data
  sat <- crop(sat, brgb)
  # convert the raster to points and buffer them to square polygons matching the raster resolution
  p <- as(sat, 'SpatialPixels')
  spp <- SpatialPoints(p@coords, proj4string=CRS("+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
  buf <- gBuffer(spp, width = widthb, capStyle = "SQUARE", byid = TRUE)
  
  # direct extraction
  ex_sat <- extract(sat, buf, df = TRUE)
  ex_lcc <- extract(brgb, buf)
  ex_classes <- lapply(ex_lcc, function(x){
    data.frame(class_1 = length(which(x == 1)),
               class_2 = length(which(x == 2)),
               class_3 = length(which(x == 3)),
               class_4 = length(which(x == 4)),
               class_na = length(which(is.na(x))))
  })
  ex_classes <- do.call(rbind, ex_classes)
  ex <- cbind(ex_sat, ex_classes)
  ex$ID <- NULL
  ex$lcc_tile <- names(brgb)
  
  write.csv(ex, file=paste0(out, paste0("extraction_", brgb@data@names , ".csv")), row.names = FALSE)
  }
}

for(i in seq(852, length(tiles))){
  t <- raster(tiles[i])
  funex(sat = sen, brgb = t, out = "F:/ludwig/aerial_16/extraction/")
  print(i)
}


