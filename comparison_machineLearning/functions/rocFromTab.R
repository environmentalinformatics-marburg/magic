rocFromTab=function(prob,obs, plot=TRUE,th=100) {
  ##sort
  sort_prob=sort(prob,decreasing=TRUE,index.return=TRUE)
  sort_obs=obs[sort_prob$ix]
  sort_prob=sort_prob$x
  th=th-1
  result=matrix(nrow=length(c(0,seq(round(length(obs)/th,0),length(obs),by=round(length(obs)/th,0)),length(obs))),ncol=3)
  
  for (i in c(0,seq(round(length(obs)/th,0),length(obs),by=round(length(obs)/th,0)),length(obs))){
    sort_prob[]=0
    sort_prob[1:i]=1 #classify the probability map according to current threshold
    A=sum(sort_prob==1&sort_obs==1) #calculate contingency table
    B=sum(sort_prob==1&sort_obs==0)
    C=sum(sort_prob==0&sort_obs==1)
    D=sum(sort_prob==0&sort_obs==0)
    #calculate false positive and versus true positive rate
    result[which(c(0,seq(round(length(obs)/th,0),length(obs),by=round(length(obs)/th,0)),length(obs))==i),1]=i/length(obs)
    result[which(c(0,seq(round(length(obs)/th,0),length(obs),by=round(length(obs)/th,0)),length(obs))==i),3]= A/(A+C)
    result[which(c(0,seq(round(length(obs)/th,0),length(obs),by=round(length(obs)/th,0)),length(obs))==i),2]=B/(B+D)
  }
  
  AUC=integrate(splinefun(result[,2],result[,3],method="natural"),0,1)$value
  if (plot==TRUE){
    plot(result[,2],result[,3],type="l",xlab="False positive rate",ylab="True positive rate",xlim=c(0,1),ylim=c(0,1))
    lines(c(0,1),c(0,1),col="grey50")
    legend("topleft",legend=paste("AUC = ",round(AUC,3)),bty="n")
  }
  colnames(result)=c("threshold","falsePositives","truePositives")
  result2=list()
  result2[[1]]=AUC
  result2[[2]]=result
  return (result2)
}

  