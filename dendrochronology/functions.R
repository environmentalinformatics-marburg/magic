#dat= needs to have daily dates
#plotID =spatial identifier
#dat needs day and night temperatures
calculateEcoClimate <- function (dat, plotID="Plot", aggregation="month",
                                 tday="tday",tnight="tnight",prec="prec"){
  aggregatedDf <- function(dat,variable,fun,aggregation){
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
    
    
    result <- data.frame("Plot"= df$Group.1, "Date"= df$Group.2,
                         result)
    return(result)
  }
  #############################################################################
  #### Calculate GDD
  dat$GDD <- (dat[,tday]+dat[,tnight])/2-10
  dat$GDD[dat$GDD<0] <- 0
  Gdd_agg <- aggregatedDf(dat,variable="GDD",fun="sum",aggregation = aggregation)
  ######### Wärmesummen
  dat$Gsum <- 0
  dat$Gsum[dat$tmean>5] <- dat$tmean[dat$tmean>5]-5
  Gsum_agg <- aggregatedDf(dat,variable="Gsum",fun="sum",aggregation = aggregation)
  ######### Means
  MonthlyTmean_agg <- aggregatedDf(dat,variable="tmean",fun="mean",aggregation = aggregation)
  ######### Prec
  
  MonthlyPrec_agg <- aggregatedDf(dat,variable="prec",fun="sum",aggregation = aggregation)

  ###########
  result_final <- data.frame(Gdd_agg,Gsum_agg[,3:ncol(Gsum_agg)],
                             MonthlyTmean_agg[,3:ncol(MonthlyTmean_agg)],
                             MonthlyPrec_agg[,3:ncol(MonthlyPrec_agg)])#...

}
  
  
