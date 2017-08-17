panel.smoothconts <- function(x, y, z, col = "grey30", 
                              contours = TRUE, cex = 1.8, labcex = 1,
                              zlevs.conts = seq(500, 6000, 500),
                              ...)
{
  stopifnot(require("gridBase"))
  z <- matrix(z,
              nrow = length(unique(x)),
              ncol = length(unique(y)))
  rownames(z) <- unique(x)
  colnames(z) <- unique(y)
  
  if (!is.double(z)) storage.mode(z) <- "double"
  opar <- par(no.readonly = TRUE)
  on.exit(par(opar))
  if (panel.number() > 1) par(new = TRUE)
  par(fig = gridFIG(), omi = c(0, 0, 0, 0), mai = c(0, 0, 0, 0))
  cpl <- current.panel.limits(unit = "native")
  plot.window(xlim = cpl$xlim, ylim = cpl$ylim,
              log = "", xaxs = "i", yaxs = "i")
  # paint the color contour regions
  
  if (isTRUE(contours)) 
    contour(as.double(do.breaks(range(as.numeric(rownames(z))), nrow(z) - 1)),
            as.double(do.breaks(range(as.numeric(colnames(z))), ncol(z) - 1)),
            z, levels = as.double(zlevs.conts), 
            add = TRUE, cex = cex,
            axes = FALSE, lwd = 0.5,
            col = col, # color of the lines
            drawlabels = TRUE, # add labels or not
            labcex = labcex, 
            ...
    )
}
