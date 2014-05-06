balancing=function(training,response,seed){
  class <- eval(parse(text=paste("training$",response,sep="")))
  minPixel<-min(sum(class==unique(class)[1]),sum(class==unique(class)[2]))
  maxPixel<-max(sum(class==unique(class)[1]),sum(class==unique(class)[2]))
  minclass<-ifelse(min(sum(class==unique(class)[1]))==minPixel,as.character(unique(class)[1]),as.character(unique(class)[2]))
  maxclass<-ifelse(max(sum(class==unique(class)[1]))==maxPixel,as.character(unique(class)[1]),as.character(unique(class)[2]))
  prob<-ifelse(class==minclass,0,1)
  if(seed) set.seed(20)
  subset<-c(sample(1:length(class),minPixel,prob=prob),which(class==minclass))
  training<-training[subset,]
  return (training)
}