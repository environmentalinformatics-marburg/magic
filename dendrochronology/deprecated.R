#' Calculate ecologically relevant temperature parameters
#' @description Calculate ecologically relevant temperature parameters
#' @param tmin Numeric. Daily min temperatures
#' @param tmax Numeric. Daily max temperatures
#' @param tmean Numeric. Daily mean temperatures
#' @param base Numeric. Base temperature to which the parameters will be calculated
#' @return A Vector with calculated parametes with the same length as the input
#' @author Hanna Meyer
#' @seealso \code{\link{aggregateClimate}}
#' @note See \code{\link{aggregateClimate}} to aggregate the results to weeks, months, years 
#' @examples
#' GDD(tmax=c(5,6,10,17),tmin=c(4,5,6,13))
#' Gsum(tmean=c(5,11,10,17))
#' @export GDD Gsum Coldsum
#' @aliases GDD Gsum Coldsum

GDD <- function(tmax,tmin,base=10){
  result <- (tmax+tmin)/2-base
  result[result<0] <- 0
  return(result)
}
#' @describeIn foobar Difference between the mean and the median
Gsum <- function(tmean,base=5){
  result <- 0
  result[tmean>=base] <- tmean[tmean>=base]-base
  return(result)
}

Coldsum <- function(tmean,base=0){
  result <- 0
  result[tmean < base] <- abs(result[tmean < base]-base)
}