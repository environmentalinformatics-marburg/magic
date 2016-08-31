####################################################
#      Classification
####################################################

library(randomForest)
library(caret)
mainpath <- "/media/memory01/data/IDESSA/AI/"
datapath <- paste0(mainpath,"Training_Data/")
outpath <- paste0(mainpath,"RF_Modelle/")
# Preparation

load(paste0(datapath,"Dataframe_small.RData"))

Dataframe <- na.omit(Dataframe)

set.seed(3456)
trainIndex <- createDataPartition(Dataframe$class, p = 0.04,
                                  list = FALSE, times = 1 )

train <- Dataframe[ trainIndex,]
test <- Dataframe[-trainIndex,]


tctrl <- trainControl(method="cv")

rfeModel <- train(train[,1:8],
                train$class,
                method = "rf",
                trControl=tctrl,
                tuneLength=7)

#setwd(Results)
save(rfeModel,file=paste0(outpath,"rfeModel.RData"))