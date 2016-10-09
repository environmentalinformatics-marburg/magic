library(hsdar)
library(R2Tec5)

######################################################################################
####### Data 2011
######################################################################################
#############Spectra
setwd("/home/hanna/Documents/Projects/PaDeMoS/Spektren2011")
spec2011=read.csv("community_median_calibrated.csv")
spec2011=t(spec2011)
Spectra2011=spec2011[-1,]
#Speclib2011=speclib(spectra=Spectra2011,wavelength=wavelength)
#Remove X in rownames:
row.names(Spectra2011)=substr(row.names(Spectra2011),2,99)

#############Environmental Variables
setwd("/home/hanna/Documents/Projects/PaDeMoS/Deckungsgrade2011")
Cover2011=read.csv("Env_Variables_new.csv",sep="\t")

#############Match
Spectra2011 <-Spectra2011[row.names(Spectra2011) %in%  Cover2011$FolderCommunity ,]
Cover2011<-Cover2011[match(row.names(Spectra2011), Cover2011$FolderCommunity, nomatch = 0),]

######################################################################################
#####Data 2012
######################################################################################
#############Spectra
setwd("/home/hanna/Documents/Projects/PaDeMoS/AllSpectra2012/")
data=list.files()
Spectra2012=c()
wavelength=read.spectrum(data[1])$data$Wavelength
for (i in 1:length(data)){
  Spectra2012=rbind(Spectra2012,read.spectrum(data[i])$data$Reflectance)
}
#Speclib2012=speclib(spectra=Spectra2012,wavelength=wavelength)
plots2012=paste("2012_",substr(data,0,nchar(data)-4),sep="")
row.names(Spectra2012)=plots2012
row.names(Spectra2012)=gsub("az1_", "az", row.names(Spectra2012))
row.names(Spectra2012)=gsub("qh2_", "qhh", row.names(Spectra2012))
row.names(Spectra2012)=gsub("_", "", row.names(Spectra2012))
row.names(Spectra2012)=gsub("2012", "", row.names(Spectra2012))
row.names(Spectra2012)=tolower(row.names(Spectra2012))

#############Vegetation cover
setwd("/home/hanna/Documents/Projects/PaDeMoS/Deckungsgrade2012")
data=list.files()
Cover2012=read.csv(data[1])
for (i in 2:length(data)){
  Cover2012=rbind(Cover2012,read.csv(data[i]))
}
Cover2012=Cover2012[,c(1,5)]
Cover2012$Image=tolower(Cover2012$Image)
Cover2012$Image=gsub("qh2_", "qhh_", Cover2012$Image)
Cover2012$Image=gsub("r_", "", Cover2012$Image)
Cover2012$Image=gsub(".jpg", "", Cover2012$Image)
Cover2012$Image=gsub("_", "", Cover2012$Image)

##############MATCH
Spectra2012 <-Spectra2012[row.names(Spectra2012) %in%  Cover2012$Image ,]
Cover2012<-Cover2012[match(row.names(Spectra2012), Cover2012$Image, nomatch = 0),]

##############add biomass
setwd("/home/hanna/Documents/Projects/PaDeMoS/biomass2012")
biomass2012<-read.csv("biomass2012.csv")
biomass2012$plotName=tolower(biomass2012$plotName)
biomass2012<-biomass2012[match(row.names(Spectra2012), biomass2012$plotName, nomatch = 0),]
biomass2012=biomass2012[,-c(1,2)]

#############add coordinates
setwd("/home/hanna/Documents/Projects/PaDeMoS/locations/2012/")
loc2012<-read.csv("all2012.csv",sep=";")
loc2012$NAME=tolower(loc2012$NAME)
loc2012<-loc2012[match(row.names(Spectra2012), loc2012$NAME, nomatch = 0),]



######################################################################################
###Merge 2011,2012 env
######################################################################################
env2012<-merge(Cover2012, biomass2012, by.x = "Image", by.y="plotName",all=TRUE)
env2012<-merge(env2012, loc2012, by.x = "Image", by.y="NAME",all=TRUE)
env2012<-env2012[,-c(4:7)]
env2012$Grazing<-rep(NA,nrow(env2012))
env2012<-data.frame(env2012$Image,env2012$Grazing,env2012$Cover,env2012$weight_g,env2012$ELE,env2012$X,env2012$Y)
names(env2012)<-c("ID","Grazing","VegCover","biomass","Elev","X","Y")
env2011<-Cover2011[,-c(1,2,3,4,6,8)]
env2011$biomass<-rep(NA,nrow(env2011))
env2011<-data.frame(env2011$FolderCommunity,env2011$Grazing,env2011$VegCover,env2011$biomass,env2011$Elev,env2011$X,env2011$Y)
names(env2011)<-c("ID","Grazing","VegCover","biomass","Elev","X","Y")
env2011$year<-rep("2011",nrow(env2011))
env2012$year<-rep("2012",nrow(env2012))

env2012<-env2012[match(row.names(Spectra2012), env2012$ID, nomatch = 0),]

######################################################################################
###TO SPECLIB
######################################################################################
#create speclib
Spectra=rbind(Spectra2011,Spectra2012)
Speclib_all=speclib(spectra=Spectra,wavelength=wavelength)
attributes.speclib(Speclib_all) <- rbind(env2011,env2012)
id.speclib(Speclib_all) <- Speclib_all$attributes$ID


#########################################################################################
#LOcations
########################################################################################
locations=c()
locations[grep("qh",Speclib_all$ID)]="QumaheMeadow"
locations[grep("qhh",Speclib_all$ID)]="QumaheSteppe"
locations[grep("zi",Speclib_all$ID)]="Zhidoi"
locations[grep("nc",Speclib_all$ID)]="NamTso"
locations[grep("mo",Speclib_all$ID)]="Moincer"
locations[grep("la",Speclib_all$ID)]="Latse"
locations[grep("da",Speclib_all$ID)]="Daleg"
locations[grep("bx",Speclib_all$ID)]="Baganxiang"
locations[grep("az",Speclib_all$ID)]="Aze"
locations[grep("_sa_",Speclib_all$ID)]="SazinGompa"
locations[grep("_xi_",Speclib_all$ID)]="Xinghai"
locations[grep("_tz_",Speclib_all$ID)]="Tianzhu"
locations[grep("_mq_",Speclib_all$ID)]="Maqu"
locations[grep("_hh_",Speclib_all$ID)]="HuangHe"
locations[grep("_hhII_",Speclib_all$ID)]="HuangHe"
locations[grep("_hII_",Speclib_all$ID)]="HuangHe"
locations[grep("_ko_",Speclib_all$ID)]="KokoNor"
locations[grep("_bk_",Speclib_all$ID)]="Bayankala"
locations[grep("_zi_",Speclib_all$ID)]="Zhidoi"
locations[grep("_lq_",Speclib_all$ID)]="Luqu"
locations[grep("_xc_",Speclib_all$ID)]="Xicheng"
site=as.vector(locations)



attributes.speclib(Speclib_all) <- cbind(attributes.speclib(Speclib_all),site)

row.names(Speclib_all$attributes)=NULL

Vegtype=rep("Alpine Steppe",length(Speclib_all$attributes$site))
Vegtype[(Speclib_all$attributes$site=="SazinGompa"|
           Speclib_all$attributes$site=="KokoNor"|
           Speclib_all$attributes$site=="Aze"|
           Speclib_all$attributes$site=="Luqu"|
           Speclib_all$attributes$site=="Bayankala"|
           Speclib_all$attributes$site=="Zhidoi"|
           Speclib_all$attributes$site=="Baganxiang"|
           Speclib_all$attributes$site=="Daleg"|
           Speclib_all$attributes$site=="Latse"|
           Speclib_all$attributes$site=="NamTso"|
           Speclib_all$attributes$site=="QumaheMeadow")]="Alpine Meadow"
Speclib_all$attributes$VegType=Vegtype

save(Speclib_all,file="/home/hanna/Documents/Projects/PaDeMoS/TotalDataSet/Speclib20112012.RData")
