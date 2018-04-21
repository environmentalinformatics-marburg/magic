####INPUT FUNCTION
#sat = stack satellite data, 
#width = radius of pixelsize satellite data
#tabnam = variable names for extraction table, character vector: first channels, 
#then "bush-perc" (percentage bush cover), finally "bush_class_tile" (name of 
#bush classification tile)
#out = where to write extracted tables as .csv

################## read data ######################
require(raster)
require(rgdal)

#read raster images
datapath <- "F:/HK_Geoinfo/data/worldclim/"
f <- list.files(datapath, pattern="RData", full.names = T)
load(f)

stcomp <- stack(complete[[1]], complete[[2]], complete[[3]], complete[[4]],
      complete[[5]], complete[[6]], complete[[7]], complete[[8]])

#read bush tiles
bush_class_d <- "F:/HK_Geoinfo/data/L2016_final/classifiedTiles/"
bush <- list.files(bush_class_d, pattern=".tif$", full.names = T)

rl <- list()
brl <- lapply(seq(bush), function(j){
  rl[j] <- raster:: raster(bush[j])
})

#change names
sat <- stcomp
widthb <- 15 
brgb <- brl
out <- "F:/HK_Geoinfo/data/L2016_final/extr/"
newproj <- "+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"



funex <- function(sat, widthb, brgb, out){
  lapply(c(1:length(brgb)), function(k){
    brgb1 <- raster::projectRaster(brgb[[k]], crs = CRS("+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"), method = "ngb")
    ext <- brgb1@extent
    tryCatch(sat1 <- crop(sat, ext), error=function(e){print(c(k, "no overlap"))})
      
    if(exists("sat1")){
      #buffer needs sp object
      p <- as(sat1, 'SpatialPixels')
      spp <- SpatialPoints(p@coords, proj4string=CRS("+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
      
      #build buffer for Landsat pixels, width=radius
      buf <- rgeos::gBuffer(spp, width=widthb, capStyle = "SQUARE", byid=T)
      
      #function for returning percentage of bush coverage
      f50 <- function(x){
        p <- lapply(seq(length(x)), function(j){
          z <- table(as.vector(x[[j]]))["1"]
          (z[[1]]/length(x[[j]]))
        })
        return(p)
      }
      
      #extract percentage of bush coverage and landsat values
      exbrgb <- extract(brgb1, buf)
      perc <- f50(exbrgb)
      exsat <- extract(sat1, buf, df=T)
      #join tables
      exsat$bushperc <- unlist(perc) 
      exsat$tile <- k
      
      write.csv(exsat, file=paste0(out, paste0("extraction_", brgb1@data@names , ".csv")))
      print(k)
      flush.console()
    }
    
  })
}



plot(extent(sat[[1]]))
plot(extent(brgb1))

#extract  
funex(sat, widthb, brgb, tabnam, out)

#read all tables and merge them
fex <- list.files(out, full.names = T)
tex <- lapply(seq(fex), function(j){
  read.csv(fex[j], sep=",", dec=".")
})


mtex <- do.call("rbind", tex)
write.csv(mtex, file=paste0(out, "complete_ls8_extraction.csv"))


lengthx <- lapply(seq(length(exbrgb)), function(i){length(exbrgb[[i]])})
table(unlist(lengthx))

