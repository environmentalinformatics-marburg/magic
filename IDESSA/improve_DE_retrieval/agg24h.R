
#Author:Meike Kühnlein and Hanna Meyer
### Environmental settings
#put rasters in folders named paste0(path.wd,daytime,folSeq,"1h")

# Clear workspace
rm(list = ls(all = TRUE))
library(Rainfall)
library(raster)
library(rgdal)
################################################################################
#                   USER ADJUSTMENTS
################################################################################

data.path <- "/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/predictions/"
aggSeq <- c(3,24)
folSeq <- c("onlySpectral","all")
daytime <- c("day","night")

################################################################################
#                   LOAD PACKAGES AND START CLUSTER
################################################################################


# Required packages and functions
library(raster)
library(doParallel)
cl <- makeCluster(3)
registerDoParallel(cl)

################################################################################
#                   LOOP OVER RASTER
################################################################################

## loop over daytime
for (k in 1:length(daytime)){
  ## loop over models
  for (j in 1:length(folSeq)){
    path <- paste0(data.path,"/",folSeq[j],"/",daytime[k],"_Rain/") 
    ## loop over aggregation level
    for (i in 1:length(aggSeq)){
      path.out <- paste(path,paste(aggSeq[i],"h/",sep=""),sep="")
      dir.create(path.out, recursive = FALSE, showWarnings = FALSE)
      # List raster files
      files.long <- list.files(path, pattern = ".tif", full.names = TRUE)
      files.short <- list.files(path, pattern = ".tif", full.names = FALSE)
      
      ####################### Aggregate daytime and 24hInb raster
      if (daytime[k]=="day"){
        days <- unique(substr(files.short, 16,23))
       
        rasters=foreach(i=seq(days),.packages=c("raster","doParallel"))%dopar%{ 
          tmp <- grep(days[i], files.long)
          lapply(tmp, function(j) {
            raster(files.long[j])
          })
        }
        # Aggregate diurnal raster data by agg.level 
        # (diurnal aggregation -> agg.level = 24, aggregation by e.g. three hours -> agg.level = 3)
        rasters.agg <- aggRaster(data = rasters, 
                                 agg.level = aggSeq[i], 
                                 write.file = TRUE,
                                 days = days, 
                                 path.out = path.out)
      }
      
      ####################### Aggregate nighttime raster 
      if (daytime[k]=="night"){
        # Extract unique days from raster files minus 12 hours
        nights <- strptime(substr(files.short, 13, 25), format = "%Y%m%d%H")
        nights <- nights - 12 * 60 * 60
        nights <- substr(nights, 1, 10)
        nights <- gsub("-", "", nights)
        index.list <- split(files.long, nights)
        nights <- unique(nights)
        rasters=foreach(i=seq(index.list),.packages=c("raster","doParallel"))%dopar%{ 
          tmp <- index.list[[i]]
          lapply(seq(tmp), function(j) {
            raster(tmp[[j]])
          })
        }
        rasters.agg <- aggRaster(data = rasters, 
                                 agg.level = aggSeq[i], 
                                 write.file = TRUE,
                                 days = nights, 
                                 path.out = path.out)
      }
    }
  }
}
################################################################################
#                  STOP CLUSTER
################################################################################



################################################################################
########################## RADOLAN ############################################
path <-"/media/hanna/data/copyFrom183/Improve_DE_retrieval/RadarProj/2010/"
################################################################################

  path.out <- "/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/predictions/radolan_24h/"
  #dir.create(path.out, recursive = FALSE, showWarnings = FALSE)
  # List raster files
  files.long <- list.files(path, pattern = ".tif$", full.names = TRUE, recursive =T)
  files.short <- substr(list.files(path, pattern = ".tif$", full.names = FALSE, recursive =T),
                        10,35)
  
  ####################### Aggregate daytime and 24hInb raster

    days <- unique(substr(files.short, 1,8))
    
    rasters=foreach(i=seq(days),.packages=c("raster","doParallel","rgdal"))%dopar%{ 
      tmp <- grep(days[i], files.long)
      lapply(tmp, function(j) {
        raster(files.long[j])
      })
    }
    rasters.agg <- aggRaster(data = rasters, 
                             agg.level = 24, 
                             write.file = TRUE,
                             days = days, 
                             path.out = path.out)
  
    stopCluster(cl)