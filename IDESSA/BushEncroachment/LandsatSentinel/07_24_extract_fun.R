
#####EXTRACT VALUES OF BUSH-CLASSIFICATION AND LANDSAT CHANNELS
library(rgeos)
library (plyr)

###GET DATA

bush_class_d <- "F:/HK_Geoinfo/lcc_reclass_veg50/"
bush_class <- list.files(bush_class_d, pattern=".tif$")
bush <- paste0(bush_class_d, bush_class)
dat <- "F:/HK_Geoinfo/lab/no02/dry/"
tc <- c("173078/", "173079/", "174078/")
dat_ac <- paste0(dat, tc)

#get all bush-classified tiles
rl <- list()
brl <- lapply(seq(bush_class), function(j){
  rl[j] <- raster(bush[j])
})

#get Landsat files, atmospheric correction done
ac <- character()
stac <- lapply(seq(dat_ac), function(j) {
  for (i in seq(6)){
    ac[i] <- paste0(dat_ac[j], list.files(dat_ac[j], pattern = paste0("atmcorrac_",i,".tif$")))
  }
  stack(ac)
})

####INPUT FUNCTION
#sat = stack satellite data, 
#width = radius of pixelsize satellite data
#tabnam = variable names for extraction table, character vector: first channels, 
  #then "bush-perc" (percentage bush cover), finally "bush_class_tile" (name of 
  #bush classification tile)
#out = where to write extracted tables as .csv

#make small sample
#Landsat: ! work without merged file: find out if extents match, then crop
ext <- brl[[289]]@extent
sat <- crop(stac[[1]], ext)
widthb <- 15
brgb <- brl[[289]] #bush rgb
tabnam <- c("ac_b_2_b", "ac_b_3_g", "ac_b_4_r", 
            "ac_b_5_NIR", "ac_b_6_SWIR1", "ac_b_6_SWIR2", "bush_perc",
            "bush_class_tile")
out <- "F:/HK_Geoinfo/data/2013_LC8/output/extraction/"

funex <- function(sat, widthb, brgb, tabnam, out){
  
  #buffer needs sp object
  p <- as(sat, 'SpatialPixels')
  spp <- SpatialPoints(p@coords, proj4string=CRS("+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
  
  #build buffer for Landsat pixels, width=radius
  buf <- list()
  for(i in seq(spp)){
    buf[i] <- gBuffer(spp[i], width=widthb, capStyle = "SQUARE", byid = F)
  }
  
  #function for returning percentage of bush coverage
  f50 <- function(x){
    z <- table(as.vector(x))["50"]
    return(z[[1]]/length(x[[1]]))
  }
  
  #extract percentage of bush coverage, for one (!) aerial image tile
  
  #start loop for all tiles here, brgb will need index
  extr <- lapply(seq(buf), function(j){
    ex <- extract(brgb, buf[[j]])
    perc <- f50(ex)
  })
  
  #extract landsat values
  extl <- lapply(seq(buf), function(j){
    ex <- extract(sat, buf[[j]])
  })
  
  
  #list -> df
  dfb <- ldply(extr, data.frame)
  dfl <- ldply(extl, data.frame)
  
  #combine dataframes
  nc <- ncol(dfl)+1
  dfl[,nc] <- dfb
  nc2 <- ncol(dfl)+1
  dfl[,nc2]<- replicate(nrow(dfl), brgb@data@names) 
  names(dfl) <- tabnam
  
  write.csv(dfl, file=paste0(out, paste0("extraction_", brgb@data@names , ".csv")))
  
  #finish loop here
}
  
funex(sat, width, brgb, tabnam, out)
