##create data frames with all verification scores to create final boxplots for model validation
library(ggplot2)
library(grid)
library(proto)

datapath="/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/"#wo liegen die ganzen Modellordner?
resultpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/"
setwd(datapath)

model=c("rf","nnet","avNNet","svm")
time=c("day","inb","night")
timeDecription=c("day","twilight","night")

###### READ RAINRATE DATA

RAINOUT=data.frame()
for (i in 1:length(time)){
  for (k in 1:length(model)){
    RAIN=read.csv(paste0("Rain_rfInput_vp03_",time[i],"_as/VerificationScores_",model[k],".csv"))
    RAINOUT=rbind(RAINOUT,
               data.frame("VALUE"=unlist(RAIN),
                              "SCORE"=rep(c("RMSE","ME","MAE","Rsq"),c(rep(nrow(RAIN),length(names(RAIN))))),
                              "MODEL"=rep(toupper(model[k]),length(unlist(RAIN))),
                              "TIME"=rep(toupper(timeDecription[i]),length(unlist(RAIN)))
              )
    )
  }
}

###### READ RAIN AREA DATA
RINFOOUT=data.frame()
for (i in 1:length(time)){
  ROC=read.csv(paste0("RInfo_rfInput_vp03_",time[i],"_as/Confusion_comp/aucdata.csv"))
  for (k in 1:length(model)){
    RINFO=read.csv(paste0("RInfo_rfInput_vp03_",time[i],"_as/Confusion_comp/confusiondata_",model[k],".csv"))
    names(RINFO)[3]="POFD"#manually correct error in score name
    RINFO=data.frame(RINFO,"AUC"=eval(parse(text=paste0("ROC$",model[k]))))
    RINFOOUT=rbind(RINFOOUT,
                  data.frame("VALUE"=unlist(RINFO),
                             "SCORE"=rep(names(RINFO),c(rep(nrow(RINFO),length(names(RINFO))))),
                             "MODEL"=rep(toupper(model[k]),length(unlist(RINFO))),
                             "TIME"=rep(toupper(timeDecription[i]),length(unlist(RINFO)))
                  )
    )
  }
}

RINFOOUT$SCORE=factor(RINFOOUT$SCORE,levels=names(RINFO)) #keep order
#########################
#PLOT
#########################
library(scales)
library(proto)
library(grid)
source("/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/additionalScripts/scriptsForPublication/geom_boxplot_noOutliers.R")

bp.RINFOOUT <- ggplot(RINFOOUT, aes(x = MODEL, y = VALUE))+ 
#  geom_boxplot_noOutliers(aes(fill =MODEL),outlier.size = NA) + #use colors?
  geom_boxplot_noOutliers(outlier.size = NA) +
  theme_bw()+
  facet_grid(SCORE ~ TIME,scales = "free")+
#  scale_fill_manual(values = c("RF" = " lightcyan2", "NNET" = "lightblue","AVNNET" = "lightcyan3", "SVM" = "lightsteelblue"))+
  xlab("") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=14),
        panel.margin = unit(0.7, "lines"))



bp.RAINOUT <- ggplot(RAINOUT, aes(x = MODEL, y = VALUE))+ 
#  geom_boxplot_noOutliers(aes(fill =MODEL),outlier.size = NA) + #use colors?
  geom_boxplot_noOutliers(outlier.size = NA) +
  theme_bw() +
  facet_grid(SCORE ~ TIME,scales = "free")+
#  scale_fill_manual(values = c("RF" = " lightcyan2", "NNET" = "lightblue","AVNNET" = "lightcyan3", "SVM" = "lightsteelblue"))+
  xlab("") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=14),
        panel.margin = unit(0.7, "lines"),
        panel.background = element_rect(fill = NA, colour = NA),
        plot.background = element_rect(fill = NA, colour = NA))#+
  #geom_hline(y=rep(0,12),aes(colour=c(rep("transparent",11),1)))
pdf(paste0(resultpath,"/bp.RAIN.pdf"),width=10,height=14)

print(bp.RAINOUT)
y_at <- 1 - ggplot_build(bp.RAINOUT)$panel$ranges[[4]]$y.range[2] / 
  (ggplot_build(bp.RAINOUT)$panel$ranges[[4]]$y.range[2] - 
  ggplot_build(bp.RAINOUT)$panel$ranges[[4]]$y.range[1])
#current.vpTree()
seekViewport(name = "panel.6-4-6-4")
#grid.rect(gp=gpar(fill="black"))


grid.lines(y = y_at, gp = gpar(lty = 1, lwd = 3,col="grey"))

upViewport(0)

seekViewport(name = "panel.6-6-6-6")
#grid.rect(gp=gpar(fill="black"))

grid.lines(y = y_at, gp = gpar(lty = 1, lwd = 3,col="grey"))

upViewport(0)

seekViewport(name = "panel.6-8-6-8")
#grid.rect(gp=gpar(fill="black"))

grid.lines(y = y_at, gp = gpar(lty = 1, lwd = 3,col="grey"))

upViewport(0)
#grid.rect(gp = gpar(fill = "grey"))
print(bp.RAINOUT, newpage = FALSE)

dev.off()


pdf(paste0(resultpath,"/bp.RINFO.pdf"),width=10,height=14)
print(bp.RINFOOUT)
dev.off()

#pdf(paste0(resultpath,"/bp.RAIN.pdf"),width=10,height=14)
#print(bp.RAINOUT)
#dev.off()



