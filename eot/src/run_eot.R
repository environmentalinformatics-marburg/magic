### Environmental settings

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
path.wd <- "E:/programming/r/r_eot"
setwd(path.wd)

# Paths and files
path.data <- "data"
path.out <- "out"

# Required packages
# library(compiler)
library(raster)
library(parallel)

# Required functions
source("src/EotDeseason.R")
source("src/EotDenoise.R")
source("src/EotControl.R")

# Launch just-in-time (JIT) compilation
# enableJIT(3)


### Data import 

pred.files <- list.files(path.data, pattern = "SST.*.rst$", full.names = TRUE, recursive = TRUE)
resp.files <- list.files(path.data, pattern = "gpcp.*.rst$", full.names = TRUE, recursive = TRUE)

# # Stack data by year
# pred.years <- unique(substr(basename(pred.files), 10, 13))
# resp.years <- unique(substr(basename(resp.files), 13, 16))
# 
# pred.stck <- lapply(pred.years, function(i) {
#   stack(pred.files[grep(i, pred.files)])
# })
# resp.stck <- lapply(resp.years, function(i) {
#   stack(resp.files[grep(i, resp.files)])
# })

# Stack data
pred.stck <- stack(pred.files)
resp.stck <- stack(resp.files)

# # Set pixel values == 0 (land masses) to NA
# n.cores <- detectCores()
# clstr <- makePSOCKcluster(n.cores)
# clusterEvalQ(clstr, c(library(raster), library(rgdal)))
# clusterExport(clstr, c("pred.stck", "resp.stck"))
#               
# pred.stck <- do.call("stack", parLapply(clstr, seq(nlayers(pred.stck)), function(i) {
#   tmp <- pred.stck[[i]]
#   tmp[which(tmp[] == 0)] <- NA
#   return(tmp)
# }))
#               
# resp.stck <- do.call("stack", parLapply(clstr, seq(nlayers(resp.stck)), function(i) {
#   tmp <- resp.stck[[i]]
#   tmp[which(tmp[] == 0)] <- NA
#   return(tmp)
# }))              
# 
# stopCluster(clstr)

# # Artificial cropping
# pred.stck <- crop(pred.stck, extent(c(-180, -120, -20, 20)))
# resp.stck <- crop(resp.stck, extent(c(-160, -120, -10, 10)))


### Deseasoning

pred.stck.dsn <- EotDeseason(data = pred.stck, cycle.window = 12)
resp.stck.dsn <- EotDeseason(data = resp.stck, cycle.window = 12)


### Denoising

pred.stck.dns <- EotDenoise(data = pred.stck.dsn, k = 10)
resp.stck.dns <- EotDenoise(data = resp.stck.dsn, k = 10)


### EOT

# Output filenames
names.out <- unique(substr(names(pred.stck), 1, 13))

out <- EotControl(pred = pred.stck.dns, 
                  resp = resp.stck.dns, 
                  n = 2, 
                  path.out = path.out, 
                  names.out = names.out, 
                  cycle.window = 12)


### Plotting

spplot(out[[6]]$rsq.predictor[[1]])
spplot(out[[6]]$rsq.response[[1]])
spplot(out[[6]]$residuals[[1]], 2)