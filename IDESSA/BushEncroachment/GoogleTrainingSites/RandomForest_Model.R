# Training- and Testiningdata
setwd(out)
load("valuetable.df.RData")


set.seed(3456)
trainIndex <- createDataPartition(valuetable.df$class, p = .25,
                                  list = FALSE, times = 1)

#trainIndex <- createDataPartition(valuetable.df$class, p = .05,
#                                  list = FALSE, times = 1)

train <- valuetable.df[ trainIndex,]
test <- valuetable.df[-trainIndex,]

save(train, file = "train.RData")
save(test, file = "test.RData")

remove(valuetable.df,trainIndex,test)
gc()

########### RandomForest Model ###########
set.seed(7)

if(allowParallel){
  require(doParallel)
  cl <- makeCluster(detectCores())
  registerDoParallel(cl)
}
#Change for using ROC
trainFuncs <- caretFuncs
trainFuncs$summary <- twoClassSummary

#traincontrol
trControl = trainControl(method = "cv", classProbs = TRUE, number = 10,
                         summaryFunction = twoClassSummary)

results<-train(class ~ .,
               data = train,
               method="rf",
               trControl=trControl, 
               metric="ROC", 
               tuneLength=10)
save(results,file="results.RData")
