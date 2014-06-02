


############################################################################################################
####################################### READ DATA #######################################
############################################################################################################
data <- read.table(paste(datapath,"/",inputTable,sep=""),
                   header=T,
                   row.names=NULL,
                   na.strings="-99.000000")
tmpDateField=dateField
dateField<-eval(parse(text=paste("data$",dateField,sep="")))

############################################################################################################
################################## Scale and center predictor Variables ####################################
############################################################################################################


if (centerscale){
  data[,which(names(data) %in% predictorVariables)]=
    scale(data[,which(names(data) %in% predictorVariables)])
}

data=data[(rowSums(is.na(data[,which(names(data) %in% predictorVariables)])))==0,]#rm rows with na in predictors
############################################################################################################
################################## SPLIT DATA #######################################
############################################################################################################
#create partition by choosing randomly SizeOfTrainingSet% of the scenes. 
#These are used for training, the rest is used for testing
splittedData<-splitData(data,dateField,SizeOfTrainingSet,seed=useSeeds)
testing=splittedData$testing
if (response=="RInfo"){
  testing$RInfo=factor(testing$RInfo,levels=c("rain","norain"))
}
save(testing,file=paste(resultpath,"/testing.RData",sep=""))
rm(testing,data)
training=splittedData$training
rm(splittedData)
gc()
############################################################################################################
############################### BALANCE DATA #########################################
############################################################################################################
#number of the pixels with higher frequency is reduced to the number of pixels
#in class with lower frequency

if (balance) {
  training<-balancing(training,response,seed=useSeeds,factor)
}
############################################################################################################
############################## Cut to sampsize ##############################
############################################################################################################
#training data are reduced to the defined sampsize with respect to the distribution of the response
if (nrow(training)<sampsize) sampsize=nrow(training) #reduce sampsize if less pixels are available
if(useSeeds) set.seed(20)
samples<-createDataPartition(eval(parse(text=paste("training$",response,sep=""))),
                             p = (1/nrow(training))*sampsize,list=FALSE)
training <- training[samples,] #samples used for training
rm(samples)
############################################################################################################
############################## Define predictors and class ##############################
############################################################################################################
class <- eval(parse(text=paste("training$",response,sep="")))
if (response=="RInfo"){
  class=factor(class,levels=c("rain","norain"))
}
predictors <-training[,names(training) %in%  predictorVariables]
row.names(predictors)=NULL
rm(training)
gc()
############################################################################################################
###################CREATE INDEX FOR RESAMPLING #########################################
############################################################################################################
#a list with elements for each resampling iteration. 
#Each list element is the sample rows used for training at that iteration.
#The index will defined here instead of automatical random choice during the training
#to make sure that the samples are stratified. Each fold has the same distribution of 
#the predictor variable like the distribution of the predictor variable in the 
#overall training data set.
if(useSeeds) set.seed(20)
cvSplits <- createFolds(class, k = 10)
dateField=tmpDateField