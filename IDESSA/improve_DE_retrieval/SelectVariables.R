###analyse the train model from the comparison study

load("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/Rain_rfInput_vp03_day_as/fit_nnet.RData")
fit_nnet_day=fit_nnet

load("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/Rain_rfInput_vp03_inb_as/fit_nnet.RData")
fit_nnet_inb=fit_nnet

load("/media/hanna/ubt_kdata_0005/pub_rapidminer/Results/Rain_rfInput_vp03_night_as/fit_nnet.RData")
fit_nnet_night=fit_nnet

library(latticeExtra)
library(caret)


day=plot(varImp(fit_nnet_day),col="black")
inb=plot(varImp(fit_nnet_inb),col="black")
night=plot(varImp(fit_nnet_night),col="black")
tmp=c(night,inb,day,layout=c(1,3))

pdf("/media/hanna/ubt_kdata_0005/improve_DE_retrieval/varImpCompStudy.pdf",width=6,height=10)
update(tmp,between=list(y=0.75),strip=strip.custom(factor.levels=rev(c("Day","Twilight","Night")),bg="grey90"))
dev.off()


#change names using lookup
  
  
day$panel.args[[1]]$y