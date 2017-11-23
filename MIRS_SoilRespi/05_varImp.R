library(caret)
library(Rsenal)
load("/media/hanna/data/Nele_MIRS/version2/modeldata/finalModel.RData")

row.names(model$finalModel$importance)<- sub("X", "WL", row.names(model$finalModel$importance))
pdf("/media/hanna/data/Nele_MIRS/version2/figures/varimp.pdf",width=6,height=5)
plot(varImp(model,scale = TRUE),col="black")
dev.off()

pdf("/media/hanna/data/Nele_MIRS/version2/figures/perf.pdf",width=5,height=5.5)
boxplot(model$resample$Rsquared[model$resample$mtry==model$finalModel$tuneValue[[1]]],
        ylab="R^2 (cross-validated)")
dev.off()
