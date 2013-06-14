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
dat <- subset(dat,dat$aefSlalom < 30 & dat$aefMYD06 < 30)
dat <- subset(dat,dat$aefSlalom > 5 & dat$aefMYD06 > 5)
attach(dat)
aefSlalom05 <- aefSlalom
aefMYD0605 <- aefMYD06

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


mean(aefMYD06-aefSlalom)
sqrt(mean((aefMYD06-aefSlalom)^2))
sd(aefMYD06-aefSlalom)

####################################################################
## scatter plot mit Punktdichte pro Rasterzelle, keine Interpolation um die Rasterzellen
#####################################################################
png(filename="200806111415_py82slalom_vs_py72_hexbin_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)

iplot(aefMYD06, aefSlalom, 
      pixs=0.7, 
      ztransf=function(x){x[x<1] <- 1; log2(x)}, 
      colramp = colorRampPalette(c("grey100","grey85","grey75","grey50","grey25","grey1","black")),
      xlab="Optical thickness (M06)", 
      ylab="Optical thickness (SLALOM MODIS)",
      cex.lab=1.3,
      cex=1.1,
      cex.axis=1,
      legend=FALSE
      )

grid(col="gray50",lty=2)
mtext(" a)", side=2,line=3, cex=1.5, at=c(41),adj=1)
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
      colramp = colorRampPalette(c("grey100","grey85","grey75","grey50","grey25","grey1","black")),
      xlab="Optical thickness (M06)", 
      ylab="COT (SLALOM MODIS)/COT(M06) %",
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

png(filename="200806280945_mpy82_vs_py72_histogram_mask_tau_gt_05_2.png",width=1600,height=1600,units='px',res=300,pointsize=10)

plot(density(aefSlalom,bw=0.1),
      lwd=1.2, 
      col="black", 
      lty=1,
      xlim=c(5,40), 
      ylim=c(0,0.15),
      xlab="Optical thickness",
      ylab="Density",
      cex.lab=1.3,
      main="",
      yaxt="n",
      xaxt="n")

axis(2,las=1,cex.axis=1.0)
axis(1,cex.axis=1.0)
lines(density(aefMYD06,bw=0.1), lty=2, lwd=1.2, col="black")
#lines(density(aefSlalomA,bw=0.1), lty=3, lwd=1.2, col="black")

legend("topright", 
       inset=.05, 
       c("COT","SLALOM","M06"),
       lty = c(0,1,2),
       lwd = c(0,1.2,1.2),
       horiz=FALSE,
       cex=1.1)
grid(col="gray50",lty=2)
mtext(" e)", side=2,line=3, las = 1, cex=1.5, at=c(0.151),adj=1)

dev.off()

## AEF ###
####################################################################
## scatter plot mit Punktdichte pro Rasterzelle, keine Interpolation um die Rasterzellen
#####################################################################
png(filename="200806111415_py81slalom_vs_py75_hexbin_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)

iplot(aefMYD06, aefSlalom, 
      pixs=0.7, 
      ztransf=function(x){x[x<1] <- 1; log2(x)}, 
      colramp = colorRampPalette(c("grey100","grey85","grey75","grey50","grey25","grey1","black")),
      xlab="Effective radius, µm (M06)", 
      ylab="Effective radius, µm (SLALOM MODIS)",
      cex.lab=1.3,
      cex=1.1,
      cex.axis=1,
      legend=FALSE
      )

grid(col="gray50",lty=2)
mtext(" b)", side=2,line=3, cex=1.5, at=c(31),adj=1)
dev.off()

################################
### percentage difference ######
###############################

dif = (aefSlalom-aefMYD06)/((aefSlalom+aefMYD06)/2)*100
datdif <- cbind(dat,dif)
datdif <- subset(datdif,datdif$dif < 101 & datdif$dif > -101)
(10-30)/((10+30)/2)*100

png(filename="200806111415_py81slalom_vs_py75_hexbin_error_mask_tau_gt_05.png",width=1600,height=1600,units='px',res=300,pointsize=10)

iplot(datdif$aefMYD06,datdif$dif, 
      pixs=0.7, 
      ztransf=function(x){x[x<1] <- 1; log2(x)}, 
      colramp = colorRampPalette(c("grey100","grey85","grey75","grey50","grey25","grey1","black")),
      xlab="Effective radius, µm (M06)", 
      ylab="AEF (SLALOM MODIS)/AEF(M06) %",
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

png(filename="200806280945_mpy81_vs_py75_histogram_mask_tau_gt_05_2.png",width=1600,height=1600,units='px',res=300,pointsize=10)

plot(density(aefSlalom05,bw=0.05),
      lwd=1.8, 
      col="black", 
      lty=1,
      xlim=c(0,30), 
      ylim=c(0,0.3),
      xlab="Effective radius, µm",
      ylab="Density",
      cex.lab=1.3,
      main="",
      yaxt="n",
      xaxt="n")

axis(2,las=1,cex.axis=1.0)
axis(1,cex.axis=1.0)
lines(density(aefMYD0605,bw=0.05), lty=2, lwd=1.8, col="black")
lines(density(aefSlalom,bw=0.05), lty=1, lwd=1.0, col="black")
lines(density(aefMYD06,bw=0.05), lty=2, lwd=1.0, col="black")

legend("topright", 
       inset=.05, 
       c("AEF","SLALOM (COT>5)","M06 (COT>5)", "SLALOM (COT>10)", "M06 (COT>10)"),
       lty = c(0,1,2,1,2),
       lwd = c(0,1.8,1.8,1.0,1.0),
       horiz=FALSE,
       cex=1.1)
grid(col="gray50",lty=2)
mtext(" f)", side=2,line=3, las = 1, cex=1.5, at=c(0.31),adj=1)

dev.off()






