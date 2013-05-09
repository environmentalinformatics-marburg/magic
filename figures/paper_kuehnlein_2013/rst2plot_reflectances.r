# R packages
# install.packages("sm") # if sm isn't installed yet
# install.packages("IDPmisc")
library(IDPmisc)
library(sm)
library(latticeExtra)
library(rattle)


# read data
filename <- file.choose()
dat <- read.table(filename, header=T, na.strings="-99.000000")
#dat <- subset(dat,dat$aefSlalom < 30 & dat$aefMYD06 < 30)
#dat <- subset(dat,dat$aefSlalom > 10 & dat$aefMYD06 > 10)
attach(dat)

MYD=aefMYD06
## band002
MSGJan=aefSlalom*1.06
MSGNor=-0.029+1.158*MSGJan
## or
MSGNor=-0.029+1.227*aefSlalom


## band003
MSGJan=aefSlalom*0.96
MSGNor=-0.022+1.083*aefSlalom


### reflectances ###
png(filename="200806111415_band03_vs_band03_histogram_two.png",width=1700,height=1600,units='px',res=300,pointsize=10)

plot(density(MSGJan,bw=0.01),
      lwd=1.2, 
      col="black", 
      xlim=c(0,1), 
      ylim=c(0,6),
      xlab=" Reflectance ", 
      ylab=" Density ",
      cex.lab=1.5,
      main="",
      yaxt="n",
      xaxt="n")
axis(2,las=2,cex.axis=1.0)
axis(1,cex.axis=1.0)
lines(density(MYD,bw=0.01), lty=5, lwd=1.2)
#lines(density(MSGNor,bw=0.01), lty=3, lwd=1.2, col="black")


legend("topright", 
       inset=.05, 
       #c("0.810 µm - SEVIRI ","0.856 µm - MODIS"),
       c("1.640 µm - SEVIRI","1.630 µm - MODIS"),
       #fill=c("blue", "red", "black"), 
       lty = c(1, 5),
       horiz=FALSE,
       cex=1.1)
grid(col="gray50",lty=2)
#mtext(" b)", side=2,line=3, las = 1, cex=1.5, at=c(7),adj=1)

dev.off()


###
png(filename="200806111415_band03_vs_band06_scatter_two.png",width=1600,height=1600,units='px',res=300,pointsize=10)

xyplot(MYD ~ MSGJan, 
          xlab=list("SEVIRI 1.640 µm",cex=1.2), 
          ylab=list("MODIS 1.630 µm",cex=1.2),
          xlim=c(0,1),
          ylim=c(0,1),
          panel = function() {
            panel.grid(h = -1, v = -1, col="gray50",lty=2)
            panel.xyplot(MSGJan,MYD,pch=20,cex = 0.3,col="grey1")
            panel.ablineq(lm(MYD ~ MSGJan), r.sq = TRUE, 
                      rot = TRUE, 
                      at = 0.8, 
                      pos = 1, cex=0.8)
                   } ) 


# band02
#aefSlalomNew=-0.01+1.211*aefSlalom
#aefSlalomNew=-0.012+1.214*aefSlalom
#band03
#aefSlalomNew=-0.012+1.103*aefSlalom
#aefSlalom=-0.014+1.107*aefSlalom


dev.off()

###
xyplot(aefMYD06 ~ aefSlalom, 
          xlab=list("SEVIRI 0.810 µm",cex=1.5), 
          ylab=list("MODIS 0.856 µm",cex=1.5),
          xlim=c(0,1),
          ylim=c(0,1),
          panel = function() {
            panel.grid(h = -1, v = -1, col="gray50",lty=2)
            panel.xyplot(aefSlalom,aefMYD06,pch=20,cex = 0.3,col="grey1")
            panel.ablineq(lm(aefMYD06 ~ aefSlalom), r.sq = TRUE, 
                      rot = TRUE, 
                      at = 0.8, 
                      pos = 3, cex=0.8)
                   } ) 

