
#' Temporal Aggregation. Written for Climate Station data 
#' 
#' @description
#' This function will do a temporal aggregation of a climatic parameter
#' based on a date and hour field. Currently only 1 hour aggregation is supported.
#' 
#' @param x Vector of the parameter which is to aggregate 
#' format "YYYY-mm-dd HH:MM:SS"
#' @param time date frame of date and hours of measured x. First column date must be in format
#' "YYYY/mm/dd. Second column "time must be in format HH:MM"
#' @param fun Aggregation function. E.g "sum" for rainfall events or "mean" for temperature
#' 
#' @return
#' a data frame including the date information and the aggregated values
#' 
#' @examples
#' x=c(0.5,0,0,0.08,1.2,2)
#' time<-data.frame(rep("2000-01-01",6),c("01:20","01:40","03:20","03:25","03:30","04:10"))
#' agg=tempAgg(x,time)
#' 
#' @notes 
#' Requires doParallel



tempAgg <- function (x, time, fun="sum"){
  library(doParallel)
  registerDoParallel(detectCores())
  hours=c(paste0("0",0:9),10:23)
  unique_date=unique(time[,1])
  x_agg=foreach(i=1:length(unique_date),.combine=rbind)%dopar%{
    tmp=c()
    for (k in hours){
      if (any (substr(time[,2],1,2)==k)){
        tmp=rbind(tmp,data.frame(unique_date[i],k,eval(parse(text=paste0(fun,"(x[time[,1]==unique_date[i]&substr(time[,2],1,2)==k],na.rm=TRUE)")))))
      }
    }
    tmp
  }
  names(x_agg) = c("date", "time", "x")
  x_agg
  
}


