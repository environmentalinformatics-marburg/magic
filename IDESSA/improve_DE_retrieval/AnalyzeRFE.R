### Analyze rfe ################################################################

library(Rainfall)
library(Rsenal)


datapath <- "/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/RFEModels/"
resultpath <- "/home/hanna/Documents/Presentations/Paper/Meyer2015_textureParameters/latex/figures/"

setwd(datapath)
files<-list.files(,pattern="rfeModel")

#modelIn<- paste0(datapath,"rfeModel_",daytime,"_",response,".Rdata")

rfeModels <- list(get(load(files[1])),get(load(files[2])),
                  get(load(files[3])),get(load(files[4])))

names(rfeModels)<-files

### Select variables ###########################################################

#vars <- varsRfeCV(rfeModel)
#vars <- rfeModel$optVariables
#write.table(vars,paste0(resultpath,daytime,"_",response,"_selectedVars.csv"),
#            row.names=FALSE)

#varsRfeCV(rfeModel)
#write.table(varsRfeCV(rfeModel),paste0(resultpath,daytime,"_",response,"_Vars_oneSE.csv"),
#            row.names=FALSE)



library(latticeExtra)
library(gridExtra)
pdf (paste0(resultpath,"decreaseInPerformance.pdf"),width=10,height=5)
p1<-plotModelCV(rfeModels[[1]],metric="Rsquared",sderror = FALSE)
p1b<-plotModelCV(rfeModels[[1]],metric="Rsquared",sderror = FALSE,grid=FALSE)
p2<-plotModelCV(rfeModels[[3]],metric="Rsquared",sderror = FALSE,grid=FALSE)
pf1<-p1+as.layer(p2)+as.layer(p1b)

p3<-plotModelCV(rfeModels[[2]],metric="ROC",sderror = FALSE,
                ylim=c(0.65,0.92))
p3b<-plotModelCV(rfeModels[[2]],metric="ROC",sderror = FALSE,
                ylim=c(0.65,0.92),grid=FALSE)
p4<-plotModelCV(rfeModels[[4]],metric="ROC",sderror = FALSE,grid=FALSE)
pf2 <- p3+as.layer(p4)+as.layer(p3b)

merge  <-  arrangeGrob(pf1,pf2, ncol=2) 
print(merge)
dev.off()




datapath <- "/media/hanna/data/copyFrom183/Improve_DE_retrieval/results/trainedModels/"

setwd(datapath)
filesText<-c(list.files(,pattern="Model_day"),list.files(,pattern="Model_night"))
filesSpec<-list.files(,pattern="OnlySpec")

#modelIn<- paste0(datapath,"rfeModel_",daytime,"_",response,".Rdata")

trainText <- list(get(load(filesText[1])),get(load(filesText[2])),
                  get(load(filesText[3])),get(load(filesText[4])))
names(trainText)<-filesText
trainSpec <- list(get(load(filesSpec[1])),get(load(filesSpec[2])),
                  get(load(filesSpec[3])),get(load(filesSpec[4])))
names(trainSpec)<-filesSpec


pdf (paste0(resultpath,"varImp.pdf"),width=10,height=6)
p1<-plot(varImp(trainText[[1]]),col="black",10)
p2<-plot(varImp(trainText[[2]]),col="black",10)
p3<-plot(varImp(trainText[[3]]),col="black",10)
p4<-plot(varImp(trainText[[4]]),col="black",10)
merge<-c(p3,p4,p1,p2,layout=c(2,2))
print(merge)
dev.off()

pdf (paste0(resultpath,"varImp_spec.pdf"),width=8,height=6)
p1<-plot(varImp(trainSpec[[1]]),col="black",10)
p2<-plot(varImp(trainSpec[[2]]),col="black",10)
p3<-plot(varImp(trainSpec[[3]]),col="black",10)
p4<-plot(varImp(trainSpec[[4]]),col="black",10)
merge<-c(p3,p4,p1,p2,layout=c(2,2))
print(merge)
dev.off()

