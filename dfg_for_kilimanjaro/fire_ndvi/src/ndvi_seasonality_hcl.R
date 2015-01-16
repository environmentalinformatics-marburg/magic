library("rgdal")
library("RColorBrewer")
library("GISTools")
library("classInt")
library(dplyr)

temp <- tempfile(fileext = ".zip")
# now download the zip file from its location on the Eurostat website and
# put it into the temp object
# new Eurostat website
# old: http://epp.eurostat.ec.europa.eu
# new: http://ec.europa.eu/eurostat
download.file("http://ec.europa.eu/eurostat/cache/GISCO/geodatafiles/NUTS_2010_60M_SH.zip", 
              temp)
# now unzip the boundary data
unzip(temp)

EU_NUTS <- readOGR(dsn = "./NUTS_2010_60M_SH/data", layer = "NUTS_RG_60M_2010")
ToRemove <- EU_NUTS@data$STAT_LEVL!=2 | grepl('FR9',EU_NUTS@data$NUTS_ID)
EUN <- EU_NUTS[!ToRemove,]

###
dir()
r1 <- read.csv('hlth_cd_acdr2_1_Data.csv')
r1$Value <- as.character(r1$Value) %>%
  gsub(',','',.) %>%
  gsub(':','0',.) %>%
  as.numeric(.)
r2 <- reshape(r1,direction='wide',
              idvar=c('ICD10','ICD10_LABEL'),
              v.names='Value',
              timevar='GEO',
              drop=c('UNIT','TIME','AGE','SEX','Flag.and.Footnotes'))
names(r2) <- gsub('Value.','',names(r2),fixed=TRUE)

r2 <- r2[!(r2$ICD10 %in% 
             c('A-R_V-Y','A-B','C','E','F','G-H','I','J','K','M','N','R','V01-Y89','ACC'))
         ,]
row.names(r2) <- r2$ICD10_LABEL
m1 <- as.matrix(r2[,-(1:2)]) %>% t(.)

m2 <- m1[rownames(m1) %in% EUN@data$NUTS_ID,]
pr1 <- princomp(m2,cor=TRUE) 
#plot(pr1)  
#biplot(pr1)
#plot(pr1$loadings[,1],pr1$loadings[,2])
myscale <-function(x) 
  (x-min(x))/(max(x)-min(x))

tom <- data.frame(
  loc=as.character(rownames(pr1$scores)),
  rgbr=myscale(pr1$scores[,1]),
  rgbg=myscale(pr1$scores[,2]),
  rgbb=myscale(pr1$scores[,3])) 
tom$rgb <- with(tom,rgb(rgbr,rgbg,rgbb))

EUN@data = data.frame(EUN@data[,1:4], tom[
  match(EUN@data[, "NUTS_ID"],tom[, "loc"]),   ])

png('map.png')
par(mar=rep(0,4))
plot <- plot(EUN, col = EUN@data$rgb, 
             axes = FALSE, border = NA)    
dev.off()
load <- as.data.frame(as.matrix(pr1$loadings[,1:3]))
load$name  <- rownames(pr1$loadings) 
load <- mutate(load,
               rgbr=myscale(Comp.1),
               rgbg=myscale(Comp.2),
               rgbb=myscale(Comp.3), 
               rgb =rgb(rgbr,rgbg,rgbb))
range(load$Comp.1)
png('legend2.png',
    width=960,
    height=960,
    res=144)
par(mar=rep(0,4))
with(load,plot(x=Comp.1,y=Comp.2,type='n',
               xlim=range(Comp.1)*1.2))
sample_n(load,40) %>%
  with(.,text(x=Comp.1,y=Comp.2,
              labels=name,
              col=rgb,cex=.5))
dev.off()
