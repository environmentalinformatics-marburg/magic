library(caret)
library(randomForest)
library(ggplot2)

# load the model FFS or final model
get(load("D:/model/sentinel_FFS.RData"))
get(load("D:/model/sentinelmodel.RData"))


# Variable Importance Plot for the FFS model
v_imp <- model$finalModel$importance
imp <- data.frame(var = rownames(v_imp), IncNodePurity = v_imp)
imp <- imp[with(imp, order(imp$IncNodePurity, decreasing = TRUE)),]
imp$var <- c("B4 - jul", "ndvi_sd - jan", "Sigma0 - jan", "B2 - jul", "B3 - apr",
             "B9 - jul", "B8 - jul", "B11 - jul", "B11 - jan", "B7 - jul", "B1 - jan")

pdf("D:/summary_results/FFS_varimp.pdf")
ggplot(data = imp, aes(x = factor(var, levels = rev(var)), y =  IncNodePurity))+
  geom_bar(stat = "identity", width = 0.8, fill = "white", color = "black") +
  geom_text(aes(label = var), size = 4, fontface = "bold", color = "black", position = position_fill(), hjust = 0)+
  geom_text(aes(label = round(IncNodePurity, 1)), size = 4, color = "black", position = position_identity(), hjust = 1.2)+
  theme(axis.line.y = element_blank(), axis.text.y = element_blank(),
        axis.ticks.y = element_blank(), axis.title.y = element_blank(), strip.background = element_blank())+
  theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) +
  scale_y_continuous(expand = c(0,0), breaks = c(0,20,40,60,80,100,120,140,160), limits = c(0,165))+
  ylab("Increase in node purity")+
  coord_flip()
dev.off()



