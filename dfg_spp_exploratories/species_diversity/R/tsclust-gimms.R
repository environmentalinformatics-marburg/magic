library(TSclust)
library(raster)
library(foreach)
library(remote)

## set working directory
setwd("/media/fdetsch/data/exploratories")

## aqua-modis ndvi
mds <- list.files("data/rasters/sch/MYD13Q1.006/wht/eot", 
                  pattern = "yL5000.tif$", full.names = TRUE)
mds <- mds[13:length(mds)] # 1982-2015
mds <- stack(mds)
mat <- as.matrix(mds)

## shapefile data
# data("interest.rates")
shp <- list.files("data/shapefiles", pattern = "^poly.*polygon.*.shp", 
                  full.names = TRUE)

## extract plot time series
plots <- suppressWarnings(shapefile(shp[3]))
plots <- spTransform(plots, CRS = CRS("+init=epsg:4326"))

nms <- sapply(strsplit(plots@data$Name, " "), "[[", 1)
for (i in 1:nrow(plots@data)) {
  if (nchar(nms[i]) == 4) 
    plots@data$Name[i] <- paste0(substr(nms[i], 1, 3), 0, substr(nms[i], 4, 5))
  else
    plots@data$Name[i] <- nms[i]
}

spy <- as(extent(mds), "SpatialPolygons")
proj4string(spy) <- "+init=epsg:4326"

vld <- sapply(1:nrow(plots@data), function(i) rgeos::gIntersects(plots[i, ], spy))
plots <- plots[vld, ]

pts <- foreach(i = 1:nrow(plots@data), .combine = "cbind") %do% {
  ids <- cellFromPolygon(mds, plots[i, ], weights = TRUE)[[1]]
  pct <- sapply(ids[, 2], function(j) j / sum(ids[, 2]))
  
  ## calculate weighted sum
  val <- mat[ids, ]
  if (nrow(ids) > 1)
    val <- sapply(1:ncol(val), function(j) sum(val[, j] * pct))
  
  return(deseason(val, cycle.window = 24L))
}

pts <- ts(pts, start = c(1982, 1), deltat = 1/24, class = c("mts", "ts"), 
          names = sapply(strsplit(plots@data$Name, " "), "[[", 1))

dpred <- diss(pts, "DTWARP")

# hc.dpred <- hclust(dpred)
hc.dpred <- rioja::chclust(dpred)
plot(hc.dpred)

cuts <- cutree(hc.dpred, h = 6)

## extract corresponding simpson index
simpson <- read.csv("data/Simpson.csv", stringsAsFactors = FALSE)

g1 <- simpson$Simpson[match(names(cuts[cuts == 1]), simpson$PlotID)]
d1 <- data.frame("Cluster" = "1", "Simpson" = g1)
g2 <- simpson$Simpson[match(names(cuts[cuts == 2]), simpson$PlotID)]
d2 <- data.frame("Cluster" = "2", "Simpson" = g2)
g3 <- simpson$Simpson[match(names(cuts[cuts == 3]), simpson$PlotID)]
d3 <- data.frame("Cluster" = "3", "Simpson" = g3)
g4 <- simpson$Simpson[match(names(cuts[cuts == 4]), simpson$PlotID)]
d4 <- data.frame("Cluster" = "4", "Simpson" = g4)
g5 <- simpson$Simpson[match(names(cuts[cuts == 5]), simpson$PlotID)]
d5 <- data.frame("Cluster" = "5", "Simpson" = g5)
d <- rbind(d1, d2, d3, d4, d5)

# d$Cluster <- factor(d$Cluster, levels = c("1", "4", "2", "3"))
library(ggplot2)
ggplot(aes(x = Cluster, y = Simpson), data = d) + 
  geom_boxplot() + 
  theme_bw()


types <- read.csv2("data/17706.csv", stringsAsFactors = FALSE)
types$Forest_type <- sapply(strsplit(types$Forest_type, "_"), "[[", 1)

for (i in 1:5)
  print(table(types[match(names(cuts[cuts == i]), types$EP), 
                    c("Forest_type", "Mixture")]))
