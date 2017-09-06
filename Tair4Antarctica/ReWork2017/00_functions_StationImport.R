

TairFromUWISC <- function(path){
  require(lubridate)
  headernames <- c("Year","Yday","Month","Day","Time","Temperature",
                   "Pressure","WindSpeed","WindDirection","RelativeHumidity",
                   "DeltaT")
  dat <- read.csv(path,skip=2,header=FALSE,sep="",
                  na.strings ="", stringsAsFactors= F)
  names(dat) <- headernames
  dat <- dat[,c("Year","Yday","Time","Temperature")]
  dat$Temperature[dat$Temperature==444] <- NA
  
  x <- as.Date(dat$Yday, origin=as.Date(paste0(dat$Year,"-01-01")))
  dates <- ymd(x) + hm(paste0(substr(sprintf("%04d", dat$Time),1,2),":",
                              substr(sprintf("%04d", dat$Time),3,4)))
  # dat$Time <- dat$Time/100
  info <- read.csv(path,nrows=2,header=FALSE,sep="",
                   na.strings ="", stringsAsFactors= F)
  if (ncol(info)==10){
    nme <- info[1,10]
  } else{
    nme <- paste0(info[1,10],info[1,11])
  }
  info <- c(nme,info[2,2],info[2,4])
  dat <- data.frame("Name"=info[1],
                    "Lat"=-as.numeric(gsub("([0-9]+).*$", "\\1", info[2])),
                    "Lon"=as.numeric(gsub("([0-9]+).*$", "\\1", info[3])),
                    "Date"=dates,
                    "Provider"="UWISC",
                    "Temperature"=dat$Temperature)
  if (grepl("W  Elev",readLines(path,2)[2])){
    dat$Lon <- -dat$Lon
  }
  return(dat)
}

TairFromUSDA <- function(path){
  require(rio)
  require(lubridate)
  if (grepl("xls",path)){
    if (grepl("xlsx",path)){
      created <- mapply(convert, path, gsub("xlsx", "csv", path))
      path <- paste0(substr(path,1,nchar(path)-4),"csv")
      if (grepl("Mt.Fleming",path)){
        nameStation <- "MtFleming"
      }else{
        nameStation <- gsub('.{2}$', '',  gsub(".*[/]([^.]+)[.].*", "\\1", sub("_","",sub("w.",".",path))))
      }
    }else{
      created <- mapply(convert, path, gsub("xls", "csv", path))
      path <- paste0(substr(path,1,nchar(path)-3),"csv")
      if (grepl("Mt.Fleming",path)){
        nameStation <- "MtFleming"
      }else{
        
        nameStation <- gsub('.{2}$', '',  gsub(".*[/]([^.]+)[.].*", "\\1", sub("_","",sub("w.",".",path))))
      }}}
  
  dat <- read.table(path,skip=3,sep=",",comment.char = "")
  info <- read.csv(path,nrows=3,header=FALSE,sep=",",
                   na.strings ="", stringsAsFactors= F)
  dat <- data.frame(dat[,grep("YEAR",info[1,])],
                    dat[,grep("DAY",info[1,])],
                    dat[,grep("HOUR",info[1,])]/100,
                    dat[,grep("Air",info[1,])[1]])
  names(dat) <- c("Year","Yday","Time","Temperature")
  
  x <- as.Date(dat$Yday, origin=as.Date(paste0(dat$Year,"-01-01")))
  dates <- ymd(x) + hm(paste0(dat$Time,":00"))
  
  loc <- data.frame("name"=c("BullPass","GraniteHarbour","MarblePoint",
                             "MinnaBluff","MtFleming","ScottBase","VictoriaValley"),
                    "Lat"=c(-77.518,-77.006,-77.419,-78.512,-77.545,-77.848,-77.33094),
                    "Lon"=c(161.865,162.525,163.682,166.766,160.29,166.761,161.6007))
  
  dat <- data.frame("Name"= nameStation,
                    "Lat"=loc$Lat[loc$name==nameStation],
                    "Lon"=loc$Lon[loc$name==nameStation],
                    "Date"=dates,
                    "Provider"="USDA",
                    "Temperature"= dat$Temperature)
}

TairFromLTER <- function(path,agg2hour = TRUE){
  require(lubridate)
  header <- read.csv(path,skip=26,nrow=1,header=FALSE,sep=",",
                     stringsAsFactors= F)
  loc <- data.frame("name"=c("beacon","bonney","brownworth","Canada",
                             "commonwealth","explorerscave","LakeFryxell",
                             "LakeHoare","HowardGlacier","MiersValley","TaylorGlacier",
                             "LakeVanda","LakeVida"),
                    "Lat"=c(-77.828,-77.714443,-77.433468,-77.6118,-77.557,
                            -77.584,-77.611,-77.624,-77.667,-78.10115,-77.736,
                            -77.523,-77.377),
                    "Lon"=c(160.657,162.46415,162.703627,162.969,163.4,
                            163.453,163.182,162.902,163.085,163.78778,
                            162.141,161.011,161.788))
  dat <- read.csv(path,skip=27,header=FALSE,sep=",",
                  stringsAsFactors= F)
  names(dat) <- header
  dates <- ymd(as.Date(dat$DATE_TIME,format="%m/%d/%Y")) + hm(substr(dat$DATE_TIME,12,16))
  Temperature <- dat$AIRT3M
  nameStation <- gsub('.{5}$', '',  gsub(".*[/]([^.]+)[.].*", "\\1", path))
  dat <- data.frame("Date"=dates,"Temperature"=Temperature)
  if(agg2hour){
    dat_agg <- aggregate(dat$Temperature, 
                     list(hour=cut(as.POSIXct(dat$Date), "hour")),
                     mean)
    dat <- data.frame("Date"=dat_agg$hour,"Temperature"=dat_agg$x)
  }
  
  dat <- data.frame("Name"= nameStation,
                    "Lat"=loc$Lat[loc$name==nameStation],
                    "Lon"=loc$Lon[loc$name==nameStation],
                    "Date"=dat$Date,
                    "Provider"="LTER",
                    "Temperature"=dat$Temperature)
}

TairFromItaly <- function(path){
  require(lubridate)
  dat <- read.table(path,header=TRUE)
  #  Year <- as.numeric(substr(dat$DateTime,1,4))
  #  Yday <- yday(as.Date(dat$DateTime))
  # Time <- as.numeric(sub(":","",dat$UTC))/100
  dates <- ymd(as.Date(dat$DateTime)) + hm(dat$UTC)
  Temperature <- as.numeric(as.character(dat$Temp))
  Temperature[Temperature>90] <- NA
  loc <- data.frame("name"=c("Zoraida","Modesta","Paola","Sofiab","Silvia",
                             "Rita","Maria","Lola","Irene","Giulia",
                             "Eneide","Concordia","Arelis","Alessandra"),
                    "Lat"=c(-74,-73.63917,-72.76694,-75.61167,-73.51833,
                            -74.725,-74.62639,-74.135,-71.6525,-75.53611,
                            -74.7,-75.1,-76.715,-73.58583),
                    "Lon"=c(162.89,160.6456,159.0389,158.5906,169.0153,
                            164.0331,164.0111,163.4306,148.6556,145.8589,
                            164.1167,123.3333,162.97,166.6211))
  nameStation <- gsub('.{18}$', '',  gsub(".*[/]([^.]+)[_].*", "\\1", path))
  dat <- data.frame("Name"= nameStation,
                    "Lat"=loc$Lat[loc$name==nameStation],
                    "Lon"=loc$Lon[loc$name==nameStation],
                    "Date"=dates,
                    "Provider"="Italy",
                    "Temperature"=Temperature)
}
