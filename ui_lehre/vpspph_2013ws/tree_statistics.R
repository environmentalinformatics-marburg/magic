###### GLOBAL SETTINGS
library(spatstat)
library(latticeExtra)
library(sp)
library(plotKML)
library(grid)
library(rCharts)
library(automap)
library(raster)

### working directory
path <- "/media/windows/tappelhans/uni/marburg/lehre/2013/ws/spezielle/daten_burgwald"
setwd(path)
###


###### FUNCTION DEFINITIONS
### add radius to distance
addrad2dis <- function(cbh, dis) {
  r <- cbh / (2 * pi)
  dis + r / 100
}
###

### convert degrees to radians
deg2rad <- function(degrees) degrees * pi / 180
###

### define function to convert direction and distance to x y components
dirdis2xy <- function(dir, dis) {
  u <- -dis * sin(deg2rad(dir))
  x <- round(-u, 2)
  v <- -dis * cos(deg2rad(dir))
  y <- round(-v, 2)
  return(as.data.frame(cbind(x, y)))
}
###

### corner point calculation
calcCorners <- function(x.known, y.known, 
                        orientation,
                        size.x, size.y) {
  p1 <- data.frame(x = x.known, y = y.known)
  
  p2offset <- dirdis2xy(270 + orientation, size.x)
  p2 <- data.frame(x = p1$x + p2offset$x,
                   y = p1$y + p2offset$y)
  
  p4offset <- dirdis2xy(orientation, size.x)
  p4 <- data.frame(x = p1$x + p4offset$x,
                   y = p1$y + p4offset$y)
  
  p3offset <- dirdis2xy(270 + orientation, size.x)
  p3 <- data.frame(x = p4$x + p3offset$x,
                   y = p4$y + p3offset$y)
    
  return(list(P1 = p1,
              P2 = p2,
              P3 = p3,
              P4 = p4))
}
###
######

###### DATA INPUT
### read data
dat <- read.csv("complete.data.csv", stringsAsFactors = FALSE)
###

### remove duplicated trees
dat <- dat[!duplicated(dat$treeID), ]
###

### define known parameters
TNoffset <- 1.6
p1.x <- 481073.00
p1.y <- 5645524.00
ori <- 5
size.x <- 40
size.y <- 40
elevation <- 396
###
######

###### ACTUAL CALCULATIONS
### calculate slope adjusted distances & direction from true north
vert <- dirdis2xy(dat$inc, dat$dis)
dat$dis_adj <- addrad2dis(dat$cbh, vert$y)
dat$offset.z <- vert$x
dat$tree.loc.z <- vert$x

dat$dir.m <- dat$dir
dat$dir <- dat$dir + TNoffset
###

### corners (from known point)
corners <- calcCorners(x.known = p1.x, 
                       y.known = p1.y, 
                       orientation = ori + TNoffset, 
                       size.x = size.x, 
                       size.y = size.y)
###


### origin of corner points
origin.x <- lapply(seq(dat$origin), function(i) {
  corners[[dat$origin[i]]]$x
})

origin.y <- lapply(seq(dat$origin), function(i) {
  corners[[dat$origin[i]]]$y
})

dat$origin.x <- as.numeric(as.character(origin.x))
dat$origin.y <- as.numeric(as.character(origin.y))
###


## position of trees (from origins)
tree.offset <- dirdis2xy(dat$dir, dat$dis_adj)

dat$offset.x <- tree.offset$x
dat$offset.y <- tree.offset$y

dat$tree.loc.x <- dat$origin.x + dat$offset.x
dat$tree.loc.y <- dat$origin.y + dat$offset.y
###

### recursively calcualte origin points including tree origins
while (any(is.na(dat$origin.x))) {
  
  ind.mis <- which(is.na(dat$origin.x))
  
  vec.repx <- vector("numeric", length(ind.mis))
  vec.repy <- vector("numeric", length(ind.mis))
  for (i in seq(ind.mis)) {
    vec.repx[i] <- dat$tree.loc.x[dat$treeID == dat$origin[dat$origin %in% dat$treeID][i]]
    vec.repy[i] <- dat$tree.loc.y[dat$treeID == dat$origin[dat$origin %in% dat$treeID][i]]
  }
  
  dat$origin.x[ind.mis] <- vec.repx
  dat$origin.y[ind.mis] <- vec.repy
  
  tree.offset <- dirdis2xy(dat$dir, dat$dis_adj)
  
  dat$offset.x <- tree.offset$x
  dat$offset.y <- tree.offset$y
  
  dat$tree.loc.x <- dat$origin.x + dat$offset.x
  dat$tree.loc.y <- dat$origin.y + dat$offset.y
}
###


###### PLOTTING THE RESULTS
### plotting using lattice 
trees.p <- xyplot(tree.loc.y ~ tree.loc.x, data = dat, asp = "iso", 
                  col = brewer.pal(length(unique(dat$spec)), 
                                   "Set1")[as.factor(dat$spec)],
                  cex = dat$cbh / max(dat$cbh) * 3, pch = 19)

corners.df <- do.call("rbind", corners)
corners.df[5, ] <- corners.df[1, ]

corners.p <- xyplot(y ~ x, data = corners.df, type = "l", 
                    asp = "iso", col = "grey90", 
                    panel = function(...) {
                      grid.rect(gp = gpar(fill = "grey10"))
                      panel.xyplot(...)})

p <- corners.p + as.layer(trees.p)
print(p)
###


### points in google earth
dat.sp <- dat[complete.cases(dat), ]
coordinates(dat.sp) <- c("tree.loc.x", "tree.loc.y")
proj4string(dat.sp) <- "+proj=utm +ellps=WGS84 +zone=32 +units=m +north"

plotKML(dat.sp["spec"])
###


### points as html for presentation on the web
hp <- hPlot(x = "tree.loc.x", y = "tree.loc.y", data = dat, width = 90, 
            type = "bubble", group = "spec", digits = 20, size = "cbh")

hp$params$height <- 500
hp$params$width <- 500
hp$plotOptions(bubble = list(minSize = '1%', maxSize = '2%'))
hp$yAxis(gridLineWidth = 0)
hp
###


###### POINT PATTERN ANALYSIS
### define window
wndw <- owin(poly = list(x = corners.df[c(4:1), 1],
                         y = corners.df[c(4:1), 2]))
###

### create point pattern process (special object type for spatial analysis)
dat.ppp <- ppp(x = dat$tree.loc.x,
               y = dat$tree.loc.y,
               window = wndw)
###

### visual interpretation of point pattern (exploratory)
plot(dat.ppp)
plot(density(dat.ppp))
plot(Kest(dat.ppp))
plot(Lest(dat.ppp))
plot(pcf(dat.ppp))
###

### proper statistical analysis of point pattern (Monte Carlo simulation)
### statistical inference thorugh calculation of significance bands
#set.seed(234)
env <- envelope(dat.ppp, fun = Lest, nsim = 99)
plot(env)
###
######


# ###### CREATE DEM
# ### kriging interpolation of z values
# bbx <- dat.sp@bbox
# ext <- extent(bbx)
# grd <- raster(ext, 100, 100)
# 
# grd <- setValues(grd, rnorm(ncell(grd)))
# 
# spplot(grd)
# grdsp <- as(grd, "SpatialPixelsDataFrame")
# 
# 
# dem <- autoKrige(offset.z ~ 1, dat.sp, grdsp)
# plot(dem)
# 
# levelplot(topo.kr[[i]]@data$var1.pred ~ topo.kr[[i]]@coords[, 1] + 
#             #                     topo.kr[[i]]@coords[, 2], col.regions = clrs(1000)
