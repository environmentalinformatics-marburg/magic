### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
# path.wd <- "/media/pa_NDown/ki_modis_ndvi" # Linux
path.wd <- "L:/ki_modis_ndvi" # Windows
setwd(path.wd) 

# Required packages
lib <- c("doParallel", "raster", "reshape", "ggplot2", "plyr")
sapply(lib, function(x) require(x, character.only = T))

# Parallelization
cl <- makePSOCKcluster(n.cores <- 4)
clusterEvalQ(cl, c(library(rgdal), library(raster)))


### Data processing

## Import fire data

# List files and extract date information
fire.fls <- list.files("data/reclass/md14a1", pattern = "md14a1.*.tif$", full.names = T)
fire.yrly_ts <- unique(substr(basename(fire.fls), 8, 11))

# Time series setup
fire.dly_ts <- do.call("c", lapply(fire.yrly_ts, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), as.Date(paste(i, "12", "31", sep = "-")), 1)
}))

# Merge continuous dates with available files
fire.dly_ts.fls <- merge(data.frame(date = fire.dly_ts), 
                           data.frame(date = as.Date(substr(basename(fire.fls), 8, 14), format = "%Y%j"), file = fire.fls, stringsAsFactors = FALSE), 
                           by = "date", all.x = TRUE)


## Import and reprocess DEM

# Import DEM
dem <- raster("data/KiLi_DEM/kili_dem.tif")

# Crop and resample DEM using MODIS image extent and resolution
kili.reference <- raster(fire.dly_ts.fls[which(!is.na(fire.dly_ts.fls[, 2]))[1], 2])
kili.extent <- extent(kili.reference)

dem.res <- resample(dem.crp <- crop(dem, kili.extent), 
                    kili.reference)

# Reclassify DEM
# dem.rec <- reclassify(dem.res, matrix(c(0, 500, 0, 
#                                         500, 1000, 500, 
#                                         1000, 1500, 1000, 
#                                         1500, 2000, 1500, 
#                                         2000, 2500, 2000, 
#                                         2500, 3000, 2500, 
#                                         3000, 3500, 3000, 
#                                         3500, 4000, 3500, 
#                                         4000, 4500, 4000, 
#                                         4500, 5000, 4500, 
#                                         5000, 5500, 5000, 
#                                         5500, 6000, 5500), ncol = 3, byrow = T))
dem.rec <- reclassify(dem.res, matrix(c(0, 1000, 500, 
                                        1000, 2000, 1500, 
                                        2000, 3000, 2500, 
                                        3000, 4000, 3500, 
                                        4000, 5000, 4500, 
                                        5000, 6000, 5500), ncol = 3, byrow = T))


## Identify and sum up fire events per year considering
## - temporally adjacent fire events
## - spatially adjacent fire events
## - elevation level

clusterExport(cl, c("fire.dly_ts.fls", "fire.yrly_ts", "dem.rec"))

# Loop through available years
fire.yr <- parLapply(cl, fire.yrly_ts, function(i) {
  # Subset data by current year
  tmp.df <- subset(fire.dly_ts.fls, substr(date, 1, 4) == i)
  
  # Import RasterLayers of current year
  tmp.rst <- lapply(seq(nrow(tmp.df)), function(j) {
    if (is.na(tmp.df[j, 2]))
      NA
    else 
      raster(tmp.df[j, 2])
  })
  
  # Raster template for annual aggregation
  template <- tmp.rst[[which(!is.na(tmp.df[, 2]))[1]]]
  out.rst <- raster(nrows = nrow(template), ncols = ncol(template), 
                    ext = extent(template), crs = projection(template))
  out.rst[] <- rep(0, ncell(out.rst))
    
  # Dataframe template
  out.df <- data.frame(height = integer(0), size = integer(0))
  
  # RasterLayer available?
  for (k in seq(tmp.rst)) {
    if (class(tmp.rst[[k]]) == "logical") {
      next
      
    } else {
      fire <- which(tmp.rst[[k]][] > 0)
      
      # Fire events detected?
      if (length(fire) == 0) {
        next
        
      } else {
        
        # Logical vector indicating whether fire cells should be processed
        process.cell <- rep(T, length(fire))
        # Loop through fire cells
        for (l in if(length(fire) > 1) seq(fire) else 1) {
          
          if (k > 1 & tmp.rst[[k-1]][fire[l]] != 0) {
            next
            
            # Process cell | k = 1 | Fire event detected in previous RasterLayer?
          } else if (process.cell[l]) {
            # out.rst[l] <- out.rst[l] + 1
            
            # Initialize fire size and identify adjacent cells
            curr.cell <- fire[l]
            fire.size <- 1
            adj.cells <- adjacent(tmp.rst[[k]], fire[l], directions = 4, pairs = F)
            
            # Exclude cells that burned in previous scene
            adj.cells.prev_burn <- which(tmp.rst[[k-1]][adj.cells] != 0)
            if (k > 1 & length(adj.cells.prev_burn) > 0) {
              process.cell[fire %in% adj.cells[adj.cells.prev_burn]] <- F
              adj.cells <- adj.cells[-adj.cells.prev_burn]
            }
            
            # Exclude adjacent pixels from different elevation level
            init.height <- extract(dem.rec, curr.cell)
            adj.height <- extract(dem.rec, adj.cells)
            
            adj.cells <- adj.cells[adj.height == init.height]
            
            # Adjacent fire cells?
            if (any(adj.cells %in% fire)) {
              adj.fire <- T
              
              while(adj.fire) {
                # Disable separate processing of adjacent fire cells 
                new.cells <- adj.cells[which(adj.cells %in% fire)]
                process.cell[which(fire %in% new.cells)] <- F
                
                # Increment fire size
                fire.size <- fire.size + sum(adj.cells %in% fire)
                
                # Adjacent cells of new fire cells
                adj.cells <- adjacent(tmp.rst[[k]], new.cells, directions = 4, pairs = F)
                
                # Remove previously processed fire cells
                adj.cells <- adj.cells[!adj.cells %in% curr.cell]
                
                # Exclude cells that burned in previous scene
                adj.cells.prev_burn <- which(tmp.rst[[k-1]][adj.cells] != 0)
                if (k > 1 & length(adj.cells.prev_burn) > 0) {
                  adj.cells <- adj.cells[-adj.cells.prev_burn]
                }
                
                # Exclude different elevation levels
                adj.height <- extract(dem.rec, adj.cells)
                adj.cells <- adj.cells[adj.height == init.height]
                
                # Check if any adjacent fire cells exist
                curr.cell <- new.cells
                adj.fire <- ifelse(any(adj.cells %in% fire), T, F)
              } # end of while loop
            } # end of innermost if-else statement
            
            out.df <- rbind(out.df, data.frame(height = init.height, size = fire.size))
          } # end of inner if-else statement
        } # end of inner for loop
      } # end of center if-else statement
    } # end of outer if-else statement
  } # end of outermost if-else statement
  
  return(out.df)
})

# Sum up fire events per elevation level per year
fire.yr.sum <- lapply(fire.yr, function(i) {
  tmp.agg <- aggregate(i$size, by = list(i$height), FUN = sum)
  
  tmp.mrg <- merge(data.frame(c(500, 1500, 2500, 3500, 4500)), tmp.agg, all.x = T, by = 1)
  tmp.mrg[is.na(tmp.mrg)] <- 0
  
  return(tmp.mrg)
})

# Sum up fire events of different size per elevation level per year
fire.yr.cnt <- lapply(fire.yr, function(i) {
  ddply(i, .(height, size), summarise, count = length(height))
})


## Mean fire size per elevation level per year

# Loop through single years
fire.yr.mean_size <- lapply(fire.yr.cnt, function(i) {
  # Unique heights 
  #   tmp.height <- unique(i$height)
  tmp.height <- c(500, 1500, 2500, 3500, 4500)
  # Calculate mean fire size per unique height
  sapply(tmp.height, function(j) {
    tmp.df <- subset(i, height == j)
    
    if (nrow(tmp.df) > 0)
      return(tmp.mean <- round(sum(tmp.df[, 2] * tmp.df[, 3]) / sum(tmp.df[, 3]), 
                               digits = 1))
    else
      return(0)
  })
})

# Merge calculated means with total amount of fire cells per elevation level
fire.yr.sum.mean_size <- lapply(seq(fire.yr.sum), function(i) {
  data.frame(fire.yr.sum[[i]], fire.yr.mean_size[[i]])
})

# Merge summarized fire events including mean fire sizes
for (i in seq(fire.yr.sum.mean_size)) {
  if (i == 1) {
    fire.yr.sum.df <- fire.yr.sum.mean_size[[i]]
    names(fire.yr.sum.df) <- c("elevation", fire.yrly_ts[i], paste(fire.yrly_ts[i], "mv", sep = "_"))
  } else {
    tmp <- names(fire.yr.sum.df)
    fire.yr.sum.df <- merge(fire.yr.sum.df, fire.yr.sum.mean_size[[i]], all = T, by = 1)
    names(fire.yr.sum.df) <- c(tmp, fire.yrly_ts[i], paste(fire.yrly_ts[i], "mv", sep = "_"))
  }
  
  fire.yr.sum.df[is.na(fire.yr.sum.df)] <- 0
}

# # Merge counted fire events
# for (i in seq(fire.yr.cnt)) {
#   if (i == 1) {
#     fire.yr.cnt.df <- fire.yr.cnt[[i]]
#     names(fire.yr.cnt.df) <- c("elevation", "size", fire.yrly_ts[i])
#   } else {
#     tmp <- names(fire.yr.cnt.df)
#     fire.yr.cnt.df <- merge(fire.yr.cnt.df, fire.yr.cnt[[i]], all = T, by = c(1, 2))
#     names(fire.yr.cnt.df) <- c(tmp, fire.yrly_ts[i])
#   }
#   
#   fire.yr.cnt.df[is.na(fire.yr.cnt.df)] <- 0
# }


## Reformat (melt) data

# Format elevation levels
ele <- formatC(fire.yr.sum.df[, 1], width = 4, format = "d", flag = "0")

# Merge and melt data
fire.yr.sum.df.t <- data.frame(year = as.integer(fire.yrly_ts), 
                               t(fire.yr.sum.df)[seq(2, nrow(t(fire.yr.sum.df)), 2), ])
names(fire.yr.sum.df.t) <- c("year", as.character(ele))

fire.yr.sum.df.melt <- melt(fire.yr.sum.df.t, id = "year", variable_name = "elevation")

# Add mean fire size to elevation level per year
fire.yr.sum.df.melt$mean_size <- unlist(lapply(1:5, function(i) {
  sapply(fire.yr.mean_size, "[[", i)  
}))


### Plotting

levels(fire.yr.sum.df.melt$elevation) <- c("500-1000 m", "1000-2000 m", "2000-3000 m", 
                                           "3000-4000 m", "4000-5000 m")

png("out/ts_fire_elevation_size.png", height = 600, width = 900)
print(ggplot(data = fire.yr.sum.df.melt, aes(x = year, y = value)) + 
  stat_smooth(method = "loess", colour = "black", lwd = 1, 
              span = .5, show_guide = F, se = F) + 
  stat_smooth(method = "lm", colour = "red", lty = 2) + 
  geom_point(aes(size = mean_size, alpha = ifelse(mean_size == 0, 0, 1)), 
             col = "grey40") + 
  scale_size(breaks = c(1, 5, 10)) +
  scale_alpha(guide = "none") + 
  facet_grid(elevation ~ .) + 
  coord_cartesian(ylim = c(-2.5, max(fire.yr.sum.df.melt$value) + 2.5)) + 
  labs(x = "Time [a]", y = "Fire events"))
dev.off()
