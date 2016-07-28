###visualize validation
library(proto)
library(grid)

setwd("/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/validation/")
source("/home/hanna/Documents/release/environmentalinformatics-marburg/magic/IDESSA/comparison_machineLearning/additionalScripts/scriptsForPublication/geom_boxplot_noOutliers.R")

validation_files <- list.files(,pattern="^evaluation_validation")
validation_files_spectral <- list.files(,pattern="OnlySpectral_evaluation_validation")

RINFOOUT=data.frame()
for (dayt in c("day","night")){
  texture <- get(load(grep(dayt,grep("RInfo",validation_files,value=TRUE),value=TRUE)))
  SpectralOnly <- get(load(grep(dayt,grep("RInfo",validation_files_spectral,value=TRUE),
                                value=TRUE)))
  RINFOOUT<-rbind(RINFOOUT,cbind(texture,"time"=dayt,"type"="optimal model"),cbind(SpectralOnly,"time"=dayt,"type"="only spectral"))
}
names(RINFOOUT)[3]="POFD"#manually correct error in score name
RINFOUT=data.frame("VALUE"=unlist(RINFOOUT[,c(2:4,5,9)]),
                   "SCORE"=rep(names(RINFOOUT[,c(2:4,5,9)]),
                               c(rep(nrow(RINFOOUT[,c(2:4,5,9)]),
                                     length(names(RINFOOUT[,c(2:4,5,9)]))))),
                   "TIME"=unlist(RINFOOUT[,10]),
                   "MODEL"=unlist(RINFOOUT[,11]))



RAINOUT=data.frame()
for (dayt in c("day","night")){
  texture <- get(load(grep(dayt,grep("Rain",validation_files,value=TRUE),value=TRUE)))
  SpectralOnly <- get(load(grep(dayt,grep("Rain",validation_files_spectral,value=TRUE),
                                value=TRUE)))
  RAINOUT<-rbind(RAINOUT,cbind(texture,"time"=dayt,"type"="optimal model"),cbind(SpectralOnly,
                                                                                 "time"=dayt,"type"="only spectral"))
}
RAINOUT=data.frame("VALUE"=unlist(RAINOUT[,c(2,4,6,8)]),
                   "SCORE"=rep(names(RAINOUT[,c(2,4,6,8)]),
                               c(rep(nrow(RAINOUT[,c(2,4,6,8)]),
                                     length(names(RAINOUT[,c(2,4,6,8)]))))),
                   "TIME"=unlist(RAINOUT[,9]),
                   "MODEL"=unlist(RAINOUT[,10]))




RInfo <- ggplot(RINFOUT, aes(x = MODEL, y = VALUE))+ 
  geom_boxplot_noOutliers(outlier.size = NA, notch = TRUE)+ 
  theme_bw()+
  facet_grid(SCORE ~ TIME,scales = "free")+
  xlab("") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=14),
        panel.margin = unit(0.7, "lines"))

Rain <- ggplot(RAINOUT, aes(x = MODEL, y = VALUE))+ 
  geom_boxplot_noOutliers(outlier.size = NA, notch = TRUE)+ 
  theme_bw()+
  facet_grid(SCORE ~ TIME,scales = "free")+
  xlab("") + ylab("")+
  theme(legend.title = element_text(size=16, face="bold"),
        legend.text = element_text(size = 16),
        legend.key.size=unit(1,"cm"),
        strip.text.y = element_text(size = 16),
        strip.text.x = element_text(size = 16),
        axis.text=element_text(size=14),
        panel.margin = unit(0.7, "lines"))



pdf("/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_textureParameters/SubmissionIII/figureprep/validation_RAIN.pdf",
    width=9,height=10)
Rain
dev.off()

pdf("/home/hanna/Documents/Presentations/Paper/submitted/Meyer2016_textureParameters/SubmissionIII/figureprep/validation_RInfo.pdf",
    width=9,height=10)
RInfo
dev.off()

