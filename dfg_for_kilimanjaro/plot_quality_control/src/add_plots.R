# Required libraries
library(rgdal)
library(raster)

# Working directory and data set
dsn <- switch(Sys.info()[["sysname"]], 
              "Linux" = "/media/permanent/",
              "Windows" = "D:/")
setwd(paste0(dsn, "active/kilimanjaro_plot_quality_control/data"))
input.filepath <- "plot_poles_arc1960_mod/PlotPoles_ARC1960_mod_20140410_v04_added_by_bing.shp"
output.path <- paste(dirname(input.filepath), "moved", sep = "/")
output.filepath <- paste(output.path, basename(input.filepath), sep = "/")
layer <- sub("^([^.]*).*", "\\1", basename(input.filepath))

# Set new plot details
plots.new <- data.frame(PlotID = c("emg0", "mch0", "foc0", "mwh0", "mai0", "sav0", "foc6", "mcg0", "fpo0", "fpd0"),
                        PoleName = "A middle pole",
                        PoleType = "AMP",
                        POINT_X = NaN,
                        POINT_Y = NaN,
                        coords_x3 = 0,
                        coords.x1 = c(335386, 307231, 305477, 318531, 304694, 353957, 304864, 304864, 306464, 318544),
                        coords.x2 = c(9641965, 9658017, 9655113, 9651408, 9634264, 9634163, 9652552, 9652552, 9657059, 9650477))


# Amend dataset and write to shape file
input.data <- readOGR(input.filepath, layer = layer)
prj.org <- projection(input.data)
data.df <- data.frame(input.data)

data.df.amended <- rbind(data.df, plots.new)

coordinates(data.df.amended) <- ~ coords.x1 + coords.x2
projection(data.df.amended) <- prj.org
dir.create(output.path, showWarnings = FALSE)
writeOGR(data.df.amended, output.filepath, 
         layer = layer,
         driver="ESRI Shapefile")
