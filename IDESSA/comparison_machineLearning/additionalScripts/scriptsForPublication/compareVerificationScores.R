##create data frames with all verification scores to create final boxplots for model validation


datapath="/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/"#wo liegen die ganzen Modellordner?
resultpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/"
setwd(datapath)

model=c("rf","nnet","avNNet","svm")
time=c("day","inb","night")
time=c("inb","night")

###### READ RAINRATE DATA

RAINOUT=data.frame()
for (i in 1:length(time)){
  for (k in 1:length(model)){
    RAIN=read.csv(paste0("Rain_rfInput_vp03_",time[i],"_as/VerificationScores_",model[k],".csv"))
    RAINOUT=rbind(RAINOUT,
               data.frame("VALUE"=unlist(RAIN),
                              "SCORE"=rep(names(RAIN),c(rep(nrow(RAIN),length(names(RAIN))))),
                              "MODEL"=rep(model[k],length(unlist(RAIN))),
                              "TIME"=rep(time[i],length(unlist(RAIN)))
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
    RINFO=data.frame(RINFO,"AUC"=eval(parse(text=paste0("ROC$",model[k]))))
    
    RINFOOUT=rbind(RINFOOUT,
                  data.frame("VALUE"=unlist(RINFO),
                             "SCORE"=rep(names(RINFO),c(rep(nrow(RINFO),length(names(RINFO))))),
                             "MODEL"=rep(model[k],length(unlist(RINFO))),
                             "TIME"=rep(time[i],length(unlist(RINFO)))
                  )
    )
  }
}



#########################
#PLOT
#########################
library(scales)
source("/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/additionalScripts/geom_boxplot_noOutliers.R")

bp.RINFOOUT <- ggplot(RINFOOUT, aes(x = MODEL, y = VALUE))+ 
  geom_boxplot_noOutliers(fill = "grey90",notch=T,outlier.size = NA) +
  theme_bw() +
  facet_grid(SCORE ~ TIME,scales = "free")

bp.RAINOUT <- ggplot(RAINOUT, aes(x = MODEL, y = VALUE))+ 
  geom_boxplot_noOutliers(fill = "grey90",notch=T,outlier.size = NA) +
  theme_bw() +
  facet_grid(SCORE ~ TIME,scales = "free")


#g.bw <- bw.ggplot + 
#  geom_boxplot(fill = "grey90",notch=T,outlier.size = NA) +
#  theme_bw() +
#  facet_grid(SCORE ~ TIME,scales = "free")


png(paste0(resultpath,"/bp.RINFO.png"),res=300,width=10,height=14,units = "in")
print(bp.RINFOOUT)
dev.off()

png(paste0(resultpath,"/bp.RAIN.png"),res=300,width=10,height=14,units = "in")
print(bp.RAINOUT)
dev.off()
