##for publication:
library(reshape2)
library(ggplot2)
mainpath <- "/media/hanna/data/CopyFrom181/Results/"
#mainpath <- "/media/hanna/data/CopyFrom181/Results/"
datapath <- paste0(mainpath,"Model/")
figurepath <- paste0(mainpath,"Figures/")

fit_nnet <- get(load(paste0(datapath,"day_model_RA.RData")))
t_size=unlist(fit_nnet$finalModel$tuneValue[1])
t_decay=unlist(fit_nnet$finalModel$tuneValue[2])
metrics <- fit_nnet$results[fit_nnet$results$size==t_size&fit_nnet$results$decay==t_decay, c(3, 5:7)]
names(metrics)=c("threshold","POD","1-POFD","Dist")
metrics <- melt(metrics, id.vars = "threshold",
                variable.name = "Resampled",
                value.name = "Data")
thresplot <- ggplot(metrics, aes(x = threshold, y = Data, color = Resampled,linetype=Resampled)) +
 # geom_line() +
  scale_colour_manual(values = c("POD" = " grey20", "1-POFD" = "grey20","Dist" = "grey20"))+
  scale_linetype_manual(values = c("POD" =2, "1-POFD" = 3,"Dist" = 1))+
  ylab("") + xlab("Threshold") + 
#  scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))
  geom_line(size=1)+
  theme(legend.position = "right",legend.title = element_blank(),
        axis.text=element_text(size=14),
        axis.text.x=element_text(colour="black"),
        axis.text.y=element_text(colour="black"),
        panel.background = element_rect(fill = 'white',colour="grey90"),
        legend.key=element_rect(fill="white",colour="white"),
        legend.text=element_text(size=14),
        panel.grid.major = element_line(colour = "grey70",size=0.1),
        axis.title.x = element_text(size = 14))

pdf(paste0(figurepath,"ThresholdTuning.pdf"),
    width=9,height=6)
print(thresplot)
dev.off()
