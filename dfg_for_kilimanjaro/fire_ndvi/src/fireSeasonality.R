### Global settings

# Clear workspace
rm(list = ls(all = TRUE))

# Working directory
switch(Sys.info()[["sysname"]], 
       "Linux" = setwd("/media/fdetsch/XChange/kilimanjaro/ndvi/"), 
       "Windows" = setwd("D:/kilimanjaro/temperature_gsod"))

# Required libraries
lib <- c("doParallel", "raster", "rgdal", "zoo", "Rsenal", "reshape2", "ggplot2")
sapply(lib, function(x) stopifnot(require(x, character.only = TRUE)))

# Parallel backend
registerDoParallel(cl <- makeCluster(2))


### Data import

## MODIS fire

# Import 8-day fire files (2001-2013)
fire.fls <- list.files("data/md14a1/aggregated/", pattern = ".tif$", 
                       full.names = TRUE)

fire.stck <- stack("out/fire_agg/fire_agg_mnth.tif")

# Using monthly aggregated raster data
fire.st.nd <- foreach(h = c("2013", "2013"), i = c("2001", "2009"), 
                      j = c("2005", "2013"), .packages = lib) %dopar% {
    
  month.seq <- as.yearmon(seq(as.Date("2001-01-01"), 
                              as.Date("2013-12-31"), by = "month"))
  tmp.fire.stck <- fire.stck[[grep(paste("Jan", i), month.seq):
                                grep(paste("Dez", j), month.seq)]]
  
  nfires <- sapply(1:nlayers(tmp.fire.stck), function(k) {
    sum(tmp.fire.stck[[k]][] > 0)
  })
  
  fire.harmonics <- 
    round(vectorHarmonics(nfires, frq = 12, fun = mean, m = 2, 
                          st = c(as.numeric(i), 01), nd = c(as.numeric(j), 12)))
  fire.harmonics[fire.harmonics < 0] <- 0
  
  #   return(data.frame("month" = month.seq[grep(paste("Jan", i), month.seq):
  #                                           grep(paste("Dez", j), month.seq)], 
  #                     "nfires" = nfires))

  fire.harmonics.df <- data.frame(month = month.abb, nfire = fire.harmonics)
  names(fire.harmonics.df)[2] <- paste("nfire", i, j, sep = "_")
  
  return(fire.harmonics.df)
}  

# Using 8-day raster data
fire.st.nd <- foreach(h = c("2013", "2013"), i = c("2001", "2009"), 
                      j = c("2005", "2013"), .packages = lib) %dopar% {
                        
                        # Limit time window from Terra-MODIS launch to Dec 2013
                        st <- grep(paste0("_", i), fire.fls)[1]
                        nd <- grep(paste0("_", j), fire.fls)[length(grep(paste0("_", j), fire.fls))]
                        
                        tmp.fire.fls <- fire.fls[st:nd]
                        
                        # Setup time series
                        fire.dates <- as.Date(substr(basename(tmp.fire.fls), 8, 14), format = "%Y%j")
                        
                        fire.ts <- do.call("c", lapply(i:j, function(k) { 
                          seq(as.Date(paste(k, "01", "01", sep = "-")), 
                              as.Date(paste(k, "12", "31", sep = "-")), 8)
                        }))
                        
                        # Identify available fire data based on continuous 8-day interval
                        tmp.fire.ts <- merge(data.frame(fire.ts, 1:length(fire.ts)), 
                                             data.frame(fire.dates, 1:length(fire.dates)), 
                                             by = 1, all.x = TRUE)
                        
                        tmp.fire.ts.fls <- 
                          merge(data.frame(date = tmp.fire.ts[, 1]), 
                                data.frame(date = as.Date(substr(basename(tmp.fire.fls), 8, 14), format = "%Y%j"), 
                                           file = tmp.fire.fls, stringsAsFactors = FALSE), 
                                by = "date", all.x = TRUE)
                        
                        tmp.fire.rst <- lapply(tmp.fire.ts.fls[, 2], function(k) {
                          if (is.na(k))
                            return(NA)
                          else
                            return(raster(k))
                        })
                        
                        tmp.fire.ts.fls$nfire <- sapply(tmp.fire.rst, function(k) {
                          if (!is.logical(k)) 
                            sum(k[] > 0)
                          else
                            NA
                        })
                        
                        nfires <- aggregate(tmp.fire.ts.fls$nfire, 
                                            by = list(as.yearmon(tmp.fire.ts.fls$date)), 
                                            FUN = function(x) sum(x, na.rm = TRUE))
                        
                        fire.harmonics <- 
                          round(vectorHarmonics(nfires[, 2], frq = 12, fun = mean, m = 2, 
                                                st = c(as.numeric(i), 01), nd = c(as.numeric(j), 12)))
                        fire.harmonics[fire.harmonics < 0] <- 0
                        
                        fire.harmonics.df <- data.frame(month = month.abb, nfire = fire.harmonics)
                        names(fire.harmonics.df)[2] <- paste("nfire", i, j, sep = "_")
                        
                        return(fire.harmonics.df)
                      }  

 
fire.harmonics <- do.call(function(x, y) melt(merge(x, y, by = 1)), fire.st.nd)
fire.harmonics$month <- factor(fire.harmonics$month, levels = month.abb)


### Plotting

label.st <- paste(c(2001, 2005), collapse = "-")
label.nd <- paste(c(2009, 2013), collapse = "-")

ggplot(aes(x = month, y = value, colour = variable, group = variable), 
       data = fire.harmonics) + 
  geom_line(lwd = 1) + 
  scale_colour_manual("", values = c("cornflowerblue", "red2"), 
                      labels = c(label.st, label.nd)) + 
  labs(list(x = "\nMonth", y = "No. of fire pixels")) + 
  theme_bw() + 
  theme(legend.key = element_rect(fill = "transparent"), 
        panel.grid.major = element_line(size = 1.2), 
        panel.grid.minor = element_line(size = 1.1))