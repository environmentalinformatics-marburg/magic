### Environmental settings

# Clear workspace
rm(list = ls(all = TRUE))

# Required libraries
library(raster)
library(rgdal)
library(parallel)

# Paths and filenames
path.wd <- "D:/exploratories"
path.src <- "src/"
path.data <- "data/"
path.ndvi <- "md13cor_05_50/"
path.out <- "out/"

file.coords <- "plot_locations.csv"
file.out <- "2002_2011__ndvi_data.dat"
file.out.sd <- "2002_2011__ndvi_data_sd.dat"
file.out.gf <- "2002_2011__ndvi_data_gf.dat"

# Working directory
setwd(path.wd)

# Functions
source(paste(path.src, "rejectOutliers.R", sep = ""))
source(paste(path.src, "gapLength.R", sep = ""))
source(paste(path.src, "dynFillOutliers.R", sep = ""))


### NDVI data

# List NDVI raster files
files.ndvi <- list.files(paste(path.data, path.ndvi, sep = ""), pattern = ".rst", full.names = TRUE)

# Proj4string for MODIS Sinusoidal projection
crs.mod <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

# Import NDVI raster data
n.cores <- detectCores()
clstr <- makePSOCKcluster(n.cores)

clusterEvalQ(clstr, c(library(raster), library(rgdal)))
clusterExport(clstr, c("files.ndvi", "crs.mod"))

data.ndvi <- parLapply(clstr, seq(files.ndvi), function(i) {
  # Set coordinate reference system (CRS) to MODIS Sinusoidal
  raster(files.ndvi[i], crs = CRS(crs.mod))
})


### Plot locations

# Proj4strings for plot locations
crs.alb <- "+proj=tmerc +lat_0=0 +lon_0=9 +k=1 +x_0=3500000 +y_0=0 +ellps=bessel +datum=potsdam +units=m +no_defs" # DHDN 3
crs.hai <- "+proj=tmerc +lat_0=0 +lon_0=12 +k=1 +x_0=4500000 +y_0=0 +ellps=bessel +datum=potsdam +units=m +no_defs" # DHDN 4
crs.sch <- "+proj=tmerc +lat_0=0 +lon_0=15 +k=1 +x_0=5500000 +y_0=0 +ellps=bessel +datum=potsdam +units=m +no_defs" # DHDN 5

list.crs <- list(A = crs.alb, H = crs.hai, S = crs.sch)

# Import plot locations
data.coords <- read.table(paste(path.data, file.coords, sep = ""), 
                          header = TRUE, sep = ";", dec = ",", stringsAsFactors = FALSE)

# Separate plot locations by exploratory
data.coords <- lapply(unique(data.coords[,1]), function(i) {
  tmp <- subset(data.coords, data.coords[,1] == i)
  # Set coordinates (data.frame -> SpatialPointsDataFrame)
  coordinates(tmp) <- c("rw", "hw")
  # Set CRS with respect to current exploratory
  proj4string(tmp) <- CRS(list.crs[[i]])
  # Reproject plots to MODIS Sinusoidal
  spTransform(tmp, CRS = CRS(crs.mod))
})

# Merge single SpatialPointsDataFrames
data.coords <- do.call("rbind", data.coords)


### Extract NDVI values 

clusterExport(clstr, c("data.ndvi", "data.coords"))

data.ndvi.plots <- do.call("cbind", parLapply(clstr, seq(data.ndvi), function(i) {
    tmp <- data.frame(extract(data.ndvi[[i]], data.coords))
    names(tmp) <- substr(names(data.ndvi[[i]]), 30, 37)
    tmp
}))

# Set Plot IDs as rownames
row.names(data.ndvi.plots) <- data.coords$Plot_ID

# Change columns and rows
data.ndvi.plots <- data.frame(t(data.ndvi.plots))

# Write NDVI table to file
write.table(data.ndvi.plots, paste(path.out, file.out, sep = ""), col.names = TRUE, row.names = TRUE, sep = ";")


### Outlier rejection

# Reject outliers
data.ndvi.plots.sd <- rejectOutliers(data = data.ndvi.plots, 
                                     window.size = 7)

# Reject values < -0.5
clusterExport(clstr, "data.ndvi.plots.sd")

data.ndvi.plots.sd.tmp <- data.frame(do.call("cbind", parLapply(clstr, seq(ncol(data.ndvi.plots.sd)), function(i) {
  tmp <- data.ndvi.plots.sd[,i]
  
  if (length(which(tmp < -0.5)) > 0)
    tmp[which(tmp < -0.5)] <- NA
  
  tmp
})))
names(data.ndvi.plots.sd.tmp) <- names(data.ndvi.plots.sd)
rownames(data.ndvi.plots.sd.tmp) <- rownames(data.ndvi.plots.sd)


# Write spike-filtered NDVI table to file
write.table(data.ndvi.plots.sd.tmp, paste(path.out, file.out.sd, sep = ""), col.names = TRUE, row.names = TRUE, sep = ";")


### Calculate gap lengths

# Clone spike-filtered data frame
data.ndvi.plots.gf <- data.ndvi.plots.sd.tmp

while (length(which(is.na(data.ndvi.plots.gf))) > 0) {

  clusterExport(clstr, c("path.src", "data.ndvi.plots.gf"))
  clusterEvalQ(clstr, source(paste(path.src, "gapLength.R", sep = "")))
  
  data.gaps <- parLapply(clstr, seq(ncol(data.ndvi.plots.gf)), function(i) {
    tmp <- which(is.na(data.ndvi.plots.gf[,i]))
    
    if (length(tmp) > 0) {
      gapLength(pos.na = tmp)
    } else {
      list()
    }
  })
  
  # Loop through plots
  for (i in seq(data.gaps)) {
    
    # If any NA values in current plot -> 
    if (length(data.gaps[[i]]) > 0) {
      # Loop through gaps in current plot
      tmp <- do.call("rbind", lapply(seq(data.gaps[[i]]), function(j) {
        # Retrieve gap position
        pos.na <- seq(as.numeric(data.gaps[[i]][[j]][1]), as.numeric(data.gaps[[i]][[j]][2]))
        # Calculate window size for current gap
        window.size <- as.numeric(data.gaps[[i]][[j]][3]) + 4
        # Fill current gap
        dynFillOutliers(data = as.numeric(data.ndvi.plots.gf[,i]), 
                        pos.na = pos.na,
                        window.size = window.size)
        
      }))
      
      # Replace NA values by running means
      data.ndvi.plots.gf[tmp[,1],i] <- tmp[,2]
    }
    
  }
  
}

# Write filled NDVI table to file
write.table(data.ndvi.plots.gf, paste(path.out, file.out.gf, sep = ""), col.names = TRUE, row.names = TRUE, sep = ";")

# Stop cluster
stopCluster(clstr)


# # Plot data
# plot(data.ndvi.plots[,100], type = "l")
# lines(data.ndvi.plots.sd.tmp[,100], col = "red")
# lines(data.ndvi.plots.gf[,100], col = "green")
