library(latticeExtra)

path <- "/media/tims_ex/kilimanjaro_gsod_dynamics/tanzania_met_office"
setwd(path)

kia <- read.csv("data/kia.csv", stringsAsFactors = FALSE)
moshi <- read.csv("data/moshi.csv", stringsAsFactors = FALSE)

tkia <- lapply(seq(nrow(kia)), function(x){
  data.frame(YEAR = as.Date(paste(kia[x,1], sprintf("%02d", seq(12)),
                                  "01", sep = "-"),"%Y-%m-%d"),
             P_RT_NRT = as.numeric(t(kia[x,c(2:13)])))
})
tkia <- do.call("rbind", (tkia))
xyplot(tkia$P_RT_NRT ~ tkia$YEAR, type = "h")

tmoshi <- lapply(seq(nrow(moshi)), function(x){
  data.frame(YEAR = as.Date(paste(moshi[x,1], sprintf("%02d", seq(12)),
                                  "01", sep = "-"),"%Y-%m-%d"),
             P_RT_NRT = as.numeric(t(moshi[x,c(2:13)])))
})
tmoshi <- do.call("rbind", (tmoshi)) 
xyplot(tmoshi$P_RT_NRT ~ tmoshi$YEAR, type = "h")
