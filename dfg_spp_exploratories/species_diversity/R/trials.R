dim(pts)

## extract plot time series
dat <- do.call("rbind", lapply(1:3, function(n) {
  
  plots <- suppressWarnings(shapefile(shp[n]))
  plots <- spTransform(plots, CRS = CRS("+init=epsg:4326"))
  
  nms <- sapply(strsplit(plots@data$Name, " "), "[[", 1)
  for (i in 1:nrow(plots@data)) {
    if (nchar(nms[i]) == 4) 
      plots@data$Name[i] <- paste0(substr(nms[i], 1, 3), 0, substr(nms[i], 4, 5))
    else
      plots@data$Name[i] <- nms[i]
  }
  
  spy <- as(extent(mdss[[n]]), "SpatialPolygons")
  proj4string(spy) <- "+init=epsg:4326"
  
  vld <- sapply(1:nrow(plots@data), function(i) rgeos::gIntersects(plots[i, ], spy))
  plots <- plots[vld, ]
  
  pts <- foreach(i = 1:nrow(plots@data), .combine = "cbind") %do% {
    ids <- cellFromPolygon(mdss[[n]], plots[i, ], weights = TRUE)[[1]]
    pct <- sapply(ids[, 2], function(j) j / sum(ids[, 2]))
    
    ## calculate weighted sum
    val <- mats[[n]][ids, ]
    if (nrow(ids) > 1)
      val <- sapply(1:ncol(val), function(j) sum(val[, j] * pct))
    
    return(deseason(val[13:length(val)], cycle.window = 24L))
    # return(val[13:length(val)])
  }
  
  trd <- apply(pts, 2, FUN = function(x) significantTau(x, p = 1, prewhitening = FALSE))
  
  data.frame(PlotID = plots$Name, Trend = trd, 
             Simpson = simpson$Simpson[match(plots$Name, simpson$PlotID)], 
             types[match(plots$Name, types$EP), c("Forest_type", "Management")])
}))

xyplot(Simpson ~ Trend | Forest_type + Management, data = dat, 
       panel = function(x, y, ...) {
         panel.xyplot(x, y, ...)
         panel.ablineq(lm(y ~ x), r.squared = TRUE, rotate = TRUE)
       })

smi <- read.table("data/17746.txt", header = TRUE)
dat <- merge(dat, smi, by.x = "PlotID", by.y = "EP", all = TRUE)

## extract corresponding simpson index
simpson_all <- read.csv("data/Simpson_15_alllayers.csv", 
                        stringsAsFactors = FALSE, row.names = 1)
names(simpson_all) <- c("PlotID", "Simpson_All")
dat <- merge(dat, simpson_all, by = "PlotID", all = TRUE)

dat <- dat[complete.cases(dat), ]
# mod <- lm(Simpson ~ SMI + I(SMI^2), data = dat, na.action = na.omit)
mod <- lm(Simpson ~ SMI, data = dat, na.action = na.omit)
plot(dat$SMI, dat$Simpson, col = "grey75")
lines(dat$SMI, fitted(mod))

rsd <- residuals(mod)
cor(rsd, dat$Trend)

