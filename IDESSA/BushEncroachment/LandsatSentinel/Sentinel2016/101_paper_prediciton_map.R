# prediction map

# nice map:
library(raster)
library(rasterVis)
library(ggplot2)
library(RStoolbox)
library(cowplot)

pred <- raster("/media/marvin/Seagate Expansion Drive/summary_results/sentinel_prediction.tif")
hist(pred)
# create general theme
t <- theme(panel.background = element_blank(),
           axis.text.x = element_text(angle = 45, hjust = 1),
           text = element_text(family = "times", size = 3),
           legend.position = "bottom", legend.justification = "center",
           legend.text = element_text(size = 12), legend.title = element_text(size = 12))

# plot prediciton
pred_map <- ggR(pred, geom_raster = TRUE, stretch = "lin", quantiles = c(0.02, 0.98))+
  scale_x_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_y_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_fill_gradient(low = '#e8d186', high = '#556B2F',
                      breaks = c(0,1), labels = c(0, 1), name = element_blank(),
                      na.value = "white")+
  t 
pred_map

mapsize <- c(62700, 62800, -2906900, -2906800)
pred_tiny <- crop(pred, mapsize)

pred@extent




