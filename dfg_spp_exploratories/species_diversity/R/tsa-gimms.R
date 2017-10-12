### environmental stuff -----

## clear workspace 
rm(list = ls(all = TRUE))

## set working directory
setwd("/media/fdetsch/data/exploratories")

## load required packages
library(ESD)
library(remote)
library(gimms)
library(doParallel)
library(bfast)

## parallelization
cl <- makeCluster(detectCores() - 1)
registerDoParallel(cl)

## loop over areas
shp <- list.files("data/shapefiles", pattern = "^poly.*polygon.*.shp", 
                  full.names = TRUE)

out <- vector("list", 3L); n <- 1
for (exploratory in c("alb", "hai", "sch")) {
  
  # SEW12, SEW15, SEW01, SEW10
  ## import shapefile data
  plots <- suppressWarnings(shapefile(shp[n]))
  plots <- spTransform(plots, CRS = CRS("+init=epsg:4326"))
  
  ## import spatially resampled avhrr data
  gms <- list.files(paste0("data/rasters/", exploratory, 
                           "/MYD13Q1.006/wht/eot"), 
                    pattern = "yL5000.tif$", full.names = TRUE)
  gms <- stack(gms[13:length(gms)])
  mat <- as.matrix(gms)
  

  ### breakpoint analysis -----

  bps <- foreach(i = 1:nrow(plots@data), .combine = plyr::rbind.fill, 
                 .packages = c("raster", "bfast", "plyr")) %dopar% {
                   
    ids <- cellFromPolygon(gms, plots[i, ], weights = TRUE)[[1]]
    pct <- sapply(ids[, 2], function(j) j / sum(ids[, 2]))
    
    ## calculate weighted sum
    val <- mat[ids, ]
    if (nrow(ids) > 1)
      val <- sapply(1:ncol(val), function(j) sum(val[, j] * pct))
    
    ## run breakpoint analysis
    bfs <- bfast(ts(val, start = c(1982, 1), end = c(2015, 12), deltat = 1/24), 
                 season = "harmonic", max.iter = 5L)
    
    ## extract breakpoint characteristics (if any)
    ssn <- bfs$nobp$Wt
    trd <- bfs$nobp$Vt
    
    bps <- if (!ssn | !trd) {
      lst <- bfs$output[[length(bfs$output)]]
      
      # trend
      if (!trd) {
        tbp <- lst$ci.Vt$confint
        tbp <- cbind(tbp, "Magnitude" = rep(NA, nrow(tbp)), 
                     "Type" = rep(1, nrow(tbp))) # Trend = 1, Seasonal = 0
        tbp[bfs$Time == tbp[, 2], 4] <- bfs$Magnitude
      } else tbp <- NULL
      
      # seasonal
      if (!ssn) {
        sbp <- lst$ci.Wt$confint
        sbp <- cbind(sbp, "Type" = rep(0, nrow(sbp)))
      } else sbp <- NULL

      # output
      data.frame("PlotID" = plots[i, ]@data$Name, 
                 if (!is.null(tbp) & !is.null(sbp)) {
                   rbind.fill.matrix(tbp, sbp)
                 } else if (!is.null(tbp) & is.null(sbp)) {
                   tbp
                 } else sbp)
    } else NULL
  }
    
  ## write breakpoint data to disk
  names(bps) <- c("PlotID", "LCI", "Breakpoint", "UCI", "Magnitude", "Type")   
  write.csv(bps, paste0("out/breakpoints_", exploratory, ".csv"), 
            quote = FALSE, row.names = FALSE)
  
  out[[n]] <- bps
  n <- n + 1
}
  
## close parallel backend
stopCluster(cl)
