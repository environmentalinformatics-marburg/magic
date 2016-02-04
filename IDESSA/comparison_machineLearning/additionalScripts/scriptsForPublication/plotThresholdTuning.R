load("fit_nnet.Rdata")
usedPackages=c("caret","kernlab","ROCR","raster","latticeExtra","fields","reshape2",
               "grid","maps","mapdata","sp","rgdal","RColorBrewer","lattice","doParallel","hydroGOF","corrplot")

lapply(usedPackages, library, character.only=T)

##for publication:
t_size=unlist(fit_nnet$finalModel$tuneValue[1])
t_decay=unlist(fit_nnet$finalModel$tuneValue[2])
metrics <- fit_nnet$results[fit_nnet$results$size==t_size&fit_nnet$results$decay==t_decay, c(3, 5:7)]
names(metrics)=c("threshold","POD","1-POFD","Dist")
metrics <- melt(metrics, id.vars = "threshold",
                variable.name = "Resampled",
                value.name = "Data")
thresplot=ggplot(metrics, aes(x = threshold, y = value, color = variable,linetype=variable)) +
  geom_line() +
  scale_colour_manual(values = c("POD" = " grey20", "1-POFD" = "grey20","Dist" = "grey20"))+
  scale_linetype_manual(values = c("POD" =2, "1-POFD" = 3,"Dist" = 1))+
  ylab("") + xlab("Threshold") +
  geom_line(size=1)+
  theme(legend.position = "right",legend.title = element_blank(),
        axis.text=element_text(size=14),
        axis.text.x=element_text(colour="black"),
        axis.text.y=element_text(colour="black"),
       panel.background = element_rect(fill = 'white',colour="grey80"),
       legend.key=element_rect(fill="white",colour="white"),
       legend.text=element_text(size=14),
       axis.title.x = element_text(size = 14))

png("/home/hanna/Documents/tmp/ThresholdTuning.png",res=300,width=12,height=10,units = "in")
print(thresplot)
dev.off()
