### Analyze rfe ################################################################

library(Rainfall)
library(Rsenal)


datapath <- "/media/hanna/ubt_kdata_0005/improve_DE_retrieval/"
resultpath <- "/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/"

daytime="day"
response="Rain"

modelIn<- paste0(datapath,"rfeModel_",daytime,"_",response,".Rdata")

load(modelIn)


### Select variables ###########################################################

#vars <- varsRfeCV(rfeModel)
vars <- rfeModel$optVariables
write.table(vars,paste0(resultpath,daytime,"_",response,"_selectedVars.csv"),
            row.names=FALSE)

varsRfeCV(rfeModel)
write.table(varsRfeCV(rfeModel),paste0(resultpath,daytime,"_",response,"_Vars_oneSE.csv"),
            row.names=FALSE)

### Plotting ###################################################################
if (response=="Rain"){
  pdf (paste0(resultpath,daytime,"_",response,"_rfe_cv.pdf"),width=10,height=8)
  plotModelCV(rfeModel,sderror = TRUE)
  plotModelCV(rfeModel,metric="Rsquared",sderror = TRUE)
  plotModelCV(rfeModel,metric="Rsquared",xlim=c(1,55),ylim=c(0.1,0.4),sderror = TRUE)
  dev.off()
}



if (response=="RInfo"){
  pdf (paste0(resultpath,daytime,"_",response,"_rfe_cv.pdf"),width=10,height=8)
  plotModelCV(rfeModel)
  plotModelCV(rfeModel,xlim=c(1,55),ylim=c(0.1,0.325))
  dev.off()
}


pdf (paste0(resultpath,daytime,"_",response,"_varImp.pdf"),width=7,height=10)
plot(varImp(rfeModel$fit),col="black")
dev.off()


