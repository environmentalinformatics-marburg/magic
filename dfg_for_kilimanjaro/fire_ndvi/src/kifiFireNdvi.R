### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = setwd("/media/fdetsch/XChange/kilimanjaro/ndvi/"), 
       "Windows" = setwd("F:/kilimanjaro/ndvi"))

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal", "randomForest",
         "latticeExtra", "popbio", "zoo", "ggplot2")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

fun <- paste0("src/", c("probRst.R", "myMinorTick.R", 
                        "ndviCell.R", "evalTree.R", "splitRaster.R"))
sapply(fun, source)

# Parallelization
registerDoParallel(cl <- makeCluster(3))


### Data import

## MODIS NDVI 

# MODIS platforms
sensors <- c("mod13q1", "myd13q1")

# Time range
st_year <- "2001"
nd_year <- "2013"

# Import raster data and corresponding dates for each sensor separately
ndvi.rst.wht <- lapply(sensors, function(i) {
  # Import Whittaker-filled files (2003-2013)
  ndvi.fls <- list.files(paste0("data/processed/whittaker_", i), 
                         pattern = "^WHT.*.tif$", full.names = TRUE)
  
  st <- grep(ifelse(i == "mod13q1", st_year, "2003"), ndvi.fls)[1]
  nd <- grep(nd_year, ndvi.fls)[length(grep(nd_year, ndvi.fls))]
  
  ndvi.fls <- ndvi.fls[st:nd]
  ndvi.rst <- stack(ndvi.fls)
  
  # Import corresponding date information
  ndvi.fls.init <- list.files("data/MODIS_ARC/PROCESSED/ndvi_clrk", 
                              pattern = paste0(toupper(i), ".*_NDVI.tif$"))
  
  st_init <- grep(ifelse(i == "mod13q1", st_year, "2003"), ndvi.fls.init)[1]
  nd_init <- grep(nd_year, ndvi.fls.init)[length(grep(nd_year, ndvi.fls.init))]
  
  ndvi.fls.init <- ndvi.fls.init[st_init:nd_init]
  ndvi.dates <- as.Date(substr(ndvi.fls.init, 10, 16), format = "%Y%j")
  
  # List raster data and corresponding dates
  return(list(ndvi.rst, ndvi.dates))
})

# Rearrange raster layers according to date information
dates <- do.call("c", lapply(ndvi.rst.wht, "[[", 2))
index <- order(dates)
dates <- dates[index]

ndvi.stck.wht <- stack(lapply(ndvi.rst.wht, "[[", 1))
ndvi.stck.wht <- ndvi.stck.wht[[index]]

# Setup time series
ndvi.ts <- do.call("c", lapply(st_year:nd_year, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 8)
}))

# Identify available NDVI data based on continuous 8-day interval
ndvi.ts <- merge(data.frame(ndvi.ts, 1:length(ndvi.ts)), 
                 data.frame(dates, 1:length(dates)), by = 1, all.x = TRUE)

ndvi.rst.wht <- lapply(ndvi.ts[, 3], function(i) {
  if (is.na(i))
    return(NA)
  else
    return(ndvi.stck.wht[[i]])
})


## MODIS fire

# Import 8-day fire files (2001-2013)
fire.fls <- list.files("data/md14a1/aggregated/", 
                       pattern = "^aggsum_8day.*.tif$", full.names = TRUE)


# # Limit time window from Terra-MODIS launch to Dec 2013
st <- grep(st_year, fire.fls)[1]
nd <- grep(nd_year, fire.fls)[length(grep(nd_year, fire.fls))]
fire.fls <- fire.fls[st:nd]

# Setup time series
fire.dates <- substr(sapply(strsplit(basename(fire.fls), "_"), "[[", 4), 1, 7)
fire.dates <- as.Date(fire.dates, format = "%Y%j")

fire.ts <- do.call("c", lapply(st_year:nd_year, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 8)
}))

# Import aggregated fire data
fire.stck <- stack(fire.fls)

# Identify available fire data based on continuous 8-day interval
fire.ts <- merge(data.frame(fire.ts, 1:length(fire.ts)), 
                 data.frame(fire.dates, 1:length(fire.dates)), 
                 by = 1, all.x = TRUE)

fire.rst <- lapply(fire.ts[, 3], function(i) {
  if (is.na(i))
    return(NA)
  else
    return(fire.stck[[i]])
})

# Identification of fire scenes and fire pixels
fire.scenes <- foreach(i = fire.rst, .combine = "c", .packages = lib) %dopar% {
  if (class(i) != "logical") {maxValue(i) > 0} else {NA}
}


### NDVI prior to and after fire

## Convert fire / NDVI rasters to matrices

fire.mat <- foreach(i = fire.rst, .packages = lib) %dopar% as.matrix(i)
ndvi.mat <- foreach(i = ndvi.rst.wht, .packages = lib) %dopar% as.matrix(i)

# Deregister parallel backend (already implemented in upcoming functions)
stopCluster(cl)


## Identify fire cell in NDVI 

burnt.ndvi.cells <- ndviCell(fire.scenes = fire.scenes, 
                             fire.dates = fire.dates, 
                             fire.rst = fire.rst,
                             ndvi.rst = ndvi.rst.wht,
                             fire.mat = fire.mat, 
                             ndvi.mat = ndvi.mat, 
                             method = "temporal.change",
                             n.cores = 3)

# write.csv(burnt.ndvi.cells, "out/burnt_ndvi_cells.csv", 
#           row.names = FALSE, quote = FALSE)
# burnt.ndvi.cells <- read.csv("out/burnt_ndvi_cells.csv")


### Classification

## Evaluation (right now, ctree() is not used for prediction)

# # Calculate ctree() for varying bucket sizes
# eval.tree <- evalTree(independ = c(6, 7, 8), 
#                       depend = 4, 
#                       data = burnt.ndvi.cells, 
#                       minbucket = seq(50, 450, 50))

# # Store output
# write.csv(eval.tree, "out/ctree_scores.csv", quote = FALSE, row.names = FALSE)
# eval.tree <- read.csv("out/ctree_scores.csv")


## Probability calculation

# Classification tree
model <- randomForest(as.factor(fire) ~ ndvi + ndvi_diff + ndvi_meandev,
                      data = burnt.ndvi.cells)

# Probability rasters
prob.rst <- probRst(fire.scenes = fire.scenes, 
                    fire.dates = fire.dates, 
                    fire.rst = fire.rst,
                    ndvi.rst = ndvi.rst.wht,
                    fire.mat = fire.mat, 
                    ndvi.mat = ndvi.mat, 
                    model = model, 
                    n.cores = 3)

# Output storage
out.names <- paste(sapply(fire.rst[which(fire.scenes)], names), 
                   "prob.tif", sep = "_")

prob.rst <- foreach(i = prob.rst, j = seq(prob.rst)) %do% {
  if (!is.null(i))
    writeRaster(i, filename = paste0("out/ndvi_prob/", out.names[j]),  
                format = "GTiff", overwrite = TRUE)
}

# Response rasters
resp.rst <- probRst(fire.scenes = fire.scenes, 
                    fire.dates = fire.dates, 
                    fire.rst = fire.rst,
                    ndvi.rst = ndvi.rst.wht,
                    fire.mat = fire.mat, 
                    ndvi.mat = ndvi.mat, 
                    model = model, 
                    type = "response",
                    n.cores = 3)

# Output storage
out.names <- paste(sapply(fire.rst[which(fire.scenes)], names), 
                   "resp.tif", sep = "_")

resp.rst <- foreach(i = resp.rst, j = seq(resp.rst)) %do% {
  if (!is.null(i))
    writeRaster(i, filename = paste0("out/ndvi_resp/", out.names[j]),  
                format = "GTiff", overwrite = TRUE)
}


### Plotting stuff

## Fire events per month as time series

fire.ts.fls <- 
  merge(data.frame(date = fire.ts[, 1]), 
        data.frame(date = fire.dates, 
                   file = fire.fls, stringsAsFactors = FALSE), 
        by = "date", all.x = TRUE)

fire.ts.fls.cc <- fire.ts.fls[complete.cases(fire.ts.fls), ]
fire.ts.fls.cc$date <- factor(as.yearmon(fire.ts.fls.cc$date))

fire.rst.cc <- stack(fire.ts.fls.cc[, 2])
fire.rst.cc.agg <- 
  stackApply(fire.rst.cc, indices = as.numeric(fire.ts.fls.cc[, 1]), 
             fun = sum, filename = "out/fire_agg/fire_agg_mnth", 
             format = "GTiff", na.rm = TRUE, overwrite = TRUE)

fire.df.cc.agg <- data.frame(date = unique(fire.ts.fls.cc[, 1]), 
                             value = sapply(1:nlayers(fire.rst.cc.agg), function(i) {
                               sum(fire.rst.cc.agg[[i]][] > 0)
                             }))

png("out/fire_agg/fire_agg_mnth.png", units = "cm", width = 30, height = 9, 
    res = 300, pointsize = 12)
ggplot(aes(x = as.Date(as.yearmon(date)), y = value), data = fire.df.cc.agg) +
  geom_histogram(stat = "identity", fill = "black") + 
  labs(x = "Time [months]", y = "Number of fire pixels") + 
  theme_bw() + 
  theme(axis.title.x = element_text(size = rel(1.2)), 
        axis.text.x = element_text(size = rel(1)), 
        axis.title.y = element_text(size = rel(1.2)), 
        axis.text.y = element_text(size = rel(1)))
dev.off()

# Individual color scheme
my.bw.theme <- trellis.par.get()
my.bw.theme$box.rectangle$col = "grey80" 
my.bw.theme$box.rectangle$lwd = 2
my.bw.theme$box.umbrella$lwd = 2
my.bw.theme$box.umbrella$col = "grey80"
my.bw.theme$plot.symbol$col = "grey80"

foreach(i = c("burnt_ndvi_cells.csv", "burnt_ndvi_cells_dev.csv"), 
        j = c("tmp", "dev")) %do% {
          
  # Import data and transform information about fire occurence (0/1) to factor
  tmp.sub <- read.csv(paste0("out/", i))
  tmp.sub$fire <- factor(ifelse(burnt.ndvi.cells$fire == 0, "no", "yes"))
  
  
  ## Scatterplot with point density distribution and boxplots
  
  png(paste0("out/fire_ndvi_prepos_", j, ".png"), width = 20, height = 15, 
      units = "cm", pointsize = 16, res = 300)
  print(xyplot(fire ~ ndvi, data = tmp.sub,
         par.settings = my.bw.theme, 
         xlab = "NDVI", ylab = "Fire", panel = function(x, y) {
           panel.smoothScatter(x, y, nbin = 500, bandwidth = .1, cuts = 10, nrpoints = 0)
           panel.bwplot(x, y, box.ratio = .25, pch = "|", notch = TRUE, 
                        par.settings = my.bw.theme)
         }))
  dev.off()
  
  
  ## Densityplot
  
  png(paste0("out/dens_ndvi_", j, ".png"), width = 24, height = 15, units = "cm", 
      pointsize = 16, res = 300)
  print(ggplot(tmp.sub, aes(x = ndvi, fill = fire)) + 
    geom_density(alpha = .5) + 
    scale_fill_manual(values = c("no" = "black", "yes" = "red")) + 
    guides(fill = guide_legend(title = "Fire" ,
                               title.theme = element_text( face="plain", angle=0 ))) + 
    labs(x = "NDVI", y = "Density"))
  dev.off()
}