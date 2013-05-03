# Working directory
setwd("E:/kilimanjaro_landcover/plots/")

# Parallelization
library(parallel)
n.cores <- detectCores()
clstr <- makePSOCKcluster(n.cores)

# List directories and/or files to zip 
dirs <- unique(substr(list.files(full.names = FALSE, include.dirs = TRUE), 1, 4))

# Perform compression
clusterExport(clstr, "dirs")
parLapply(clstr, dirs, function(i) {
  system(paste("7z a", paste(toupper(i), "7z", sep = "."), i, sep = " "))
})
