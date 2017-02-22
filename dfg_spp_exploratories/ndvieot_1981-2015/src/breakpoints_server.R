### environmental stuff -----

rm(list = ls(all = TRUE))

## working directory
setwd("/media/memory01/data/exploratories/exploratories_ndvieot_1981-2015")

## packages
lib <- c("raster", "velox", "parallel", "bfast")
jnk <- sapply(lib, function(x) library(x, character.only = TRUE))

## parallelization
cl <- makePSOCKcluster(12L)
clusterExport(cl, "lib")
clusterEvalQ(cl, sapply(lib, function(x) library(x, character.only = TRUE)))


### data preprocessing: import and reformat research plots -----

## import data
lns <- readLines("data/plot_description.txt")

## loop over all plots available and extract relevant information
ids <- grep("plot:", lns)

stn <- do.call("rbind", lapply(ids, function(i) {
  cnt <- lns[i:(i+3)]
  spl <- strsplit(cnt, "\t")
  
  if (length(grep("Latitude|Longitude", cnt)) == 0) {
    val <- sapply(strsplit(cnt, "\t")[1:2], "[[", 2)
    data.frame(plot = val[1], category = val[2], Latitude = NA, Longitude = NA, 
               stringsAsFactors = FALSE)
  } else {
    val <- sapply(strsplit(cnt, "\t"), "[[", 2)
    data.frame(plot = val[1], category = val[2], Latitude = as.numeric(val[3]), 
               Longitude = as.numeric(val[4]), stringsAsFactors = FALSE)
  }
}))

## convert to Spatial*
stn <- stn[complete.cases(stn), ]
coordinates(stn) <- ~ Longitude + Latitude
proj4string(stn) <- "+init=epsg:4326"

## separate by research area
exp <- lapply(c("Alb", "Hainich", "Schorfheide"), function(i) {
  stn[grep(i, stn@data$category), ]
})

clusterExport(cl, "exp")


### data processing: time series breakpoints -----

## loop over research areas
n <- 1

for (area in c("alb", "hai", "sch")) {
  
  # status message
  cat("Starting with '", area, "'.\n", sep = "")
  
  # import available files
  fls <- list.files(paste0("data/", area, "/MCD13Q1.006/whittaker/eot"), 
                    pattern = "yL5000.*.tif$", full.names = TRUE)
  
  fls <- fls[grep("1982001", fls):length(fls)] # 1982-2015
  rst <- raster::stack(fls)
  vlx <- velox::velox(rst)
  
  # identify corresponding pixel per plot
  ref <- rst[[1]]
  cls <- raster::cellFromXY(rst, exp[[n]])

  # apply bfast algorithm to each pixel time series separately
  parallel::clusterExport(cl, c("cls", "ref", "vlx", "n"), 
                          envir = environment())
  
  jnk <- parallel::parLapply(cl, 1:length(cls), function(i) {
    tmp <- ref; tmp[][-cls[i]] <- NA
    spy <- raster::rasterToPolygons(tmp)
  
    val <- as.numeric(vlx$extract(spy, fun = mean))
    val <- ts(val, start = c(1982, 1), end = c(2015, 12), frequency = 24)
    bfs <- bfast::bfast(val, max.iter = 3)
    
    png(paste0(getwd(), "/out/bfast/", exp[[n]]@data[i, "plot"], ".png"), 
        width = 12, height = 15, units = "cm", res = 500)
    plot(bfs)
    dev.off()
    
    rm(bfs); return(invisible())
  })
  
  n <- n + 1
}

## deregister parallel backend
stopCluster(cl)
