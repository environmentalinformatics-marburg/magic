# molopo random sample
library(raster)
library(rgdal)
library(sp)
library(mapview)

# path to the tifs
fl_path <- "I:/env_info/original_data/UTM"

# load filepaths and names
tiles <- as.list(list.files(fl_path, recursive = TRUE, pattern = ".tif$", full.names = TRUE))
t_name <- list.files(fl_path, recursive = TRUE, pattern = ".tif$")


samp <- lapply(seq(length(tiles)), function(t){
  # load current rasterstack
  cur <- stack(tiles[[t]])
  ext <- as.list(cur@extent)
  
  # 1000m point grid over the raster
  grx <- numeric()
  px <- ext[1]+700
  while(px < ext[2]-1700){
  grx <- rbind(grx, px)
  px <- px+1000
  }
  gry <- numeric()
  py <- ext[3]+700
  while(py < ext[4]-1700){
    gry <- rbind(gry, py)
    py <- py + 1000
  }
  
  # choose random x and y coordinates
  set.seed(t)
  sampx <- sample(seq(grx), 2)
  set.seed(t+5)
  sampy <- sample(seq(gry), 2)
  
  return(data.frame(x = grx[sampx,], y = gry[sampy,]))
})

# combine the list entries
samp <- as.data.frame(do.call(rbind, samp))
samp$tile <- rep(t_name, each = 2)

sampsp <- samp
coordinates(sampsp) <- ~ x + y
projection(sampsp) <- CRS("+init=EPSG:32734")
writeOGR(sampsp, dsn = "I:/env_info/sample_points.shp", driver = "ESRI Shapefile", layer = "sample", overwrite = TRUE)

