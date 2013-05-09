library(latticeExtra)
library(sm)
library(RColorBrewer)

## Einlesen der Daten
inpath <- "/media/PRECI/slalom_vergleich/sandbox/slalom_vs_mod06/validation/atlantiv_coefficients_feb/figures/figure_11"
dat <- read.table(paste(inpath, "mergeCloudMSG_200806041245_mask_tau_gt_00_all_mean.dat", sep = "/"), header=T, na.strings="-99.000000")

#attach(dat)
#dat <- subset(dat_read, MSGTau < 80)
#dat <- subset(dat, MSGTau > 5 & CloudTau > 5)
#dat <- subset(dat, Anz > 2)



#############################
# COT scatter
############################

xyplot1 <- xyplot(dat$py82 ~ dat$cloudsat,
                  groups = dat$cloudsat,
                  ylab=list("Optical thickness (SLALOM)",cex=1.1), 
                  xlab=list("Optical thickness (2B-TAU)",cex=1.1),
                  scales = list(x = list(at = c(5,10,15,20,25,30,35,40,45,50,55,60)), labels = c("5","10","15","20","25","30","35","40","45","50","55","60"),cex=1.2,
                                y = list(at = c(5,10,15,20,25,30,35,40,45,50,55,60)), labels = c("5","10","15","20","25","30","35","40","45","50","55","60"),cex=1.2),
                  xlim=c(0,35),
                  ylim=c(0,35),
                  page = function(page) grid.text('a)', x = 0.015, y = 0.95),
                  panel = function() {
                    panel.grid(h = -1, v = -1, col="gray50",lty=2)
                    panel.xyplot(dat$cloudsat,dat$py82,pch = 16,cex = 0.6,col = brewer.pal(6, "Greys")[5])
                    panel.ablineq(lm(dat$py82 ~ dat$cloudsat), r.sq = TRUE, 
                                  rot = FALSE, 
                                  at = 0.4, 
                                  pos = 3,
                                  offset = 9,
                                  cex=1.3)
                  } )




#############################
# COT percentage differences
############################


difr1 = ((dat$py82-dat$cloudsat)/((dat$cloudsat+dat$py82)/2))*100

xyplot2 <- xyplot(difr1 ~ dat$cloudsat, 
                  xlab=list("Optical thickness (2B-TAU)",cex=1.1), 
                  ylab=list("COT (SLALOM)/COT (2B-TAU)  %",cex=1.1),
                  scales = list(y = list(at = c(-100,-75,-50,-25,0,25,50,75,100), labels = c("-100","-75","-50","-25","0","25","50","75","100")),cex=1.2,
                                x = list(at = c(5,10,15,20,25,30,35,40)), labels = c("5","10","15","20","25","30","35","40"),cex=1.2),
                  xlim=c(0,35),
                  ylim=c(-100,100),
                  page = function(page) grid.text('b)', x = 0.015, y = 0.95),
                  panel = function() {
                    panel.grid(h = -1, v = -1, col="gray50",lty=2)
                    panel.xyplot(dat$cloudsat, difr1,pch=16,cex = 0.6,col=brewer.pal(6, "Greys")[5])
                    panel.abline(h=0, col = "black")
                  }
)



### print ###
png(paste(inpath, "figure_11_2.png", sep = "/"), res = 300, width = 1024*3, height = 512*3)
print(xyplot1, split = c(1,1,2,1), more = T)
print(xyplot2, split = c(2,1,2,1))
dev.off()

#####################
# statistical values
#####################

min(dat$py72)
max(dat$py72)
median(dat$py72)
mean(dat$py72)
sd(dat$py72)

min(dat$py82)
max(dat$py82)
median(dat$py82)
mean(dat$py82)
sd(dat$py82)

min(dat$cloudsat)
max(dat$cloudsat)
median(dat$cloudsat)
mean(dat$cloudsat)
sd(dat$cloudsat)

c<-cor(dat$cloudsat,dat$py72)
c
c<-cor(dat$cloudsat,dat$py82)
c


mean_py72 <- mean(dat$cloudsat-dat$py72)
mean_py82 <- mean(dat$cloudsat-dat$py82)
mean_py82
mean_py72
rmse_py82 <- sqrt(mean((dat$cloudsat-dat$py82)^2))
rmse_py82
rmse_py72 <- sqrt(mean((dat$cloudsat-dat$py72)^2))
rmse_py72
sd(dat$cloudsat-dat$py82)
sd(dat$cloudsat-dat$py72)



#############################################################################################
# plot
#############################################################################################






