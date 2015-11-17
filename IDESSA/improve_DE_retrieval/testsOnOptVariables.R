subset<-rfeModel$variables[rfeModel$variables$Variables==rfeModel$optsize,]

test=aggregate(subset$Overall,by=list(subset$var),sum)
varimps <- test[order(test$x,decreasing=T),]
