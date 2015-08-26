################### Control Random Forest
setwd(out)

load("test.RData")
load("results.RData")

pred_test <- c(predict(results, test))
obs_test <- c(test$class)

cm<-confusionMatrix(pred_test,obs_test)$table

#ROC-Curve
AUC=roc(obs_test,pred_test)$auc[1]

Validation<-classificationStats(pred_test, obs_test)
Validation$AUC<-AUC


write.table(cm,"ConfusionMatrix.txt")
write.table(Validation,"Validation.txt",row.names=F)


varimp <- varImp(results)
row.names(varimp$importance)<-c("Red","Green","Blue","VVI","Hue", "Saturation", "Value",
                                "Red 3x3 mean","Green 3x3 mean","Blue 3x3 mean", "VVI 3x3 mean",
                                "Hue 3x3 mean", "Saturation 3x3 mean", "Value 3x3 mean",
                                "Red 3x3 sd","Green 3x3 sd","Blue 3x3 sd", "VVI 3x3 sd",
                                "Hue 3x3 sd", "Saturation 3x3 sd", "Value 3x3 sd", "Biome")

pdf("varImp.pdf",width=6,height=4.5)
plot(varimp,15,col="black")
dev.off()


load("All_classified.df.RData")

pdf("Reliability.pdf",width=8,height=3.5)
par(mar=c(0,3,0,3))
boxplot(All_classified.df$reliability*100,horizontal=TRUE,col="grey90", notch=TRUE,pch=8,cex=0.5,bty="n",
        xaxt="n",yaxt="n",frame.plot=FALSE)
axis(1, at=c(0,10,20,30,40,50,60,70,80,90,100),labels=c("0","10","20","30","40","50","60","70","80","90","100"), 
     col.axis="black", las=1,pos=0.75)
text(50, 0.56, "Percent", xpd = TRUE)
dev.off()


