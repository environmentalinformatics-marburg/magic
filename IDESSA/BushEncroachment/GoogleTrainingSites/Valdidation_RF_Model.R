################### Control Random Forest
library("Rsenal")
library("pROC")
load("test.RData")
load("results.RData")


pred_test <- c(predict(results, test))
obs_test <- c(test$class)

confusionMatrix(pred_test,obs_test)

#ROC-Curve
plot.roc(obs_test,pred_test)

classificationStats(pred_test, obs_test)
