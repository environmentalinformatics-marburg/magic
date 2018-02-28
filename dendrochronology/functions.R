#dat= needs to have daily dates
#plotID =spatial identifier
#dat needs day and night temperatures
calculateEcoClimate <- function (dat, plotID="Plot",
                                 tday="tday",tnight="tnight",prec="prec"){
  aggregatedDf <- function(dat,variable,fun,aggregation){
    
    if(aggregation=="year"){
      df <- aggregate(dat[,variable], 
                      by=list(dat[,plotID],year(dat$Date)),
                      fun,na.rm=T)
      
      result<- lapply(unique(year(dat$Date)),function(year){
        aggregate(df$x[df$Group.2==year],
                  by=list(df$Group.1[df$Group.2==year]),
                  "mean",na.rm=T)$x})
      names(result) <- paste0(variable,"_",unique(year(dat$Date)))
      
    }
    
    
    if(aggregation=="month"){
      df <- aggregate(dat[,variable], 
                           by=list(dat[,plotID],year(dat$Date),month(dat$Date)),
                           fun,na.rm=T)
    
    result<- lapply(1:12,function(month){
      aggregate(df$x[df$Group.3==month],
                by=list(df$Group.1[df$Group.3==month],
                        df$Group.2[df$Group.3==month]),
                "mean",na.rm=T)$x})
    names(result) <- paste0(variable,"_",month(1:12,label=TRUE,locale="en_US.UTF-8"))
    
    }
    
    if(aggregation=="week"){ ####currently not working
      df <- aggregate(dat[,variable], 
                             by=list(dat[,plotID],year(dat$Date),month(dat$Date),
                                     week(dat$Date)),
                             fun,na.rm=T)
      
      result <- lapply(1:53,function(week){
        aggregate(df$x[df$Group.4==week],
                  by=list(df$Group.1[df$Group.4==week],
                          df$Group.2[df$Group.4==week],
                          df$Group.3[df$Group.4==week]),
                  "mean",na.rm=T)$x})
      names(result) <- paste0(variable,paste0("_week_",1:53))
    }
    
    
    result <- data.frame("Plot"= unique(df$Group.1), "Date"= unique(df$Group.2),
                         result)
    return(result)
  }
  #############################################################################
  #### Calculate GDD
  dat$GDD <- (dat[,tday]+dat[,tnight])/2-10
  dat$GDD[dat$GDD<0] <- 0
  Gdd_agg <- aggregatedDf(dat,variable="GDD",fun="sum",aggregation = "month")

  ######### Wärmesummen
  dat$Gsum <- 0
  dat$Gsum[dat$tmean>5] <- dat$tmean[dat$tmean>5]-5
  Gsum_agg <- aggregatedDf(dat,variable="Gsum",fun="sum",aggregation = "month")
  Gsum_year <- aggregate(dat$Gsum,by=list(dat[,plotID],year(dat$Date)),sum)
  names(Gsum_year)[names(Gsum_year)=="x"] <- "Gsum_year"
  ######### Means
  MonthlyTmean_agg <- aggregatedDf(dat,variable="tmean",fun="mean",aggregation = "month")
  
  ######### Prec
  
  MonthlyPrec_agg <- aggregatedDf(dat,variable="prec",fun="sum",aggregation = "month")

  ###########
  result_final <- data.frame(Gdd_agg,
                             Gsum_agg[,3:ncol(Gsum_agg)],
                             MonthlyTmean_agg[,3:ncol(MonthlyTmean_agg)],
                             MonthlyPrec_agg[,3:ncol(MonthlyPrec_agg)])
#  result_final <- merge(result_final,Gsum_year,by.x=c("Plot","Date"),
#                        by.y=c("Group.1","Group.2"))
}
  
  
