rm(list=ls())
setwd("/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_Overfitting/figureprep/figureprep/")

dat <- read.csv("regtable.csv")
sdTair <- 17.2636
sdVW <- 0.07555124

colortab <- data.frame("method"=c("none","RFE","FFS"),
                       "color"=c("black","blue","red"))
shapetab <- data.frame("CV"=c("LLO","LLTO"),"shape"=c(16,17))

dat <- dat[substr(dat$Feature.Selection,1,9)!="variables"&dat$CV!="LTO"&dat$CV!="random",]
dat$color <- NA
dat$shape <- NA
for (i in 1:nrow(dat)){
dat$color[i] <- as.character(colortab$color)[which(as.character(colortab$method)==dat$Feature.Selection[i])]
dat$shape[i] <- as.character(shapetab$shape)[which(as.character(shapetab$CV)==dat$CV[i])]
}

#VW_LLOCV <- VW[substr(VW$name,1,5)=="llocv"&substr(VW$name,7,8)!="cv",]
#VW_LLTOCV <- VW[substr(VW$name,1,6)=="lltocv"&substr(VW$name,8,9)!="cv",]
#TAIR_LLOCV <- Tair[substr(Tair$name,1,5)=="llocv"&substr(Tair$name,7,8)!="cv",]
#TAIR_LLTOCV <- Tair[substr(Tair$name,1,6)=="lltocv"&substr(Tair$name,8,9)!="cv",]

Tair <- dat[substr(dat$Model,1,4)=="Tair"&dat$CV!="random"&dat$CV!="LTO",]
VW <- dat[substr(dat$Model,1,2)=="VW"&dat$CV!="random"&dat$CV!="LTO",]





#pdf("perfplot.pdf",height=5,width=8)
#par(mfrow=c(1,2),mar=c(4,4,1,1))
#plot(Tair$MAE/sdTair,Tair$Rsq,col=Tair$color,pch=as.numeric(Tair$shape),xlab="scaled MAE",ylab="R²",cex=1.5)
#plot(VW$MAE/sdVW,VW$Rsq,col=VW$color,pch=as.numeric(VW$shape),xlab="scaled MAE",ylab="R²",cex=1.5)
#legend("topright",title=c("Selection        CV      "),
#       legend=c(as.character(colortab$method),as.character(shapetab$CV)), 
#       col=c(as.character(colortab$color),rep("grey40",2)), pch=c(rep(NA,3),shapetab$shape),
#       bty="n", ncol=2,lwd=c(1,1,1,NA,NA),cex=0.60,x.intersp=0.3)
#dev.off()



legendprep <- expand.grid(as.character(colortab$method),as.character(shapetab$CV))
legendprep$col <- c()
legendprep$shp <- c()
for (i in 1:nrow(legendprep)){
  legendprep$col[i] <- as.character(colortab$color)[which(as.character(colortab$method)==legendprep$Var1[i])]
  legendprep$shp[i] <- as.character(shapetab$shape)[which(as.character(shapetab$CV)==legendprep$Var2[i])]
}


pdf("perfplot2.pdf",height=4.2,width=10)
par(oma=c(2,2,0,4),mfrow=c(1,2),mar=c(4,4,0.2,4),xpd=TRUE)
plot(Tair$MAE/sdTair,1-Tair$Rsq,col=Tair$color,pch=as.numeric(Tair$shape),xlab="MAE/sd",ylab="1-R²",cex=1.5)
plot(VW$MAE/sdVW,1-VW$Rsq,col=VW$color,pch=as.numeric(VW$shape),xlab="MAE/sd",ylab="1-R²",cex=1.5)

legend(x=0.547,y=0.528,legend=paste0(legendprep$Var1,", ",legendprep$Var2),col=legendprep$col,
       pch=as.numeric(legendprep$shp),xpd=NA,title=c("      Select., CV      "),
       cex=0.9)
dev.off()
