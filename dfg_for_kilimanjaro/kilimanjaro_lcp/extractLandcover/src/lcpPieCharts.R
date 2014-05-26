# OS detection
switch(Sys.info()[["sysname"]], 
       "Windows" = setwd("F:/kilimanjaro/landcover/"), 
       "Linux" = setwd("/media/XChange/kilimanjaro/landcover"))

# Packages
library(ggplot2)

# Data import
lcp <- read.csv("out/kili_lcp_allbuff.csv", row.names = 1)

# Unique color scheme
col <- c("Bare_soil" = "grey75", #bare_soil
         "Clearing" = "red", #clearing
         "Clouds" = "white", #clouds
         "Coffee" = "bisque4", #coffee
         "Cropland" = "bisque", #cropland
         "Erica" = "darkorange2", #erica
         "Erica_valley" = "darkorange4", #erica_valley
         "Field" = "chocolate4", #field
         "Forest_lower_montane" = "chartreuse4", #forest_lower_montane
         "Forest_not_classified" = "darkgreen", #forest_not_classified
         "Forest_Ocotea" = "aquamarine1", #forest_ocotea
         "Forest_Ocotea_disturbed" = "aquamarine3", #forest_ocotea_disturbed
         "Forest_Ocotea_disturbed_valley" = "aquamarine4", #forest_ocotea_disturbed_valley
         "Forest_Podocarpus" = "darkolivegreen1", #forest_podocarpus
         "Forest_Podocarpus_disturbed" = "darkolivegreen4", #forest_podocarpus_disturbed
         "Forest_Podocarpus_valley" = "darkolivegreen3", #forest_podocarpus_valley
         "Grassland" = "chartreuse1", #grassland
         "Grassland_Savanna" = "burlywood1", #grassland_savanna
         "Grassland_subalpine" = "antiquewhite1", #grassland_subalpine
         "Grassland_trees" = "chartreuse3", #grassland_trees
         "Helicrysum" = "khaki1", #helicrysum
         "Homegarden" = "darkred", #homegarden
         "Settlement" = "darkorchid1", #settlement
         "Shadow" = "black", #shadow
         "Unclassified" = "darkmagenta", #unclassified
         "Water_body" = "deepskyblue") #water_body
names(col) <- tolower(names(col))

# # Draw a single pie chart for a single radius around cof1
# lcp.cof1.250 <- lcp[1, grep("250_nc", names(lcp))]
# lcp.cof1.250 <- lcp.cof1.250[, lcp.cof1.250[1, ] > 0]
# lcp.cof1.250 <- t(lcp.cof1.250)
# 
# luc <- sapply(strsplit(rownames(lcp.cof1.250), "_"), function(i) {
#   paste(i[1:(length(i)-2)], collapse = "_")
# })
# 
# lcp.cof1.250 <- data.frame(plotid = colnames(lcp.cof1.250), 
#                            luc = luc, 
#                            value = lcp.cof1.250[, 1], 
#                            row.names = NULL)
# 
# ggplot(aes(x = plotid, y = value, fill = luc), data = lcp.cof1.250) + 
#   geom_bar(width = 1, stat = "identity") + 
#   coord_polar(theta = "y") + 
#   labs(x = "", y = "") + 
#   theme_bw() + 
#   theme(axis.ticks = element_blank(), 
#         axis.text.y = element_blank()) 
# 
# # Draw pie charts for all radians around cof1
# lcp.cof1 <- lcp[1, grep("_nc", names(lcp))]
# lcp.cof1 <- lcp.cof1[, lcp.cof1[1, ] > 0]
# lcp.cof1 <- t(lcp.cof1)
# 
# radians <- sapply(strsplit(rownames(lcp.cof1), "_"), function(i) {
#   radius <- i[length(i) - 1]
#   return(factor(radius))
# })
# 
# luc <- sapply(strsplit(rownames(lcp.cof1), "_"), function(i) {
#   paste(i[1:(length(i)-2)], collapse = "_")
# })
# 
# lcp.cof1 <- data.frame(plotid = colnames(lcp.cof1), 
#                        luc = luc, 
#                        radius = radians,
#                        value = lcp.cof1[, 1], 
#                        row.names = NULL)
# 
# levels(lcp.cof1$radius) <- paste(levels(lcp.cof1$radius), "m")
# 
# png("out/cof1_all.png", width = 20, height = 20, units = "cm", res = 400, 
#     pointsize = 12)
# print(ggplot(aes(x = plotid, y = value, fill = luc), data = lcp.cof1) + 
#         geom_bar(width = 1, stat = "identity", position = "fill") + 
#         facet_wrap(~ radius, ncol = 2) + 
#         coord_polar(theta = "y") + 
#         scale_fill_manual("Land-cover type", values = col) + 
#         labs(x = "", y = "") + 
#         theme_bw() + 
#         theme(axis.ticks = element_blank(), 
#               axis.text.y = element_blank()))
# dev.off()

# Draw pie charts for all plots and all plots
for (i in 1:nrow(lcp)) {
  
  plt <- rownames(lcp)[i]
  
  lcp.plt <- lcp[i, grep("_nc", names(lcp))]
  lcp.plt <- lcp.plt[, lcp.plt[1, ] > 0 & !is.na(lcp.plt[1, ])]
  
  if (ncol(lcp.plt) > 0) {
    lcp.plt <- t(lcp.plt)
    
    radians <- sapply(strsplit(rownames(lcp.plt), "_"), function(i) {
      radius <- i[length(i) - 1]
      return(factor(radius))
    })
    
    luc <- sapply(strsplit(rownames(lcp.plt), "_"), function(i) {
      paste(i[1:(length(i)-2)], collapse = "_")
    })
    
    lcp.plt <- data.frame(plotid = colnames(lcp.plt), 
                          luc = luc, 
                          radius = radians,
                          value = lcp.plt[, 1], 
                          row.names = NULL)
    
    levels(lcp.plt$radius) <- paste(levels(lcp.plt$radius), "m")
    
    png(paste0("out/", plt, "_all.png"), width = 20, height = 20, units = "cm", res = 400, 
        pointsize = 12)
    print(ggplot(aes(x = plotid, y = value, fill = luc), data = lcp.plt) + 
            geom_bar(width = 1, stat = "identity", position = "fill") + 
            facet_wrap(~ radius, ncol = 2) + 
            coord_polar(theta = "y") + 
            scale_fill_manual("Land-cover type", values = col) + 
            labs(x = "", y = "") + 
            theme_bw() + 
            theme(axis.ticks = element_blank(), 
                  axis.text.y = element_blank()))
    dev.off()
  }
}