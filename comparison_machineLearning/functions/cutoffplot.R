#adapted from Max Kuhn on http://caret.r-forge.r-project.org/custom_models.html

cutoffplot=function (x){
  
  library(reshape2)
  if(nrow(x$modelInfo$parameters)==2) {
    metrics <- x$results[eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[1,1]")),sep="")))==
                           eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[1,1]")),sep="")))[
                             x$results$Dist==min(x$results$Dist)], c(2, 4:6)]
    
    title=paste(x$modelInfo$label," \n ",x$modelInfo$parameters[1,1],": ", 
                round(eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[1,1]")))))[
                  x$results$Dist==min(x$results$Dist)],3))
  }
  if(nrow(x$modelInfo$parameters)==3){
    metrics= x$results[eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[1,1]")),sep="")))==
                         eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[1,1]")),sep="")))[
                           x$results$Dist==min(x$results$Dist)]&
                         eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[2,1]")),sep="")))==
                         eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[2,1]")),sep="")))[
                           x$results$Dist==min(x$results$Dist)], c(3, 5:7)]
    
    title=paste(x$modelInfo$label," \n ",x$modelInfo$parameters[1,1],": ", 
                round(eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[1,1]")))))[
                  x$results$Dist==min(x$results$Dist)],3),",", x$modelInfo$parameters[2,1],": ",
                round(eval(parse(text=paste("x$results$",eval(parse(text="x$modelInfo$parameters[2,1]")))))[
                    x$results$Dist==min(x$results$Dist)],3)
                )
  }
  
  metrics <- melt(metrics, id.vars = "threshold",
                  variable.name = "Resampled",
                  value.name = "Data")
  
 
  
  ggplot(metrics, aes(x = threshold, y = Data, color = Resampled)) +
    geom_line() +
    ylab("") + xlab("Probability Cutoff") + ggtitle(title) +
    theme(legend.position = "top") 
}