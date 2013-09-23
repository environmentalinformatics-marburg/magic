### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = {path.wd <- "/media/pa_NDown/ki_modis_ndvi/"}, 
       "Windows" = {path.wd <- "G:/ki_modis_ndvi"})
setwd(path.wd)

# Required packages and functions
lib <- c("doParallel", "raster", "rgdal", "party", 
         "latticeExtra", "popbio", "ggplot2")
sapply(lib, function(x) stopifnot(require(x, character.only = T)))

fun <- paste("src", c("kifiAggData.R", "probRst.R", "myMinorTick.R", 
                      "ndviCell.R", "evalTree.R"), sep = "/")
sapply(fun, source)

# Parallelization
registerDoParallel(cl <- makeCluster(4))


### Data import

## MODIS NDVI 

# List files and order by date
ndvi.fls <- list.files("data/quality_control/", recursive = T, full.names = T)

ndvi.dates <- substr(basename(ndvi.fls), 13, 19)
ndvi.years <- unique(substr(basename(ndvi.fls), 13, 16))

ndvi.fls <- ndvi.fls[order(ndvi.dates)]

# Setup time series
ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 8)
}))

# Merge time series with available NDVI files
ndvi.ts.fls <- merge(data.frame(date = ndvi.ts), 
                     data.frame(date = as.Date(ndvi.dates, format = "%Y%j"), 
                                file = ndvi.fls, stringsAsFactors = F), 
                     by = "date", all.x = T)

# Import raster files
ndvi.rst <- foreach(i = seq(nrow(ndvi.ts.fls)), .packages = lib) %dopar% {
  if (is.na(ndvi.ts.fls[i, 2])) {
    NA
  } else {
    raster(ndvi.ts.fls[i, 2])
  }
}


## MODIS fire

# Daily data: import raster files and aggregate on 8 days
aggregate.exe <- T

if (aggregate.exe) {
  # List files
  fire.fls <- list.files("data/reclass/md14a1", full.names = TRUE, pattern = ".tif$")
  
  # Setup time series
  fire.dates <- substr(basename(fire.fls), 8, 14)
  fire.years <- unique(substr(basename(fire.fls), 8, 11))
  
  fire.dly.ts <- do.call("c", lapply(fire.years, function(i) { 
    seq(as.Date(paste(i, "01", "01", sep = "-")), 
        as.Date(paste(i, "12", "31", sep = "-")), 1)
  }))
  
  # Merge time series with available fire data
  fire.dly.ts.fls <- merge(data.frame(date = fire.dly.ts), 
                           data.frame(date = as.Date(fire.dates, format = "%Y%j"), 
                                      file = fire.fls, stringsAsFactors = F), 
                           by = "date", all.x = T)
  
  fire.rst <- unlist(kifiAggData(
    data = fire.dly.ts.fls, 
    years = fire.years, 
    over.fun = max, 
    dsn = "G:/ki_modis_ndvi/data/overlay/md14a1_agg/", 
    out.str = "md14a1", format = "GTiff", overwrite = T, 
    out.proj = "+init=epsg:32737", n.cores = 4
  ))
} 


# Aggregated data: list files
fire.fls <- list.files("data/overlay/md14a1_agg", pattern = "md14a1.*.tif$", full.names = TRUE)

# Setup time series
fire.dates <- substr(basename(fire.fls), 8, 14)
fire.years <- unique(substr(basename(fire.fls), 8, 11))

fire.ts <- do.call("c", lapply(fire.years, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 8)
}))

# Merge time series with available fire data
fire.ts.fls <- merge(data.frame(date = fire.ts), 
                     data.frame(date = as.Date(fire.dates, format = "%Y%j"), 
                                file = fire.fls, stringsAsFactors = F), 
                     by = "date", all.x = T)

# Import aggregated fire data
if (!exists("fire.rst"))
fire.rst <- foreach(i = seq(nrow(fire.ts.fls)), .packages = lib) %dopar% {
  if (is.na(fire.ts.fls[i, 2])) {
    NA
  } else {
    raster(fire.ts.fls[i, 2])
  }
}

# Identification of fire scenes and fire pixels
fire.scenes <- foreach(i = fire.rst, .combine = "c", .packages = lib) %dopar% {
  if (class(i) != "logical") {maxValue(i) > 0} else {NA}
}


### NDVI prior to and after fire

## Convert fire / NDVI rasters to matrices

fire.mat <- foreach(i = fire.rst, .packages = lib) %dopar% as.matrix(i)
ndvi.mat <- foreach(i = ndvi.rst, .packages = lib) %dopar% as.matrix(i)


## Identify fire cell in NDVI 

burnt.ndvi.cells <- ndviCell(fire.scenes = fire.scenes, 
                             fire.ts.fls = fire.ts.fls, 
                             fire.rst = fire.rst,
                             ndvi.rst = ndvi.rst,
                             fire.mat = fire.mat, 
                             ndvi.mat = ndvi.mat, 
                             n.cores = 4)

# write.csv(burnt.ndvi.cells, "out/burnt_ndvi_cells.csv", row.names = F, quote = F)
# burnt.ndvi.cells <- read.csv("out/burnt_ndvi_cells.csv")


### Classification

## Evaluation

# Calculate ctree() for varying bucket sizes
eval.tree <- evalTree(independ = c(6, 7, 8), 
                     depend = 4, 
                     data = burnt.ndvi.cells, 
                     minbucket = seq(50, 450, 50))

# # Store output
# write.csv(eval.tree, "out/ctree_scores.csv", quote = FALSE, row.names = FALSE)
# eval.tree <- read.csv("out/ctree_scores.csv")


## Probability calculation

# Classification tree
model <- ctree(as.factor(fire) ~ ndvi + ndvi_diff + ndvi_meandev, 
               data = burnt.ndvi.cells, controls = ctree_control(minbucket = 50))

# Probability rasters
prob.rst <- probRst(fire.scenes = fire.scenes, 
                    fire.ts.fls = fire.ts.fls, 
                    fire.rst = fire.rst,
                    ndvi.rst = ndvi.rst,
                    fire.mat = fire.mat, 
                    ndvi.mat = ndvi.mat, 
                    model = model, 
                    n.cores = 4)

# Output storage
out.names <- paste(gsub("md14a1", "md13q1", 
                        sapply(fire.rst[which(fire.scenes)], names)), 
                   "prob.tif", sep = "_")

foreach(i = prob.rst, j = seq(prob.rst), .packages = lib) %dopar% {
  if (!is.null(i))
    writeRaster(i, filename = paste("out/ndvi_prob", out.names[j], sep = "/"),  
                format = "GTiff", overwrite = T)
}

# Response rasters
resp.rst <- probRst(fire.scenes = fire.scenes, 
                    fire.ts.fls = fire.ts.fls, 
                    fire.rst = fire.rst,
                    ndvi.rst = ndvi.rst,
                    fire.mat = fire.mat, 
                    ndvi.mat = ndvi.mat, 
                    model = model, 
                    type = "response",
                    n.cores = 4)

# Output storage
out.names <- paste(gsub("md14a1", "md13q1", 
                        sapply(fire.rst[which(fire.scenes)], names)), 
                   "resp.tif", sep = "_")

foreach(i = resp.rst, j = seq(resp.rst), .packages = lib) %dopar% {
  if (!is.null(i))
    writeRaster(i, filename = paste("out/ndvi_resp", out.names[j], sep = "/"),  
                format = "GTiff", overwrite = T)
}


# ### Plotting stuff
# 
# # Individual color scheme
# my.bw.theme <- trellis.par.get()
# my.bw.theme$box.rectangle$col = "grey80" 
# my.bw.theme$box.umbrella$col = "grey80"
# my.bw.theme$plot.symbol$col = "grey80"
# 
# # Plot logistic GLM fit including histogram 
# png("out/glm_ndvi_fire.png", width = 800, height = 600)
# par(bg = "white")
# logi.hist.plot(independ, depend, boxp = F, type = "hist", col = "gray", 
#                xlab = "Temporal change in NDVI")
# axis(3, seq(-1, 1, .2))
# for (i in 1:3) myMinorTick(side = i)
# dev.off()
# 
# # Transform information about fire occurence (0/1) to factor
# tmp.sub$fire <- factor(ifelse(tmp.sub$fire == 0, "no", "yes"))
# 
# # Scatterplot with point density distribution and boxplots
# png("out/fire_ndvi_prepos_mincell.png", width = 800, height = 600)
# plot(xyplot(fire ~ ndvi_diff, data = tmp.sub,
#             par.settings = my.bw.theme, 
#             xlab = "Temporal change in NDVI", ylab = "Fire", panel = function(x, y) {
#               panel.smoothScatter(x, y, nbin = 500, bandwidth = .1, cuts = 10, nrpoints = 0)
#               panel.bwplot(x, y, box.ratio = .25, pch = "|", notch = TRUE, 
#                            par.settings = my.bw.theme)
#             }))
# dev.off()
# 
# # Densityplot
# png("out/dens_ndvi.png", width = 800, height = 600)
# print(ggplot(tmp.sub, aes(x = ndvi_diff, fill = fire)) + 
#   geom_density(alpha = .5) + 
#   scale_fill_manual(values = c("no" = "black", "yes" = "red")) + 
#   guides(fill = guide_legend(title = "Fire" ,
#                              title.theme = element_text( face="plain", angle=0 ))) + 
#   ylab("Density") + xlab("Temporal change in NDVI"))
# dev.off()
# 
# # Deregister parallel backend
# stopCluster(cl)