# R packages
# install.packages("sm") # if sm isn't installed yet
# install.packages("IDPmisc")
library(IDPmisc)
library(sm)
library(latticeExtra)
library(rattle)


# read data
filename <- file.choose()
msg <- read.table(filename, header=T, na.strings="-99.000000")
aqua <- read.table(filename, header=T, na.strings="-99.000000")
msg$msgx=msg$msgx*1000

## plot
png(filename="spectral_response_0_8.png",width=2000,height=1600,units='px',res=300,pointsize=10)


plot(aqua$aquax,
     aqua$aquasrf,
      lwd=2, 
      col="black", 
      lty=1,
      xlim=c(750,920), 
      ylim=c(0,1),
      xlab="nm",
      ylab="Normalized spectral response",
      cex.lab=1.3,
      main="",
      yaxt="n",
      xaxt="n", 
     type="l")

axis(2,las=1,cex.axis=1.0)
axis(1,cex.axis=1.0)

lines(msg$msgx,msg$msgsrf, lty=5, lwd=1.2, col="black")



legend("topright", 
       inset=.05, 
       c("Aqua","SEVIRI"),
       lty = c(1, 5), 
       horiz=FALSE,
       cex=1.1)
grid(col="gray50",lty=2)
mtext(" a)", side=2,line=3, las = 1, cex=1.5, at=c(1),adj=1)

dev.off()
       