
out_path = "/home/dogbert/"
src_path = "/media/dogbert/dev/be/julendat/processing/plots/"

multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  require(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col)) 
    }
  }
}

################### inst variables ############################
level = 400
var_Name_t = 'Temperatur'
parameter_t = 'Ta_200'

var_Name_r = 'Luftfeuchte'
parameter_r = 'rH_200'

var_Name_w = 'Niederschlag'
parameter_w = 'P_RT_NRT'

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
  
  station <- substr(data$PlotId[1], 4,8)
  year <- substr(as.Date(data$Datetime[1]), 1,4)
  png(paste0(out_path, station, "_",year, "_", "vis.png"),
      width     = 2480,
      height    = 3508,
      units     = "px",
      res       = 300,
      # pointsize = 1
  )
  
  ##################### Ta_200 #####################################################################
  dat_t <- data.frame( Monat=c("Jan", "Feb", "Mrz", "Apr", "Mai" ,"Jun" , "Jul", "Aug", "Sep" ,"Okt", "Nov", "Dez"), 
                       data[, c(paste0(parameter_t, "_max"), parameter_t, paste0(parameter_t,"_min") )])
  dat_t$Monat <- factor(dat_t$Monat, levels = c("Jan", "Feb", "Mrz", "Apr", "Mai" ,"Jun" , "Jul", "Aug", "Sep" ,"Okt", "Nov", "Dez"))
  
  dat_t.mlt_t <- melt(dat_t)
  # dat_t.mlt_t$Monat <- factor(dat_t.mlt_t$Monat, levels = month.abb)
  dat_t.mlt_t$value <- round(dat_t.mlt_t$value, 1)
  t <- colnames(dat_t.mlt_t) <- c('Monat','Leg',var_Name_t)
  
  levels(dat_t.mlt_t$Leg) <- c("max", "mittel", "min")
  
  p1 <- (ggplot(aes(x = Monat, y = Temperatur, group = Leg, label = Temperatur, 
                    color = Leg), 
                data = dat_t.mlt_t) + 
           scale_size_area()+
           xlab(NULL)+
           ylab(paste(var_Name_t,"°C") )+
           geom_line() + 
           geom_point() + 
           geom_text(vjust = -0.5,hjust=-0.1, size=3, color="black") + 
           ggtitle(paste( station, " - ", year)) +
           theme(plot.title=element_text(family="Arial", face="bold", size=10))+
           theme(plot.margin = unit(c(8,8,8,8), "mm"))+
           theme(title = element_text(vjust=1))+
           theme(legend.title=element_blank() ) +
           theme(axis.text=element_text(colour="black"))
         #scale_colour_brewer(name = "")
  )
  #------------------------#
  
  ##################### rH_200 #####################################################################
  dat_r <- data.frame(Monat=c("Jan", "Feb", "Mrz", "Apr", "Mai" ,"Jun" , "Jul", "Aug", "Sep" ,"Okt", "Nov", "Dez"), 
                      data[, c(paste0(parameter_r, "_max"),parameter_r, paste0(parameter_r,"_min") )])
  dat_r$Monat <- factor(dat_r$Monat, levels = c("Jan", "Feb", "Mrz", "Apr", "Mai" ,"Jun" , "Jul", "Aug", "Sep" ,"Okt", "Nov", "Dez"))
  
  dat_r.mlt_r <- melt(dat_r)
  # dat_r.mlt_r$Month <- factor(dat_r.mlt_r$Monat, levels = month.abb)
  dat_r.mlt_r$value <- round(dat_r.mlt_r$value, 1)
  r<- colnames(dat_r.mlt_r)<-c('Monat','Leg',var_Name_r)
  
  levels(dat_r.mlt_r$Leg) <- c("max", "mittel", "min")
  
  p2 <- (ggplot(aes(x = Monat, y = Luftfeuchte, group = Leg, label = Luftfeuchte, 
                    color = Leg), 
                data = dat_r.mlt_r) + 
           scale_size_area()+
           xlab(NULL)+
           ylab(paste(var_Name_r, "%") )+
           geom_line() + 
           geom_point() + 
           geom_text(vjust = -0.5,hjust=-0.1, size=3, color="black") + 
           ggtitle(paste( station , " - ", year)) +
           theme(plot.title=element_text(family="Arial", face="bold", size=10)) +
           theme(plot.margin = unit(c(0,8,8,8), "mm"))+
           theme(title = element_text(vjust=1))+
           theme(legend.title=element_blank())+
           theme(axis.text=element_text(colour="black"))
         #+ #, legend.text=element_text(family="Garamond",size=8), legend.position="topright")
         # scale_colour_brewer(name = "")
  )
  #------------------------#
  
  ##################### P_RT_NRT #####################################################################
  dat_w <- data.frame( Monat=c("Jan", "Feb", "Mrz", "Apr", "Mai" ,"Jun" , "Jul", "Aug", "Sep" ,"Okt", "Nov", "Dez"), 
                       data[, c(parameter_w)])
  dat_w$Monat <- factor(dat_w$Monat, levels = c("Jan", "Feb", "Mrz", "Apr", "Mai" ,"Jun" , "Jul", "Aug", "Sep" ,"Okt", "Nov", "Dez"))
  
  dat_w.mlt_w <- melt(dat_w)
  # dat_w.mlt_t$Monat <- factor(dat_w.mlt_t$Monat, levels = month.abb)
  dat_w.mlt_w$value <- round(dat_w.mlt_w$value, 1)
  t <- colnames(dat_w.mlt_w) <- c('Monat','Leg',var_Name_w)
  
  # levels(dat_w.mlt_w$Leg) <- c("max", "mittel", "min")
  
  p3 <- ggplot(dat_w.mlt_w , aes( y=Niederschlag, x=Monat))
  p3 <- p3 + geom_bar(position="dodge", stat="identity",fill="#87e0fd") + scale_size_area()+
    xlab(NULL)+
    ylab(paste(var_Name_w, "mm") )+
    ggtitle(paste(station,  " - ", year)) + 
    theme(plot.title=element_text(family="Arial", face="bold", size=10))+
    theme(legend.position="none") +
    geom_text(aes(y=Niederschlag, label = Niederschlag),vjust = 2,size=3)+
    theme(plot.margin = unit(c(0,33,8,8), "mm"))+
    theme(title = element_text(vjust=1))  +
    scale_colour_gradient2("fill") +
    theme(axis.text=element_text(colour="black"))
  #scale_fill_identity(palette="Blues")#+coord_polar(theta="x")
  
  
  
  #------------------------#
  
  multiplot(p1, p2, p3, cols=1)
  dev.off()
  
}


