### Analyze rfe ################################################################

datapath <- "/media/hanna/ubt_kdata_0005/improve_DE_retrieval/"
resultpath <- "/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/"

daytime="day"
response="RInfo"

modelIn<- paste0(datapath,"rfeModel_",daytime,"_",response,".Rdata")

load(modelIn)



library(Rainfall)

pdf (paste0(resultpath,daytime,"_",response,"_rfe_cv.pdf"),width=10,height=8)
plotRfeCV(rfeModel)
dev.off()

pdf (paste0(resultpath,daytime,"_",response,"_rfe_cv_detail.pdf"),width=10,height=8)
plotRfeCV(rfeModel,xlim=c(1,50),ylim=c(0.91,0.947))
dev.off()

#predictors(rfeModel)

pdf (paste0(resultpath,daytime,"_",response,"_rfe_varimp.pdf"),width=10,height=8)
plot(varImp(rfeModel$fit,scale=TRUE),col="black")
dev.off()

pdf (paste0(resultpath,daytime,"_",response,"_rfe_varimp_10.pdf"),width=10,height=8)
plot(varImp(rfeModel$fit,scale=TRUE),10,col="black")
dev.off()


#pickVars(rfeModel$variables,10)
