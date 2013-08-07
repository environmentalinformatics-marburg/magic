### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
# path.wd <- "/media/pa_NDown/ki_modis_ndvi" # Linux
path.wd <- "D:/ki_modis_ndvi" # Windows
setwd(path.wd) 

# Required packages
lib <- c("doParallel", "raster", "latticeExtra", "popbio", "ggplot2")
sapply(lib, function(x) stopifnot(require(x, character.only = T)))

# Parallelization
clstr <- makePSOCKcluster(n.cores <- 4)
clusterEvalQ(clstr, c(library(rgdal), library(raster)))


### Data import

## MODIS NDVI 

# List files and order by date
modis.ndvi.fls <- list.files("data/MODIS_ARC", recursive = TRUE, full.names = TRUE, pattern = "16_days_NDVI.tif$")
modis.ndvi.fls <- modis.ndvi.fls[order(substr(basename(modis.ndvi.fls), 10, 16))]
modis.ndvi.ts.years <- unique(substr(basename(modis.ndvi.fls), 10, 13))

modis.ndvi.ts <- do.call("c", lapply(modis.ndvi.ts.years, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), as.Date(paste(i, "12", "31", sep = "-")), 8)
}))

modis.ndvi.ts.fls <- merge(data.frame(date = modis.ndvi.ts), 
                           data.frame(date = as.Date(substr(basename(modis.ndvi.fls), 10, 16), format = "%Y%j"), file = modis.ndvi.fls, stringsAsFactors = FALSE), 
                           by = "date", all.x = TRUE)

# Import raster files
clusterExport(clstr, "modis.ndvi.ts.fls")
modis.ndvi.rasters <- parLapply(clstr, seq(nrow(modis.ndvi.ts.fls)), function(i) {
  if (is.na(modis.ndvi.ts.fls[i, 2])) {
    NA
  } else {
    raster(modis.ndvi.ts.fls[i, 2])
  }
})


## MODIS fire

# Import raster files and aggregate on 8 days
aggregate.exe <- FALSE

if (aggregate.exe) {
  modis.fire.fls <- list.files("data/reclass/md14a1", full.names = TRUE, pattern = ".tif$")
  modis.fire.ts.years <- unique(substr(basename(modis.fire.fls), 8, 11))
  
  modis.fire.dly.ts <- do.call("c", lapply(modis.fire.ts.years, function(i) { 
    seq(as.Date(paste(i, "01", "01", sep = "-")), as.Date(paste(i, "12", "31", sep = "-")), 1)
  }))
  
  modis.fire.dly.ts.fls <- merge(data.frame(date = modis.fire.dly.ts), 
                                 data.frame(date = as.Date(substr(basename(modis.fire.fls), 8, 14), format = "%Y%j"), file = modis.fire.fls, stringsAsFactors = FALSE), 
                                 by = "date", all.x = TRUE)
  
  modis.fire.agg <- kifiAggData(data = modis.fire.dly.ts.fls, 
                                years = modis.fire.ts.years, 
                                over.fun = max, 
                                dsn = "/media/pa_NDown/ki_modis_ndvi/data/overlay/md14a1_agg/", 
                                out.str = "md14a1", format = "GTiff", overwrite = TRUE)
} else {
  modis.fire.fls <- list.files("data/overlay/md14a1_agg", pattern = "md14a1.*.tif$", full.names = TRUE)
  modis.fire.ts.years <- unique(substr(basename(modis.fire.fls), 8, 11))

  modis.fire.ts <- do.call("c", lapply(modis.fire.ts.years, function(i) { 
    seq(as.Date(paste(i, "01", "01", sep = "-")), as.Date(paste(i, "12", "31", sep = "-")), 8)
  }))
   
  modis.fire.ts.fls <- merge(data.frame(date = modis.fire.ts), 
                                 data.frame(date = as.Date(substr(basename(modis.fire.fls), 8, 14), format = "%Y%j"), file = modis.fire.fls, stringsAsFactors = FALSE), 
                                 by = "date", all.x = TRUE)
  
  clusterExport(clstr, "modis.fire.ts.fls")
  modis.fire.agg <- parLapply(clstr, seq(nrow(modis.fire.ts.fls)), function(i) {
    if (is.na(modis.fire.ts.fls[i, 2])) {
      NA
    } else {
      raster(modis.fire.ts.fls[i, 2])
    }
  })
}

# Identification of fire scenes
clusterExport(clstr, "modis.fire.agg")
modis.fire.avl <- parSapply(clstr, modis.fire.agg, function(i) {
  if (class(i) != "logical") {maxValue(i) > 0} else {NA}
})

# Identification of fire pixels
modis.fire.cells <- sort(unique(unlist(parSapply(clstr, modis.fire.agg, function(i) {
  if (class(i) != "logical") {which(getValues(i) > 0)} else {NA}
}))))

# Identification of first fire event per fire pixel
# clusterExport(clstr, c("modis.fire.avl", "modis.fire.cells"))
# modis.fire.cells.firstscene <- parSapply(clstr, modis.fire.cells, function(i) {
#   which(sapply(seq(modis.fire.agg), function(j) {
#     if (class(modis.fire.agg[[j]]) == "logical" | is.na(modis.fire.avl[j])) {NA} else if (!modis.fire.avl[j]) {NA} else {modis.fire.agg[[j]][i] > 0}
#   }))[1] 
# })
# modis.fire.cells.df <- data.frame(cell = modis.fire.cells, first_scene = modis.fire.cells.firstscene)
# modis.fire.cells.df <- modis.fire.cells.df[order(modis.fire.cells.df[, 2]), ]

# ### Time series
# 
# ## Fire time series
# 
# clusterExport(clstr, c("modis.fire.agg", "modis.fire.cells")) 
# tmp.fire.ts <- parSapply(clstr, modis.fire.agg, function(j) {
#   if (class(j) != "logical") {
#     getValues(j)[modis.fire.cells]
#   } else {
#     NA
#   }
# })
# modis.fire.ts <- do.call("rbind", tmp.fire.ts)
# 
# # Extract NDVI cells (250 m) that lie within fire cell (1 km)
# modis.ndvi.avl.cells <- unique(do.call("c", parLapply(clstr, modis.fire.cells, function(i) {
#   tmp <- modis.fire.agg[[100]]
#   tmp[][-i] <- NA
#   tmp.shp <- rasterToPolygons(tmp)
#   
#   return(cellsFromExtent(modis.ndvi.rasters[[300]], extent(tmp.shp)))
# })))
# 
# 
# ## NDVI time series
# 
# clusterExport(clstr, c("modis.ndvi.rasters", "modis.ndvi.avl.cells"))
# tmp.ndvi.ts <- parSapply(clstr, modis.ndvi.rasters, function(j) {
#   if (class(j) != "logical") {
#     getValues(j)[modis.ndvi.avl.cells]
#   } else {
#     NA
#   }
# })
# modis.ndvi.ts <- do.call("rbind", tmp.ndvi.ts)


### NDVI prior to and after fire

# Extract fire and NDVI four weeks prior to and after a fire event

# modis.fire.pre <- modis.fire.pos <- rep(FALSE, length(modis.fire.avl))
# 
# for (i in which(modis.fire.avl)) {
#   modis.fire.pre[(i-4):(i-1)] <- TRUE
# }
# for (i in which(modis.fire.avl)) {
#   modis.fire.pos[(i-4):(i-1)] <- TRUE
# }

# Timespan (in 8-day intervals) to consider before and after the fire event
timespan <- 1

# Loop through scenes with at least one fire pixel
clusterExport(clstr, c("timespan", "modis.ndvi.rasters", 
                       "modis.fire.ts.fls", "modis.fire.avl"))
fire.ndvi.pre.post <- do.call("rbind", parLapply(clstr, which(modis.fire.avl), function(i) {

  # Date, fire and NDVI rasters for the given time span around current scene
  tmp.date <- modis.fire.ts.fls[c(((i-timespan):(i-1)), ((i+1):(i+timespan))), 1]
  tmp.fire <- modis.fire.agg[c(((i-timespan):(i-1)), ((i+1):(i+timespan)))]
  tmp.ndvi <- modis.ndvi.rasters[c(((i-timespan):(i-1)), ((i+1):(i+timespan)))]
  
  # Fire cells in current scene
  tmp.fire.cells <- which(modis.fire.agg[[i]][] > 0)
  
  # Loop through single fire cells of current scene
  fire.ndvi.pre.post <- do.call("rbind", lapply(tmp.fire.cells, function(j) {
    tmp <- modis.fire.agg[[i]]
    tmp[][-j] <- NA
    tmp.shp <- rasterToPolygons(tmp)
    ndvi.cells <- cellsFromExtent(modis.ndvi.rasters[[300]], extent(tmp.shp))
    
    ndvi.diff <- tmp.ndvi[[length(tmp.ndvi) - timespan + 1]][ndvi.cells] - 
      tmp.ndvi[[length(tmp.ndvi) - timespan]][ndvi.cells]
    
    ndvi.cell <- ndvi.cells[which(ndvi.diff == min(ndvi.diff))]
#     ndvi.mean <- mean(tmp.ndvi[[length(tmp.ndvi) - timespan]][ndvi.cells], na.rm = T)
#     ndvi.dev.pre <- tmp.ndvi[[length(tmp.ndvi) - timespan]][ndvi.cells] - ndvi.mean
#     ndvi.dev.post <- tmp.ndvi[[length(tmp.ndvi) - timespan + 1]][ndvi.cells] - ndvi.mean
#     
#     ndvi.dev.diff <- ndvi.dev.post - ndvi.dev.pre
#     ndvi.cell <- ndvi.cells[which(ndvi.dev.diff == min(ndvi.dev.diff))]
    
    if (length(ndvi.cell) == 1) {
      # Extract fire and NDVI values of the given pixel for the defined time span
      fire.vals <- sapply(tmp.fire, function(k) k[j])
      fire.vals[(timespan+1):length(fire.vals)] <- 1
      ndvi.vals <- round(sapply(tmp.ndvi, function(k) k[ndvi.cell]) / 10000, digits = 3)
      
      # Merge date, fire and NDVI information for the current fire cell
      return(data.frame(date = tmp.date, cell_fire = rep(j, length(tmp.date)), fire = fire.vals,  
                        cell_ndvi = rep(ndvi.cell, length(tmp.date)), ndvi = ndvi.vals))
      
    } else {
      fire.vals <- sapply(tmp.fire, function(k) k[j])
      fire.vals[(timespan+1):length(fire.vals)] <- 1
      ndvi.vals <- unlist(lapply(ndvi.cell, function(l) {
        round(sapply(tmp.ndvi, function(k) k[l]) / 10000, digits = 3)
      }))
      
      multiplier <- length(ndvi.vals) / length(tmp.date)
      tmp.date <- rep(tmp.date, multiplier)
      fire.vals <- rep(fire.vals, multiplier)
      return(data.frame(date = tmp.date, 
                        cell_fire = rep(j, length(tmp.date)), fire = fire.vals,  
                        cell_ndvi = rep(ndvi.cell, each = length(tmp.date) / length(ndvi.cell)), ndvi = ndvi.vals))
    }
  }))
  
  return(fire.ndvi.pre.post)
}))

# Transform information about fire occurence (0/1) to factor
fire.ndvi.pre.post$fire <- factor(ifelse(fire.ndvi.pre.post$fire == 0, "no", "yes"))

# # Same as above, but consider but the first burn event in a cell
# clusterExport(clstr, "modis.fire.cells.df")
# fire.ndvi.pre_post <- do.call("rbind", parLapply(clstr, unique(modis.fire.cells.df[, 2]), function(i) {
#   tmp.fire.cells <- modis.fire.cells.df[modis.fire.cells.df[, 2] == i, 1]
#   
#   tmp.date <- modis.fire.ts.fls[c((i-4):(i-1), (i+1):(i+4)), 1]
#   tmp.fire <- modis.fire.agg[c((i-4):(i-1), (i+1):(i+4))]
#   tmp.ndvi <- modis.ndvi.rasters[c((i-4):(i-1), (i+1):(i+4))]
#   
#   # Loop through single fire cells of current scene
#   tmp.fire.ndvi.vals <- do.call("rbind", lapply(tmp.fire.cells, function(j) {
#     tmp <- modis.fire.agg[[i]]
#     tmp[][-j] <- NA
#     tmp.shp <- rasterToPolygons(tmp)
#     tmp.ndvi.cells <- cellsFromExtent(modis.ndvi.rasters[[300]], extent(tmp.shp))
#     
#     # Extract fire and NDVI values of the given pixel for the defined time span
#     tmp.fire.vals <- sapply(tmp.fire, function(k) k[j])
#     tmp.fire.vals[5:8] <- 1
#     
#     tmp.ndvi.vals <- round(unlist(lapply(tmp.ndvi, function(k) k[tmp.ndvi.cells])) / 10000, digits = 3)
#     
#     # Merge date, fire and NDVI information for the current fire cell
#     data.frame(date = rep(tmp.date, each = length(tmp.ndvi.cells)), cell_fire = rep(j, length(tmp.ndvi.vals)), fire = rep(tmp.fire.vals, each = length(tmp.ndvi.cells)), 
#                cell_ndvi = rep(tmp.ndvi.cells, length(tmp.ndvi.vals) / length(tmp.ndvi.cells)), ndvi = tmp.ndvi.vals)
#   }))
#   
#   return(tmp.fire.ndvi.vals)
#   
# }))

# # Remove duplicates
# modis.ndvi.preburn.postburn <- modis.ndvi.preburn.postburn[-which(duplicated(modis.ndvi.preburn.postburn)), ]

# Write output
write.csv(fire.ndvi.pre.post, "out/fire_ndvi_pre_post.csv", 
          quote = FALSE, row.names = FALSE)


### Plotting stuff

# Individual color scheme
my.bw.theme <- trellis.par.get()
my.bw.theme$box.rectangle$col = "grey80" 
my.bw.theme$box.umbrella$col = "grey80"
my.bw.theme$plot.symbol$col = "grey80"

# # Fit GLM with binomial distributed data
# fire.ndvi.glm <- glm(fire ~ ndvi, data = fire.ndvi.pre.post, 
#                      family = binomial(link = "logit"))

# Plot logistic GLM fit including histogram 
png("out/glm_ndvi_fire.png", width = 800, height = 600)
par(bg = "white")
logi.hist.plot(fire.ndvi.pre.post$ndvi, ifelse(fire.ndvi.pre.post$fire == "yes", 1, 0), 
               boxp = F, type = "hist", col = "gray")
dev.off()

# Scatterplot with point density distribution and boxplots
png("out/fire_ndvi_prepos_mincell.png", width = 800, height = 600)
plot(xyplot(as.factor(fire) ~ ndvi, data = fire.ndvi.pre.post,
            par.settings = my.bw.theme, 
            xlab = "NDVI", ylab = "Fire", panel = function(x, y) {
              panel.smoothScatter(x, y, nbin = 500, bandwidth = .1, cuts = 10, nrpoints = 0)
              panel.bwplot(x, y, box.ratio = .25, pch = "|", notch = TRUE, 
                           par.settings = my.bw.theme)
            }))
dev.off()

# Densityplot
png("out/dens_ndvi.png", width = 800, height = 600)
print(ggplot(fire.ndvi.pre.post, aes(x = ndvi, fill = fire)) + 
  geom_density(alpha = .5) + 
  scale_fill_manual(values = c("no" = "black", "yes" = "red")) + 
  guides(fill = guide_legend(title = "Fire" ,
                             title.theme = element_text( face="plain", angle=0 ))) + 
  ylab("Density") + xlab("NDVI"))
dev.off()

# Deregister parallel backend
stopCluster(clstr)