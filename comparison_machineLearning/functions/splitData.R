splitData<-function(data,dateField,SizeOfTrainingSet){
  #create partition by choosing randomly SizeOfTrainingSet% of the scenes. 
  #These are used for training, the rest is used for testing
  inTrain<-which(is.element(dateField, #determine the ids of the samples to be used for training
                            sample(unique(dateField),length(unique(dateField))*SizeOfTrainingSet)))
  splittedData=list()
  splittedData[[1]]<-data[inTrain,] #samples used for training
  splittedData[[2]]<-data[-inTrain,] #samples used for testing
  names(splittedData)=c("training","testing")
  return(splittedData)
}