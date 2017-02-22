### environmental stuff -----

rm(list = ls(all = TRUE))

## packages
lib <- c("raster", "velox", "doParallel", "bfast")
jnk <- sapply(lib, function(x) library(x, character.only = TRUE))

## parallelization
cl <- makePSOCKcluster(3L)
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


### data processing: time series breakpoints per plot -----

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


### data processing: time series breakpoints per research area -----

## loop over research areas
bks <- parLapply(cl, c("alb", "hai", "sch"), function(area) {
  
  # status message
  cat("Starting with '", area, "'.\n", sep = "")
  
  # import available files
  fls <- list.files(paste0(getwd(), "/data/", area, "/MCD13Q1.006/whittaker/eot"), 
                    pattern = "yL5000.*.tif$", full.names = TRUE)
  
  fls <- fls[grep("1982001", fls):length(fls)] # 1982-2015
  rst <- raster::stack(fls)
  vlx <- velox::velox(rst)
  
  spy <- as(extent(rst), "SpatialPolygons")
  proj4string(spy) <- "+init=epsg:4326"
  mdv <- as.numeric(vlx$extract(spy, fun = median))
  mnv <- as.numeric(vlx$extract(spy, fun = mean))

  bfs <- foreach(i = list(mdv, mnv), j = 1:2) %do% {
    val <- ts(i, start = c(1982, 1), end = c(2015, 12), frequency = 24)
    out <- bfast(val, max.iter = 3)
    
    png(paste0(getwd(), "/out/bfast/", area, ifelse(j == 1, "_mdv", "_mnv"), ".png"), 
        width = 12, height = 15, units = "cm", res = 500)
    plot(out)
    dev.off()
    
    return(out)
  }
  
  names(bfs) <- c("median", "mean")
  saveRDS(bfs, file = paste0(getwd(), "/out/bfast/bfast_", area, ".rds"))

  return(bfs)
})

## deregister parallel backend
stopCluster(cl)
