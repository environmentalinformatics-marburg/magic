confusionMetrics=function(predicted,observed){
  tab=table(predicted,observed)
  tab=tab/100 #for that integer values become not too large for calculations
  h=TP=tab[1,1]
  f=FP=tab[1,2]
  z=TN=tab[2,2]
  m=FN=tab[2,1]
  
  bias=(TP+FP)/(TP+FN)
  POD=TP/(TP+FN)
  PFD=FP/(FP+TN)
  FAR=FP/(TP+FP)
  CSI=TP/(TP+FP+FN)
  ph=((TP+FN)*(TP+FP))/(sum(tab))
  ETS=(TP-ph)/((TP+FP+FN)-ph)
  HSS=(TP*TN-FP*FN)/(((TP+FN)*(FN+TN)+(TP+FP)*(FP+TN))/2)
  HKD=(TP/(TP+FN))-(FP/(FP+TN))
  x=c(bias,POD,PFD,FAR,CSI,ETS,HSS,HKD)
  names(x)=c("Bias","POD","PFD","FAR","CSI","ETS","HSS","HKD")
  return(as.data.frame(as.list(x)))
}