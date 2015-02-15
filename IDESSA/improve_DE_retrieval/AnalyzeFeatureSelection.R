###Analyze and visualize results of feature selection

################################################################################
library(caret)
library(gridExtra)
source("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/code/functions/plotRfeCV.R")
resultpath="/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/"

##load model
load(paste0(resultpath,"/rfe_day_Rain.RData"))

################################################################################
pdf(paste0(resultpath,"/Rain_rfe_VarImp.pdf"))
plot(varImp(rfeModel$fit,scale=TRUE),20,pch=16)
dev.off()

predictors(rfeModel)

pdf(paste0(resultpath,"/Rain_rfe_VarImp_all.pdf"))
plot(varImp(rfeModel$fit,scale=TRUE),length(predictors(rfeModel)),pch=16)
dev.off()

pdf(paste0(resultpath,"/Rain_rfe_var_Decrease_cv.pdf"),width=10,height=5)
tmp=grid.arrange(plotRfeCV(rfeModel,metric="RMSE"),plotRfeCV(rfeModel,metric="Rsquared"), ncol=2)
dev.off()

#library(Hmisc)
#xYplot(Cbind(means,means-sdv,means+sdv)~unique(data$Variable),type="l")

