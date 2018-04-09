# results kmeans clustering molopo aerials
library(plyr)
library(reshape2)
library(ggplot2)

vvi_fls <- list.files("F:/VVIStats/", full.names = TRUE)

vvi_stats <- lapply(seq(length(vvi_fls)), function(i){
  read.csv(vvi_fls[i])
})
vvi <- do.call(rbind, vvi_stats)
aggregate(vvi$vvi, by = list(vvi$new_class), mean)
aggregate(vvi$vvi, by = list(vvi$new_class), sd)
aggregate(vvi$vvi, by = list(vvi$new_class), range)

boxplot(vvi$vvi ~ vvi$new_class)

# nice map:
library(raster)
library(ggplot2)
library(RStoolbox)
library(cowplot)

aerial <- stack('/media/marvin/Daten/env_info/paper/classification_figure/rgb_vvi1088.tif')
classi <- raster('/media/marvin/Daten/env_info/paper/classification_figure/lcc_100.tif')
# 250 x 250 window for mapping
mapsize <- c(62900, 62950, -2907050, -2907000)
mapsize[2] - mapsize[1]

aerial <- crop(aerial, mapsize)
classi <- crop(classi, mapsize)

# plot the rgb aerial image
rgb_map <- ggRGB(aerial, r = 1, g = 2, b = 3)+
  scale_x_continuous(name = NULL, expand = c(0.0001, 0.0001))+
  scale_y_continuous(name = NULL, expand = c(0.0001,0.0001))+
  theme(panel.background = element_blank(), panel.grid.major = element_line('black'))
rgb_map

# plot the vvi
# visualization with linear stretch!
vvi_map <- ggR(aerial, 4, geom_raster = TRUE, stretch = 'lin', quantiles = c(0.1, 0.99))+
  scale_x_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_y_continuous(name = NULL, expand = c(0.001,0.001))+
  scale_fill_gradient(low = '#FFFFFF', high = '#556B2F', name = "VVI",
                      breaks = c(0,1), labels = c(0.002, 0.116))+
  theme(panel.background = element_blank(), panel.grid.major = element_line('black'))
vvi_map

# plot the classification with 10 x 10 grid overlay
classi <- raster::reclassify(classi, matrix(c(3,4,2,2), nrow = 2))

gridsize <- c(mapsize[1]+5, mapsize[2]-5, mapsize[3]+5, mapsize[4]-5)
grid_overlay <- expand.grid(y = seq(gridsize[3], gridsize[4], 10), x = seq(gridsize[1], gridsize[2], 10))

cla_grid_map <- ggR(classi, geom_raster = TRUE, forceCat = TRUE)+
  scale_fill_manual(name = 'Classes', values = c('#556B2F', '#f6f6aa'), labels = c("Woody Vegetation", "Other"))+
  theme(panel.background = element_blank(), panel.grid.major = element_line('black'))+
  geom_tile(data = grid_overlay, aes(x = x, y = y), color = "black", fill = NA, alpha = 0.6, size = 0.8)+
  scale_x_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_y_continuous(name = NULL, expand = c(0.001, 0.001))
cla_grid_map

ggsave("/media/marvin/Daten/env_info/paper/classification_figure/aerial.png",
       rgb_map)
ggsave("/media/marvin/Daten/env_info/paper/classification_figure/vvi.png",
       vvi_map)
ggsave("/media/marvin/Daten/env_info/paper/classification_figure/classification_sentinel_grid.png",
       cla_grid_map)
