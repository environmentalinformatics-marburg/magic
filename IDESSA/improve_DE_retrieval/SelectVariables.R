###analyse the train model from the comparison study
#find best performing parameters.


load("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/Rain_rfInput_vp03_day_as/fit_nnet.RData")
fit_nnet_day=fit_nnet

load("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/Rain_rfInput_vp03_inb_as/fit_nnet.RData")
fit_nnet_inb=fit_nnet

load("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/Rain_rfInput_vp03_night_as/fit_nnet.RData")
fit_nnet_night=fit_nnet

library(latticeExtra)
library(caret)

changeNamesOld=c("B11","B08","B0709","B0103","B03","SZen","B02","B01","B05","B0610",
  "B0409","B06","B0509","B07","B0910", "B10","B04","B0406","B09")
changeNamesNew=c("IR13.4","IR9.7","T8.7_10.8", "T0.6_1.6","NIR1.6","sunzenith","VIS0.8","VIS0.6","WV6.2",
              "T7.3_12.0","T3.9_10.8","WV7.3","T6.2_10.8","IR8.7","T10.8_12.0","IR12.0","IR3.9","T3.9_7.3","IR10.8")
  



day=varImp(fit_nnet_day)  
ImpMeasure<-data.frame(day$importance)
ImpMeasure$Vars<-row.names(ImpMeasure)
ImpMeasure=ImpMeasure[-(rownames(day$importance)=="SZen"),]
day$importance=ImpMeasure[1]

inb=varImp(fit_nnet_inb)
ImpMeasure<-data.frame(inb$importance)
ImpMeasure$Vars<-row.names(ImpMeasure)
ImpMeasure=ImpMeasure[-(rownames(inb$importance)=="SZen"),]
inb$importance=ImpMeasure[1]

night=varImp(fit_nnet_night)


rownames(day$importance)=cbind(changeNamesOld,changeNamesNew)[match(rownames(day$importance),cbind(changeNamesOld,changeNamesNew)[,1]),2]
rownames(inb$importance)=cbind(changeNamesOld,changeNamesNew)[match(rownames(inb$importance),cbind(changeNamesOld,changeNamesNew)[,1]),2]
rownames(night$importance)=cbind(changeNamesOld,changeNamesNew)[match(rownames(night$importance),cbind(changeNamesOld,changeNamesNew)[,1]),2]


day=plot(day,col="black")
inb=plot(inb,col="black")
night=plot(night,col="black")
tmp=c(night,inb,day,layout=c(1,3))

pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/varImpCompStudy.pdf",width=6,height=13)
update(tmp,between=list(y=0.75),strip=strip.custom(factor.levels=rev(c("Day","Twilight","Night")),bg="grey90"))
dev.off()

