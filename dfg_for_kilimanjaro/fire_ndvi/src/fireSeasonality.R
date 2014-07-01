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

# Import monthly RasterStack (2001-2013)
fire.stck <- stack("out/fire_agg/fire_agg_mnth_01_13.tif")

# Using monthly aggregated raster data
fire.st.nd <- foreach(i = c("2001", "2009", "2001", "2008"), 
                      j = c("2005", "2013", "2006", "2013"), 
                      .packages = lib) %dopar% {
    
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
  
  fire.harmonics.df <- data.frame(month = month.abb, nfire = fire.harmonics)
  names(fire.harmonics.df)[2] <- paste("nfire", i, j, sep = "_")
  
  return(fire.harmonics.df)
}  
 
fire.harmonics <- Reduce(function(...) merge(..., by = 1, sort = FALSE), fire.st.nd)
fire.harmonics <- melt(fire.harmonics, id.vars = "month")
fire.harmonics$month <- factor(fire.harmonics$month, levels = month.abb)
fire.harmonics$variable <- 
  factor(fire.harmonics$variable, 
         levels = paste0("nfire_", c("2001_2005", "2001_2006", "2008_2013", "2009_2013")))


### Plotting

greys <- brewer.pal(9, "Greys")
blues <- brewer.pal(9, "Blues")

cols = c("nfire_2001_2005" = greys[3], 
         "nfire_2009_2013" = greys[9], 
         "nfire_2001_2006" = blues[3], 
         "nfire_2008_2013" = blues[9])

label.st.1 <- paste(c(2001, 2005), collapse = "-")
label.st.2 <- paste(c(2001, 2006), collapse = "-")
label.nd.1 <- paste(c(2009, 2013), collapse = "-")
label.nd.2 <- paste(c(2008, 2013), collapse = "-")

# png("out/fire_seasonality_01_0506_0809_13.png", width = 35, height = 20, 
#     units = "cm", pointsize = 15, res = 300)
# ggplot(aes(x = month, y = value, colour = variable, group = variable, 
#            linetype = variable), data = fire.harmonics) + 
#   geom_line(lwd = 2) + 
#   scale_colour_manual("", values = cols, 
#                       labels = c(label.st.1, label.st.2, label.nd.2, label.nd.1)) + 
#   scale_linetype_manual("", values = c(2, 1, 1, 2), 
#                         labels = c(label.st.1, label.st.2, label.nd.2, label.nd.1)) + 
#   labs(list(x = "\nMonth", y = "No. of fire pixels")) + 
#   theme_bw() + 
#   theme(legend.key = element_rect(fill = "transparent"), 
#         panel.grid.major = element_line(size = 1.2), 
#         panel.grid.minor = element_line(size = 1.1))
# dev.off()

png("out/fire_seasonality_01_05_09_13.png", width = 35, height = 20, 
    units = "cm", pointsize = 15, res = 300)
ggplot(aes(x = month, y = value, colour = variable, group = variable), 
       data = subset(fire.harmonics, variable %in% c("nfire_2001_2005", "nfire_2009_2013"))) + 
  geom_line(lwd = 2) + 
  scale_colour_manual("", values = cols, 
                      labels = c(label.st.1, label.nd.1)) + 
  labs(list(x = "\nMonth", y = "No. of fire pixels")) + 
  theme_bw() + 
  theme(text = element_text(size = 15), 
#         panel.grid.major = element_line(size = 1.1), 
#         panel.grid.minor = element_line(size = 1), 
        legend.key = element_rect(fill = "transparent")) 
dev.off()
