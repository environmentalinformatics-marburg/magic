# error map visualization

library(raster)
library(rgdal)
library(ggplot2)
library(ggmap)
library(egg)
library(grid)

train_loc <- readOGR("/media/marvin/Seagate Expansion Drive/summary_results/location_validation/locations_train.shp")
test_loc <- readOGR("/media/marvin/Seagate Expansion Drive/summary_results/location_validation/locations_test.shp")

train_df <- cbind(train_loc@data, train_loc@coords)
test_df <- cbind(test_loc@data, test_loc@coords)

study_area <- readOGR("/media/marvin/Seagate Expansion Drive/raw_data/study_area/study_area.shp")
study_area <- spTransform(study_area, train_loc@proj4string)


sa <- fortify(study_area)
tr_loc <- fortify(train_loc)
t <- theme(panel.background = element_blank(),
           text = element_text(family = "times", size = 9),
           legend.position = "bottom", legend.justification = "center",
           axis.title = element_blank(), axis.line = element_blank(), axis.text = element_blank(),
           axis.ticks = element_blank(),
           legend.text = element_text(size = 9), legend.title = element_text(size = 9))

# RMSE Plot
rmse_plot <- ggplot()+
  geom_polygon(data = study_area, aes(x = long, y = lat, group = group), color = "black", fill = "grey90")+
  geom_point(data = train_df, aes(x = coords.x1, y = coords.x2), color = "black", shape = "+", size = 3)+
  geom_point(data = test_df, aes(x = coords.x1, y = coords.x2, color = RMSE), size = 1.5, shape = 15)+
  scale_color_gradient(low = '#556B2F', high = '#e8d186')+
  t + coord_fixed()
# Rsq Plot  
rsq_plot <- ggplot()+
  geom_polygon(data = study_area, aes(x = long, y = lat, group = group), color = "black", fill = "grey90")+
  geom_point(data = train_df, aes(x = coords.x1, y = coords.x2), color = "black", shape = "+", size = 3)+
  geom_point(data = test_df, aes(x = coords.x1, y = coords.x2, color = Rsq), size = 1.5, shape = 15)+
  scale_color_gradient(high = '#556B2F', low = '#e8d186')+
  t + coord_fixed()



grid.newpage()
grid.draw(ggarrange(rsq_plot, rmse_plot, nrow = 1,
                    labels = c("(a)", "(b)"),
                    label.args = list(gp = gpar(fontfamily = "times",
                                                fontface = "plain",
                                                fontsize = 13))))
# mean bush densities
mean_bush_plot <- ggplot()+
  geom_polygon(data = study_area, aes(x = long, y = lat, group = group), color = "black", fill = "grey90")+
  geom_point(data = train_df, aes(x = coords.x1, y = coords.x2), color = "black", shape = "+", size = 3)+
  geom_point(data = test_df, aes(x = coords.x1, y = coords.x2, color = bush_mean), size = 1.5, shape = 15)+
  scale_color_gradient(high = '#556B2F', low = '#e8d186')+
  t + coord_fixed()
mean_bush_plot
