library(caret)
library(randomForest)
library(ggplot2)
source("/media/marvin/Seagate Expansion Drive/scripts/Rsenal_regressionStats.R")
library(viridis)


# load validation statistics:
stat <- read.csv("D:/summary_results/external_valid_tiles.csv")
stat_a <- read.csv("D:/summary_results/external_valid_all.csv")

# hexbin plot

# load observation and prediction
testdata <- readRDS("D:/model_validation/test_data.RDS")
testdata <- na.omit(testdata)
obs <- testdata$bush_perc
pred <- readRDS("D:/summary_results/prediction_all.RDS")

dat <- data.frame(obs = obs, pred = pred)

pdf("D:/summary_results/externalvalidation_hexplot.pdf")
ggplot(dat, aes(obs,pred)) + 
  stat_binhex(bins=100)+
  scale_x_continuous(expand = c(0,0), limit = c(0,1))+
  scale_y_continuous(expand = c(0,0), limit = c(0,1))+
  xlab("Observed bush density in %")+
  ylab("Predicted bush density in %")+
  geom_abline(slope=1, intercept=0,lty=2)+
  scale_fill_gradientn(name = "Data points", trans = "log", 
                       breaks = 10^(0:4),colors=viridis(10))+
  theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())
dev.off()


# RMSE plot
plot(stat$RMSE ~ stat$bush_mean)

ggplot(stat, aes(x = bush_mean, y = RMSE.se))+
  geom_point(size = 1)+
  xlab("Mean woody vegetation cover of location")+
  ylab("RMSE of location")+
  theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())
boxplot(stat$RMSE)

plot(stat$RMSE / stat$bush_mean)
range(stat$RMSE)


# boxplot of pred and obs
dat_box <- data.frame(cat = c(rep("obs", 10789347), rep("pred", 10789347)),
                      cover = c(obs, pred))




valid_bp <- ggplot(data = dat_box, mapping = aes(x = cat, y = cover))+
  geom_boxplot(fill = "gray90", outlier.shape = NA)+
  ylab("Woody vegetation cover")+
  scale_x_discrete(label = c("Observed", "Predicted"), expand = c(0,0))+
    theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.title.x = element_blank())

pdf("D:/summary_results/obs_pred_boxplot.pdf")
valid_bp
dev.off()  



valid_vp <- ggplot(data = dat_box, mapping = aes(x = cat, y = cover))+
  geom_violin(fill = "gray90", draw_quantiles = c(0.25,0.5,0.75))+
  ylab("Woody vegetation cover")+
  scale_x_discrete(label = c("Observed", "Predicted"))+
  scale_y_continuous(expand = c(0,0))+
  theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.title.x = element_blank())

pdf("D:/summary_results/obs_pred_violin.pdf")
valid_vp
dev.off()



library(ggplot2)
library(dplyr)

dat_box <-
  dat_box %>%
  group_by(cat) %>%
  mutate(outlier = cover > median(cover) + IQR(cover) * 1.5) %>%
  ungroup


table(dat_box$outlier[dat_box$cat == "pred"])
table(dat_box$outlier[dat_box$cat == "obs"])



