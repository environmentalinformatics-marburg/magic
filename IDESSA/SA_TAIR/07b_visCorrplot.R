rm(list=ls())
library(corrplot)
mainpath <- "/home/hanna/Documents/Projects/IDESSA/airT/forPaper/"
modelpath <- paste0(mainpath,"/modeldat")
vispath <- paste0(mainpath,"visualizations/")
load(paste0(modelpath,"/V1/modeldata.RData"))

names(dataset)[names(dataset)=="Dem"] <- "Elevation"
names(dataset)[names(dataset)=="Precseason"] <- "Rainy Season"
names(dataset)[names(dataset)=="sunzenith"] <- "Solar Zenith Angle"
crl <- cor(dataset[,c(3:14,20,23,25,15)])
col2 <- colorRampPalette(c("#67001F", "#B2182B", "#D6604D", "#F4A582", "#FDDBC7",
                           "#FFFFFF", "#D1E5F0", "#92C5DE", "#4393C3", "#2166AC", "#053061"))
pdf(paste0(vispath,"/corrplotV2.pdf"),width=8,height=7)
corrplot(crl,type="lower",method="color",tl.col="black",
         col=rev(col2(200)))
dev.off()

