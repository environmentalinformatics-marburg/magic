#compare verification scores for aggregation

datapath=("/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/")
Fileslist=list.files(datapath,pattern=".Rdata",full.names=T)
Fileslist_short=list.files(datapath,full.names=F,glob2rx(c("*Rdata","day")))
source("/home/hanna/Documents/Projects/IDESSA/Precipitation/1_comparisonML/additionalScripts/scriptsForPublication/geom_boxplot_noOutliers.R")


for (i in 1:length(Fileslist)){
  assign(substr(Fileslist_short[i],1,nchar(Fileslist_short[i])-6),get(load(Fileslist[i])))
}

day24=data.frame("VALUE"=c(unlist(MAE_day_24),unlist(ME_day_24),unlist(RMSE_day_24),unlist(RSQ_day_24)),
                 "SCORE"=c(rep("MAE",length(MAE_day_24[[1]])*4),rep("ME",length(MAE_day_24[[1]])*4),
                           rep("RMSE",length(MAE_day_24[[1]])*4),rep("RSQ",length(MAE_day_24[[1]])*4)),
                  "MODEL"=rep(toupper(names(MAE_day_24)),rep(length(unlist(MAE_day_24))/4,4)),
                  "TIME"=rep("24h",length(unlist(MAE_day_24))*4))

day3=data.frame("VALUE"=c(unlist(MAE_day_3),unlist(ME_day_3),unlist(RMSE_day_3),unlist(RSQ_day_3)),
                 "SCORE"=c(rep("MAE",length(MAE_day_3[[1]])*4),rep("ME",length(MAE_day_3[[1]])*4),
                           rep("RMSE",length(MAE_day_3[[1]])*4),rep("RSQ",length(MAE_day_3[[1]])*4)),
                 "MODEL"=rep(toupper(names(MAE_day_3)),rep(length(unlist(MAE_day_3))/4,4)),
                 "TIME"=rep("DAY 3h",length(unlist(MAE_day_3))*4))

inb3=data.frame("VALUE"=c(unlist(MAE_inb_3),unlist(ME_inb_3),unlist(RMSE_inb_3),unlist(RSQ_inb_3)),
                "SCORE"=c(rep("MAE",length(MAE_inb_3[[1]])*4),rep("ME",length(MAE_inb_3[[1]])*4),
                          rep("RMSE",length(MAE_inb_3[[1]])*4),rep("RSQ",length(MAE_inb_3[[1]])*4)),
                "MODEL"=rep(toupper(names(MAE_inb_3)),rep(length(unlist(MAE_inb_3))/4,4)),
                "TIME"=rep("INB 3h",length(unlist(MAE_inb_3))*4))

night3=data.frame("VALUE"=c(unlist(MAE_night_3),unlist(ME_night_3),unlist(RMSE_night_3),unlist(RSQ_night_3)),
                "SCORE"=c(rep("MAE",length(MAE_night_3[[1]])*4),rep("ME",length(MAE_night_3[[1]])*4),
                          rep("RMSE",length(MAE_night_3[[1]])*4),rep("RSQ",length(MAE_night_3[[1]])*4)),
                "MODEL"=rep(toupper(names(MAE_night_3)),rep(length(unlist(MAE_night_3))/4,4)),
                "TIME"=rep("NIGHT 3h",length(unlist(MAE_night_3))*4))

aggregatedData=rbind(day3,inb3,night3,day24)
aggregatedData$MODEL=factor(aggregatedData$MODEL,levels=toupper(names(MAE_inb_3)))


bp.RAINOUT <- ggplot(aggregatedData, aes(x = MODEL, y = VALUE))+ 
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
        panel.margin = unit(0.5, "lines"))

png(paste0(datapath,"/bp.Aggregation.png"),res=300,width=14,height=14,units = "in")
print(bp.RAINOUT)
dev.off()