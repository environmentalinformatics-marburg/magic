n <- 3

## shapefile data
# data("interest.rates")
shp <- list.files("data/shapefiles", pattern = "^poly.*polygon.*.shp", 
                  full.names = TRUE)

## extract plot time series
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

pts <- ts(pts, start = c(1982, 1), deltat = 1/24, class = c("mts", "ts"), 
          names = sapply(strsplit(plots@data$Name, " "), "[[", 1))

dpred <- diss(pts, "EUCL")
dpred <- diss(pts, "DTWARP")

hc.dpred <- hclust(dpred)
# hc.dpred <- rioja::chclust(dpred)
plot(hc.dpred)

cuts <- cutree(hc.dpred, h = 15)

## extract corresponding simpson index
simpson <- read.csv("data/Simpson.csv", stringsAsFactors = FALSE)

types <- read.csv2("data/17706.csv", stringsAsFactors = FALSE)
types$Management <- sapply(strsplit(types$Forest_type_in_detail, "_"), "[[", 2)
types$Forest_type <- sapply(strsplit(types$Forest_type, "_"), "[[", 1)

d <- do.call("rbind", lapply(1:max(cuts), function(i) {
  data.frame(Cluster = as.character(i), 
             Simpson = simpson$Simpson[match(names(cuts[cuts == i]), simpson$PlotID)], 
             Management = types$Management[match(names(cuts[cuts == i]), simpson$PlotID)])
}))

# d$Cluster <- factor(d$Cluster, levels = c("1", "4", "2", "3"))
library(ggplot2)
ggplot(aes(x = Cluster, y = Simpson), data = d) + 
  geom_boxplot() + 
  theme_bw()

for (i in 1:5)
  print(table(types[match(names(cuts[cuts == i]), types$EP), 
                    c("Forest_type", "Mixture")]))
