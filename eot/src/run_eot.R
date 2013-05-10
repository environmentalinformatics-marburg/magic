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

# Required functions
source("src/EotDeseason.R")
source("src/EotDenoise.R")
source("src/EotControl.R")

# Launch just-in-time (JIT) compilation
# enableJIT(3)


### Data import 

pred.files <- list.files(path.data, pattern = "sst.*.rst$", full.names = TRUE, recursive = TRUE)
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


### Deseasoning

pred.stck.dsn <- EotDeseason(data = pred.stck, cycle.window = 12)
resp.stck.dsn <- EotDeseason(data = resp.stck, cycle.window = 12)


### Denoising

pred.stck.dns <- EotDenoise(data = pred.stck.dsn, k = 25)
resp.stck.dns <- EotDenoise(data = resp.stck.dsn, k = 5)


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