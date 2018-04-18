# results kmeans clustering molopo aerials
library(plyr)
library(reshape2)
library(ggplot2)

vvi_fls <- list.files("/media/marvin/Seagate Expansion Drive/summary_results/VVIStats", full.names = TRUE)

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
mapsize <- c(62700, 62800, -2906900, -2906800)
mapsize[2] - mapsize[1]

aerial <- crop(aerial, mapsize)
classi <- crop(classi, mapsize)

# create general theme
t <- theme(panel.background = element_blank(),
           axis.text.x = element_text(angle = 45, hjust = 1),
           text = element_text(family = "times", size = 3),
           legend.position = "bottom", legend.justification = "center",
           legend.text = element_text(size = 12), legend.title = element_text(size = 12))

# plot the rgb aerial image
rgb_map <- ggRGB(aerial, r = 1, g = 2, b = 3)+
  scale_x_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_y_continuous(name = NULL, expand = c(0.001, 0.001))+
  t
rgb_map

# plot the vvi
# visualization with linear stretch!
vvi_map <- ggR(aerial, 4, geom_raster = TRUE, stretch = 'lin', quantiles = c(0.1, 0.99))+
  scale_x_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_y_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_fill_gradient(low = '#e8d186', high = '#556B2F',
                      breaks = c(0,1), labels = c(0.002, 0.1), name = element_blank())+
  t + theme(axis.title.y = element_blank(), axis.text.y = element_blank())
vvi_map

# plot the classification with 10 x 10 grid overlay
# make grid overlay
gridsize <- c(mapsize[1]+5, mapsize[2]-5, mapsize[3]+5, mapsize[4]-5)
grid_overlay <- expand.grid(y = seq(gridsize[3], gridsize[4], 10),
                            x = seq(gridsize[1], gridsize[2], 10))
# make only two classes
classi[classi == 3 | classi == 4] <- 2

cla_grid_map <- ggR(classi, geom_raster = TRUE, forceCat = TRUE)+
  scale_fill_manual(name = element_blank(), values = c('#556B2F', '#e8d186'),
                    labels = c("Woody Vegetation", "Other"))+
  geom_tile(data = grid_overlay, aes(x = x, y = y),
            color = "black", fill = NA, alpha = 0.6, size = 0.2)+
  scale_x_continuous(name = NULL, expand = c(0.001, 0.001))+
  scale_y_continuous(name = NULL, expand = c(0.001, 0.001))+
  t + theme(axis.title.y = element_blank(), axis.text.y = element_blank())
cla_grid_map

library(grid)
library(egg)
grid.newpage()
grid.draw(ggarrange(rgb_map, vvi_map, cla_grid_map, nrow = 1,
                    labels = c("(a)", "(b)", "(c)"),
                    label.args = list(gp = gpar(fontfamily = "times",
                                                fontface = "plain",
                                                fontsize = 13),
                                      vjust = -0.3)))

ggsave("/media/marvin/Daten/env_info/paper/classification_figure/aerial.png",
       rgb_map)

