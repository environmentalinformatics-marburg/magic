src_path = "/media/dogbert/dev/be/vis_2/"
out_path = "/media/dogbert/dev/be/vis_2/"
  
setwd(path)

################### inst variables ############################
level = 400
var_Name = 'Luftfeuchte'
parameter = 'rH_200'
y_coord = rH_200

###############################################################  
  
files <- list.files( path=src_path, pattern=glob2rx(paste0("*_0", level,"*.dat")),recursive=TRUE, full.names=TRUE)
libs <- c('ggplot2', 'latticeExtra', 'gridExtra', 'MASS', 
          'colorspace', 'plyr', 'Hmisc', 'scales')
lapply(libs, require, character.only = T)

dat.list <- lapply(seq(files), function(i) {
 read.table(files[i], header = T, sep = ",", stringsAsFactors = F)
})
library(ggplot2)
library(reshape)
for (data in dat.list){

  dat <- data.frame(Month = month.abb, 
                    data[, c(parameter, paste0(parameter,"_min"), paste0(parameter, "_max"))])
  
  dat.mlt <- melt(dat)
  dat.mlt$Month <- factor(dat.mlt$Month, levels = month.abb)
  colnames(dat.mlt)<-c('Month','variable',var_Name)
  station <- substr(data$PlotId[1], 4,8)
  year <- substr(as.Date(data$Datetime[1]), 1,4)
  png(paste0(out_path, station, "_",year, "_", parameter,".png"))
  print (ggplot(aes(x = Month, y = Luftfeuchte, group = variable, label = Luftfeuchte, 
        color = variable), 
        data = dat.mlt) + 
        geom_line() + 
        geom_point() + 
        geom_text(vjust = -1,size=3) + 
        ggtitle(paste("Overview", station ,var_Name, year)))
  dev.off()
  
}