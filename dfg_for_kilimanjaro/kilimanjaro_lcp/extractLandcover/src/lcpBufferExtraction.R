# Notes:
# - Adjust path.wd (working directory) prior to execution. 
# - Adjust path.lcp (folder within working directory containing final classifications) prior to execution. 
# - Make sure file 'stations_master_utm37s.csv' is located inside your working directory.

### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Required packages
library(rgdal)
library(raster)

# Paths and files
path.wd <- switch(Sys.info()[["sysname"]], 
                  "Linux" = "/media/permanent/kilimanjaro/landcover/", 
                  "Windows" = "C:/Permanent/kilimanjaro/landcover/")
setwd(path.wd)


### Data import

## Plot data

# Import plot coordinates and select middle poles only
shp <- readOGR(dsn = "../coordinates/coords/", 
               layer = "PlotPoles_ARC1960_mod_20140807_final")
shp <- subset(shp, PoleType == "AMP")
shp <- spTransform(shp, CRS("+init=epsg:32737"))


## Classified images

# List and import classified images
fls.lcp <- list.files("final/plots/", pattern = ".rst$", full.names = TRUE)
rst.lcp <- lapply(fls.lcp, raster)

# Extract class ids (column 'Value' in each raster's attribute table) and 
# related class names (column 'Class_name')
rst.lcp.id <- do.call("rbind", lapply(rst.lcp, function(i) {
  data.frame(i@data@attributes[[1]]$Value, 
             tolower(i@data@attributes[[1]]$Class_name), 
             stringsAsFactors = FALSE)
}))
names(rst.lcp.id) <- c("luv", "luc")
# Remove duplicated rows
rst.lcp.id <- rst.lcp.id[!duplicated(rst.lcp.id), ]
# Check for data inconsistencies
if (anyDuplicated(rst.lcp.id[, 1]) > 0)
  stop(paste("found duplicated class id:", rst.lcp.id[duplicated(rst.lcp.id[, 1]), 1]))

# Identify class values for class names 'clouds' and 'shadow'
id.cl <- rst.lcp.id[rst.lcp.id$luc == "clouds", 1]
id.sh <- rst.lcp.id[rst.lcp.id$luc == "shadow", 1]

# Merge classified images
rst.lcp.mrg <- do.call(function(...) merge(..., tolerance = 1), rst.lcp)


### Pixel extraction

## Output template

# PlotIDs -> row names
plot.names <- unique(as.character(shp@data$PlotID))

# Land-use classes -> column names
class.names <- sort(rst.lcp.id$luc)

output <- data.frame(matrix(ncol = 1 + length(class.names), 
                            nrow = length(plot.names)))
output[] <- 0
names(output) <- c("PlotID", class.names)

output$PlotID <- plot.names


## Buffering

# Buffer widths
buffers <- c(250, 500, 1000, 1500)

# Loop through all classified images
buffered.values <- lapply(1:nrow(shp), function(i) { 
  
  # Current PlotID
  tmp.plt <- shp@data$PlotID[i]
  
  # Loop through buffer sizes
  tmp.lst <- lapply(buffers, function(j) {    
    # Extract pixel values that fall within the given buffer
    tmp.bff.val <- unlist(extract(rst.lcp.mrg, shp[i, ], buffer = j))
    
    if (sum(!is.na(tmp.bff.val)) > 0) {
      # Calculate and round percentage of each class within buffer
      tmp.df <- as.data.frame(round(table(tmp.bff.val) / length(tmp.bff.val), 
                                 digits = 3), stringsAsFactors = FALSE)
      # Replace class values with corresponding class names
      tmp.df[, 1] <- rst.lcp.id[sapply(1:nrow(tmp.df), function(k) {
        which(rst.lcp.id == tmp.df[k, 1])
      }), 2]
      
      # Remove clouds and shadows
      cf <- which(tmp.bff.val %in% c(id.cl, id.sh))
      
      if (length(cf) > 0) {
        tmp.bff.val.cf <- tmp.bff.val[-cf]
        tmp.tbl.cf <- round(table(tmp.bff.val.cf) / length(tmp.bff.val.cf), 3)
        tmp.df.cf <- as.data.frame(tmp.tbl.cf, stringsAsFactors = FALSE)
        tmp.df.cf[, 1] <- rst.lcp.id[sapply(1:nrow(tmp.df.cf), function(k) {
          which(rst.lcp.id == tmp.df.cf[k, 1])
        }), 2]
        tmp <- merge(tmp.df, tmp.df.cf, by.x = names(tmp.df)[1], 
                     by.y = names(tmp.df.cf)[1], all = TRUE)
      } else {
        tmp.df.rm.cf <- tmp.df
        tmp <- data.frame(tmp.df, tmp.df.rm.cf[, 2])
      }
      
      # Merge and return data
      return(tmp) 
    }

  })

  names(tmp.lst) <- rep(tmp.plt, length(tmp.lst))  
  return(tmp.lst)  
})


## Output storage

# Loop through columns (== buffer sizes) of each list element
out <- lapply(seq(buffers), function(z) {
  # Duplicate output template
  tmp.out <- output
  tmp.out.cf <- output
  # Extract values from current buffer column
  tmp.val <- sapply(buffered.values, "[", z)
  
  # Insert values into temporary output template in case plot environment is
  # classified (not valid for some FED plots)
  for (i in seq(tmp.val)) { 
    if (is.null(tmp.val[[i]])) {
      tmp.out[i, 2:ncol(tmp.out)] <- NA
    } else {
      tmp.out[i, tmp.val[[i]][, 1]] <- tmp.val[[i]][, 2]   
      tmp.out.cf[i, tmp.val[[i]][, 1]] <- tmp.val[[i]][, 3] 
    }
  }
  
  # Write CSV and return output data
  write.csv(tmp.out, paste0("out/kili_lcp_", buffers[z], "m.csv"), 
            row.names = FALSE)
  write.csv(tmp.out.cf, paste0("out/kili_lcp_", buffers[z], "m_cf.csv"), 
            row.names = FALSE)
  return(list(tmp.out, tmp.out.cf))
})

# Concatenate output tables to one large table
out.final <- do.call("cbind", lapply(seq(buffers), function(i) {
  do.call(function(...) {
    merge(..., by = "PlotID", all = TRUE,
          suffixes = c(paste0("_", buffers[i]), paste0("_", buffers[i], "_nc")))
    }, out[[i]])}))

out.final <- out.final[!duplicated(colnames(out.final))]
write.csv(out.final, "out/kili_lcp_allbuff.csv", row.names = FALSE, quote = FALSE)
