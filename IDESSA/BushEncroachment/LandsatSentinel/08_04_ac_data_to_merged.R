#PROCESSING OF ATMOSPHERIC CORRECTED DATA

#install.packages("raster")
#install.packages("landsat")
#install.packages("RStoolbox")
library(raster)
library(rgdal)
library(landsat)
library(RStoolbox)

dat <- "F:/HK_Geoinfo/lab/no02/dry/"
tc <- c("173078/", "173079/", "174078/")
t <- c("173078", "173079", "174078")
dat_ac <- paste0(dat, tc)
out <- "F:/HK_Geoinfo/data/2013_LC8/output/ac_dry/"
out0 <- paste0(out, "under0/")
outsh <- paste0(out, "shapeunder0/")
out2 <- paste0(out, "ac_dry_0_2/")
outm <- paste0(out, "merged/")

#READ DATA ATMOSPHERIC CORRECTION (no thermal channels)
ac <- character()
stac <- lapply(seq(dat_ac), function(j) {
  for (i in seq(6)){
    ac[i] <- paste0(dat_ac[j], list.files(dat_ac[j], pattern = paste0("atmcorrac_",i,".tif$")))
  }
  stack(ac)
})


###ADDRESS NEGATIVE VALUES IN AC-RESULTS
#test for negative values
nc <- vector()
negval <- lapply(seq(tc), function (j){
  for (i in seq(6)){
    nc[i] <- sum(values(stac[[j]][[i]] < 0), na.rm=T)}
  nc
})

#which ones are negative? -> shapefile 
lapply(seq(stac), function(j){
  lapply(seq(6), function(i){
    if(sum(values(stac[[j]][[i]] < 0), na.rm=T)!=0){
      p <- rasterToPoints(stac[[j]][[i]], function(x) x < 0)
      poi <- SpatialPoints(p, proj4string = CRS("+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
      poidf = SpatialPointsDataFrame(poi, data.frame(dummy = rep(1,nrow(poi@coords))), proj4string = CRS("+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs")) 
      path <- paste0(outsh, paste0("shu0", j, i, ".shp"))
      writeOGR(poidf, layer= paste0("shu0", j, i), dsn = path, driver="ESRI Shapefile")
    print(c(j,i))
    flush.console()
    }else{print("no values under 0")}
  })
})

#read shapefiles with under 0 values
sh <- list.files(outsh, full.names =T, pattern=".shp")
shunder0 <- lapply(seq(sh), function(j){
  readOGR(sh[j])
})

#names for shapefile-list
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}
names(shunder0) <- substrRight(sh, 10)

#plot shapes with under 0 values
par(mfrow=c(3,2))
for(i in seq(shunder0)){
  plot(shunder0[[i]], pch=1)
  title(names(shunder0[i]))
}

#tile1
par(mfrow=c(2,2))
for(i in seq(1:4)){
  plot(stac[[1]][[1]])
  plot(shunder0[[i]], pch=1, add=T)
  title(names(shunder0[i]))
}

#tile2
par(mfrow=c(2,3))
for(i in c(5:10)){
  plot(stac[[2]][[1]])
  plot(shunder0[[i]], pch=1, add=T)
  title(names(shunder0[i]))
}

#tile3
par(mfrow=c(2,3))
for(i in c(11:15)){
  plot(stac[[3]][[1]])
  plot(shunder0[[i]], pch=1, add=T)
  title(names(shunder0[i]))
}

#all negative values in atmospheric correction are at the borders of 
#the tiles, except for the blue channel on tile 2.

#set negative values NA
stac2 <- lapply(seq(stac), function (k){
  for (i in seq(nlayers(stac[[1]]))){
    stac[[k]][[i]][stac[[k]][[i]] < 0] <- NA
    writeRaster(stac[[k]][[i]], paste0(out2, "dacf_", t[k], "_", i, ".tif"), format="GTiff", overwrite=T)
    print(paste0(out2, "dacf_", t, "_", i, ".tif"))
    flush.console()
  }
  stac[[k]]
})

#read rasters without < 0 values
no1 <- list.files(out2, full.names = T, pattern="173078")
no2 <- list.files(out2, full.names = T, pattern="173079")
no3 <- list.files(out2, full.names = T, pattern="174078")
no <- list(no1, no2, no3)

nounder0 <- list()
nonegval <- lapply(seq(no), function(i){
  nounder0[[i]] <- stack(no[[i]])
})

###MERGE TILES

#histogram matching: histograms of tile 2 and 3 are matched to that
#of tile one for channel 1 to 3, other channels can be matched without
#correction. hma's levels represent channels
hmac23 <- list()
hma <- lapply(seq(3), function(j){
  hmac2 <- histMatch(nonegval[[2]][[j]], nonegval[[1]][[j]])
  hmac3<- histMatch(nonegval[[3]][[j]], nonegval[[1]][[j]])
  hmac23[[j]] <- list(hmac2, hmac3)
})

#merging of channel 1 to 3
mos <- list()
mosc1_3 <- lapply(seq(3), function(j){
    mos[[j]] <- mosaic(nonegval[[1]][[j]], hma[[j]][[1]], hma[[j]][[2]], fun=mean) 
})
for(i in seq(mosc1_3)){
  writeRaster(mosc1_3[[i]], paste0(outm, "2013_md_c", i), format="GTiff", overwrite=T)
}

#merging of channel 4 to 6
mos <- list()
mosc4_6 <- lapply(c(4:6), function(j){
  mos[[j]] <- mosaic(nonegval[[1]][[j]], nonegval[[2]][[j]], nonegval[[3]][[j]], fun=mean) 
})
x <- (4:6)
for(i in seq(mosc4_6)){
  writeRaster(mosc4_6[[i]], paste0(outm, "2013_md_c", x[i]), format="GTiff", overwrite=T)
}

#read merged files
filesm <- list.files(outm, full.names = T)
merged <- stack(filesm)

#test
plot(merged)
plotRGB(merged, r=3, g=2, b=1, scale=2.2, stretch="lin")

