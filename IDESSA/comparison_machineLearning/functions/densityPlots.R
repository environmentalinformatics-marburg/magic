plotDensity=function(modeldata=list(),dateField="chDate",names=model){
  colorlist=c("red","blue","green","orange","brown","grey")
  for (scene in 1:length(unique(eval(parse(text=paste("modeldata[[1]]$",dateField,sep="")))))){
    plot(density(modeldata[[1]]$observed[modeldata[[1]]$chDate==unique(modeldata[[1]]$chDate)[scene]]),
         xlim=c(0,quantile(modeldata[[1]]$observed[modeldata[[1]]$chDate==unique(modeldata[[1]]$chDate)[scene]],
                           probs=c(0,1,0.99))[3]),ylim=c(0,1.8),main=
           paste0(substr(unique(modeldata[[1]]$chDate)[scene],0,4),"-",substr(unique(modeldata[[1]]$chDate)[scene],5,6),"-",
                 substr(unique(modeldata[[1]]$chDate)[scene],7,8)," ",substr(unique(modeldata[[1]]$chDate)[scene],9,10),":",
                 substr(unique(modeldata[[1]]$chDate)[scene],11,12)))
      for (i in 1: length(modeldata)){
        lines(density(modeldata[[i]]$prediction[modeldata[[1]]$chDate==unique(modeldata[[1]]$chDate)[scene]]),col=colorlist[i])
      }
      legend("topright",legend=names,col=colorlist[1:length(modeldata)],lwd=1,bty="n")
  }
  plot(density(modeldata[[1]]$observed),
       xlim=c(0,quantile(modeldata[[1]]$observed,probs=c(0,1,0.99))[3]),ylim=c(0,1),main="mean")
  for (i in 1: length(modeldata)){
    lines(density(modeldata[[i]]$prediction),col=colorlist[i])
  }
  legend("topright",legend=names,col=colorlist[1:length(modeldata)],lwd=1,bty="n")
}