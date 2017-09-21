# run p5/R/traj.R before

rgb = kiliAerial(c(35, 20), c(-10, 80), type = "terrain", rgb = TRUE, scale = 2)

lst <- foreach(i = formatC(1:12, width = 2, flag = "0"), j = month.abb
               , .packages = lib) %dopar% {
  
  dts = as.Date(paste0("2016-", i, "-01"))
  
  dts = c(dts, as.Date(paste("2016", i, lubridate::days_in_month(dts), sep = "-")))
  dts = seq(dts[1], dts[2], "day")

  lbl <- paste(j, "2016")
  
  ofl <- paste("iso", h, paste0("2016", i), "", sep = "_")
  
  trj <- ProcTraj(lat = lat, lon = lon, name = ofl,
                  hour.interval = 1,
                  met = KMetFiles, out = KOutFiles,
                  hours = -24 * 4, height = 3000L, hy.path = KHySplitPath, ID = i, 
                  dates = dts,
                  start.hour = "00:00", end.hour = "00:00")
  
  sln <- Df2SpLines(trj, crs = "+init=epsg:4326")
  
  spplot(sln, scales = list(draw = TRUE, cex = .7), 
         xlim = c(20, 80), ylim = c(-10, 35),
         colorkey = FALSE, col.regions = "black", lwd = 2, 
         sp.layout = list(rgb2spLayout(rgb, alpha = .5))) + 
    layer(sp.points(dat[dat$`Station Code` == h, ], col = "black", pch = 24, 
                    cex = 1.2, fill = "white"), data = list(dat = dat)) + 
    layer(sp.text(c(70, -7.5), lbl, font = 1, cex = .7), 
          data = list(lbl = lbl))
}

img <- suppressWarnings(latticeCombineGrid(lst, layout = c(3, 4)))
ofl <- paste0(hsp, "/results/vis/iso_", h, "_2016.png")

png(ofl, width = 18, height = 22, units = "cm", res = 500)
grid.newpage()
print(img, newpage = FALSE)
dev.off()
