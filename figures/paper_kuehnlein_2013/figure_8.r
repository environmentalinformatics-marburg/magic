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
dat <- subset(dat,dat$aefSlalom < 20 & dat$aefMYD06 < 20)
dat <- subset(dat,dat$aefSlalom < 35 & dat$aefMYD06 < 35)

dat <- subset(dat,dat$aefSlalom > 0 & dat$aefMYD06 > 0)
attach(dat)

###########################
######## statistics ######
###########################

min(aefSlalom)
max(aefSlalom)
median(aefSlalom)
mean(aefSlalom)
sd(aefSlalom)
#modalvalue(aefSlalom)

min(aefMYD06)
max(aefMYD06)
median(aefMYD06)
mean(aefMYD06)
sd(aefMYD06)
#modalvalue(aefMYD06)

c=cor(aefSlalom,aefMYD06)
c

diff<-(aefMYD06-aefSlalom)
mean (diff)
sqrt(mean((aefMYD06-aefSlalom)^2))
sd(aefMYD06-aefSlalom)

####################################################################
## scatter plot mit Punktdichte pro Rasterzelle, keine Interpolation um die Rasterzellen
#####################################################################

png(filename="200806111415_py82slalom_vs_py72_hexbin_error_mask_tau_gt_05.png",width = 1024*6, 
    height = 768*6,units='px',res=600,pointsize=10)

iplot(aefMYD06, aefSlalom, 
      pixs=0.7, 
      ztransf=function(x){x[x<1] <- 1; log2(x)},
      #zmax=5,
      #colramp = colorRampPalette(c("grey90","grey80","grey60","grey40","grey20","grey1","black")), 
      colramp = colorRampPalette(c("grey80","grey60","grey40","grey20","grey1","black")), 
      #colramp = colorRampPalette(c("grey75","grey50","grey25","grey1","black")),
      #xlab="Effective radius, µm (MYD06)", 
      #ylab="Effective radius, µm (SLALOM SEVIRI)",
      xlab="Optical thickness (M06)", 
      ylab="Optical thickness (SLALOM SEVIRI)",
      cex.lab=1.3,
      cex=1.1,
      cex.axis=1,
      legend=FALSE
      )

grid(col="gray50",lty=2)
mtext(" a)", side=2,line=3, cex=1.5, at=c(36),adj=1)
dev.off()



################################
### percentage difference ######
###############################

dif = (aefSlalom-aefMYD06)/((aefSlalom+aefMYD06)/2)*100
datdif <- cbind(dat,dif)
datdif <- subset(datdif,datdif$dif < 101 & datdif$dif > -101)
(10-30)/((10+30)/2)*100

png(filename="200806111415_py82slalom_vs_py72_hexbin_error_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)

iplot(datdif$aefMYD06,datdif$dif, 
      pixs=0.7, 
      ztransf=function(x){x[x<1] <- 1; log2(x)}, 
      colramp = colorRampPalette(c("grey80","grey60","grey40","grey20","grey1","black")), 
      #xlab="Effective radius, µm (MYD06)", 
      #ylab="AEF (SLALOM SEVIRI)/AEF(MYD06) %",
      xlab="Optical thickness (M06)", 
      ylab="COT (SLALOM SEVIRI)/COT(M06) %",
      #xlab="MODIS band 2", 
      #ylab="SEVIRI band 2/MODIS band 2 %",
      cex.lab=1.3,
      cex=1.1,
      cex.axis=1,
      legend=FALSE)
mtext(" c)", side=2,line=3, cex=1.5, at=c(106),adj=1)
grid(col="gray50",lty=2)
abline(h=0, col = "black")
dev.off()


###########################
#### density plot  ######
###########################

png(filename="200806280945_py82slalom_vs_py72_histogram_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)

plot(density(aefSlalom,bw=0.1),
      lwd=1.5, 
      col="black", 
      lty=1,
      xlim=c(5,35), 
      ylim=c(0,0.2),
      xlab="Optical thickness",
      #xlab="Effective radius, µm",
      ylab="Density",
      cex.lab=1.3,
      main="",
      yaxt="n",
      xaxt="n")

axis(2,las=1,cex.axis=1.0)
axis(1,cex.axis=1.0)
lines(density(aefMYD06,bw=0.1), lty=5, lwd=1.2, col="black")
#lines(density(aefSlalomA,bw=0.1), lty=3, lwd=1.2, col="black")

legend("topright", 
       inset=.05, 
       c("COT - SLALOM SEVIRI","COT - M06"),
       #c("COT - SLALOM SEVIRI","COT - MYD06","COT - SLALOM SEVIRI-A"),
       #fill=c("blue", "red"),
       lty = c(1, 5),
       horiz=FALSE,
       cex=1.1)
grid(col="gray50",lty=2)
mtext(" e)", side=2,line=3, las = 1, cex=1.5, at=c(0.21),adj=1)

dev.off()

## AEF ###
####################################################################
## scatter plot mit Punktdichte pro Rasterzelle, keine Interpolation um die Rasterzellen
#####################################################################
png(filename="200806111415_py81slalom_vs_py75_hexbin_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)
png(filename="legend.png",width=1600,height=1600,units='px',res=300,pointsize=10)

iplot(aefMYD06, aefSlalom, 
      pixs=0.7, 
      ztransf=function(x){x[x<1] <- 1; log2(x)}, 
      #colramp = colorRampPalette(c("grey90","grey80","grey60","grey40","grey20","grey1","black")), 
      colramp = colorRampPalette(c("grey80","grey60","grey40","grey20","grey1","black")), 
      #colramp = colorRampPalette(c("grey100","grey80","grey60","grey25","grey1","black")),
      xlab="Effective radius, µm (M06)", 
      ylab="Effective radius, µm (SLALOM SEVIRI)",
      cex.lab=1.3,
      cex=1.1,
      cex.axis=1,
      legend=TRUE
      )

grid(col="gray50",lty=2)
mtext(" b)", side=2,line=3, cex=1.5, at=c(21),adj=1)
dev.off()

################################
### percentage difference ######
###############################

dif = (aefSlalom-aefMYD06)/((aefSlalom+aefMYD06)/2)*100
datdif <- cbind(dat,dif)
datdif <- subset(datdif,datdif$dif < 101 & datdif$dif > -101)
(15-5)/((15+5)/2)*100

png(filename="200806111415_py81slalom_vs_py75_hexbin_error_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)

iplot(datdif$aefMYD06,datdif$dif, 
      pixs=0.7, 
      ztransf=function(x){x[x<1] <- 1; log2(x)}, 
      colramp = colorRampPalette(c("grey80","grey60","grey40","grey20","grey1","black")), 
      xlab="Effective radius, µm (M06)", 
      ylab="AEF (SLALOM SEVIRI)/AEF(M06) %",
      cex.lab=1.3,
      cex=1.1,
      cex.axis=1,
      legend=FALSE)
mtext(" d)", side=2,line=3, cex=1.5, at=c(106),adj=1)
grid(col="gray50",lty=2)
abline(h=0, col = "black")
dev.off()


###########################
#### density plot  ######
###########################

png(filename="200806280945_py81slalom_vs_py75_histogram_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)

plot(density(aefSlalom,bw=0.1),
      lwd=1.5, 
      col="black", 
      lty=1,
      xlim=c(5,20), 
      ylim=c(0,0.4),
      xlab="Effective radius, µm",
      ylab="Density",
      cex.lab=1.3,
      main="",
      yaxt="n",
      xaxt="n")

axis(2,las=1,cex.axis=1.0)
axis(1,cex.axis=1.0)
lines(density(aefMYD06,bw=0.1), lty=5, lwd=1.2, col="black")
#lines(density(aefSlalomA,bw=0.1), lty=3, lwd=1.2, col="black")

legend("topright", 
       inset=.05, 
       c("AEF - SLALOM SEVIRI","AEF - M06"),
       #c("COT - SLALOM SEVIRI","COT - MYD06","COT - SLALOM SEVIRI-A"),
       #fill=c("blue", "red"),
       lty = c(1, 5),
       horiz=FALSE,
       cex=1.1)
grid(col="gray50",lty=2)
mtext(" f)", side=2,line=3, las = 1, cex=1.5, at=c(0.41),adj=1)

dev.off()





### print ###
png(paste(inpath, "figure_14.png", sep = "/"), res = 300, width = 1024*3, height = 1024*3)
print(xyplot1, split = c(1,1,2,2), more = T)
print(xyplot2, split = c(2,1,2,2), more = T)
print(xyplot3, split = c(1,2,2,2), more = T)
print(xyplot4, split = c(2,2,2,2))
dev.off()

#####################
# statistical values
#####################

