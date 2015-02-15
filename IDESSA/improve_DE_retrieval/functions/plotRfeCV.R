#function takes an rfe model and plots the mean metric with standard deviations


plotRfeCV <- function (rfeModel,metric="RMSE",...){
  data <- as.data.frame(rfeModel$resample)
  sdv=c()
  means=c()
  for (i in unique(data$Variables)){
    sdv=c(sdv,sd(eval(parse(text=paste("data$",metric)))[data$Variables==i]))
    means=c(means,mean(eval(parse(text=paste("data$",metric)))[data$Variables==i]))
  }
  #  input_list <- list(...)
  xyplot(means~unique(data$Variables),
         ylim=c(min(means-sdv),max(means+sdv)),
         xlim=c(min(data$Variables),max(data$Variables)),
         xlab="Number of Variables",
         ylab=paste0(metric," (Cross-Validation)"),
         panel = function(x, y, ...){
           panel.polygon(c(unique(data$Variables),rev(unique(data$Variables))),
                         c(means+sdv, rev(means-sdv)), col="grey80", border=FALSE)
           panel.xyplot(x,y,type=c("b","g"),col="black",pch=16)
         }
  )
}

