### Environmental settings

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
setwd(path.wd <- "E:/programming/r/r_eot")

# Paths and files
path.data <- "data"
path.out <- "out"

# Required packages
library(raster)

# Required functions
src <- c("src/EotDeseason.R", "src/EotDenoise.R", "src/EotControl.R")
lapply(src, source)


### Data import 

pred.files <- list.files(path.data, pattern = "SST.*.rst$", full.names = TRUE, recursive = TRUE)
resp.files <- list.files(path.data, pattern = "gpcp.*.rst$", full.names = TRUE, recursive = TRUE)

# Stack data
pred.stck <- stack(pred.files)
resp.stck <- stack(resp.files)

# # Artificial cropping
# pred.stck <- crop(pred.stck, extent(-10, 10, -5, 5))
# resp.stck <- crop(resp.stck, extent(-10, 10, -5, 5))


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
                  resp = resp.stck.dns,   # defaults to pred if not provided
                  n = 2, 
                  write.out = TRUE,       # default is FALSE
                  path.out = path.out,    # default is current wd
                  names.out = names.out,  # default is NULL 
                  cycle.window = 12)      # default is nlayers(pred)


### Plotting

spplot(out[[1]]$rsq.predictor[[1]])
spplot(out[[1]]$rsq.response[[1]])
spplot(out[[1]]$resid.response[[1]])