library(latticeExtra)
library(Rsenal)
library(kza)

path <- "/home/ede/software/magic/dfg_for_kilimanjaro/precipdyn_kilimanjaro/tanzania_met_office"
setwd(path)

fls <- list.files("data", full.names = TRUE)

station <- c("KIA", "Moshi")

prcp_kia_moshi <- lapply(seq(fls), function(i) {

  tmp <- read.csv(fls[i], stringsAsFactors = FALSE)

  ttmp <- lapply(seq(nrow(tmp)), function(x){
    data.frame(YEAR = as.Date(paste(tmp[x,1], sprintf("%02d", seq(12)),
                                    "01", sep = "-"),"%Y-%m-%d"),
               P_RT_NRT = as.numeric(t(tmp[x,c(2:13)])))
  })
  ttmp <- do.call("rbind", (ttmp))
  xyplot(ttmp$P_RT_NRT ~ ttmp$YEAR, main = station[i], type = "h")


  ### make sure time series is regular
  tseries <- as.Date(createTimeSeries(ttmp$YEAR[1], ttmp$YEAR[nrow(ttmp)],
                                      step = "months"))

  ttmp_compl <- merge(data.frame(YEAR = tseries), ttmp, all = TRUE)

  ttmp_compl$month <- substr(ttmp_compl$YEAR, 6, 7)

  ttmp_compl$name <- rep(station[i], nrow(ttmp_compl))

  mnth.ave <- aggregate(ttmp_compl$P_RT_NRT, by = list(ttmp_compl$month),
                        FUN = mean, na.rm = TRUE)

  names(mnth.ave) <- c("month", "P_RT_NRT_mmean")
  tmp4 <- merge(ttmp_compl, mnth.ave, all.x = TRUE)
  tmp4 <- tmp4[order(tmp4$YEAR), ]
  tmp4$dev <- tmp4$P_RT_NRT - tmp4$P_RT_NRT_mmean

  tmp4$mave3 <- kz(tmp4$dev, 3, 1)
  return(tmp4)
})

prcp_kia_moshi[[3]] <- data.frame(YEAR = prcp_kia_moshi[[1]]$YEAR,
                                  P_RT_NRT = rowMeans(cbind(prcp_kia_moshi[[1]]$P_RT_NRT,
                                                            prcp_kia_moshi[[2]]$P_RT_NRT),
                                                      na.rm = TRUE),
                                  name = "MEAN_KIA_MOSHI",
                                  P_RT_NRT_mmean = rowMeans(cbind(prcp_kia_moshi[[1]]$P_RT_NRT_mmean,
                                                                   prcp_kia_moshi[[2]]$P_RT_NRT_mmean),
                                                             na.rm = TRUE),
                                  dev = rowMeans(cbind(prcp_kia_moshi[[1]]$dev,
                                                       prcp_kia_moshi[[2]]$dev),
                                                 na.rm = TRUE),
                                  mave3 = rowMeans(cbind(prcp_kia_moshi[[1]]$mave3,
                                                         prcp_kia_moshi[[2]]$mave3),
                                                   na.rm = TRUE))


station <- c("KIA", "MOSHI", "MEAN_KIA_MOSHI")
panel.nmbr <- c("a) ", "b) ", "c) ")
write <- FALSE

out <- lapply(seq(station), function(i) {

  tmp4 <- prcp_kia_moshi[[i]]

  clr <- as.character(ifelse(tmp4$mave3 > 0, "blue", "red"))

  p <- xyplot(tmp4$mave3 ~ tmp4$YEAR, origin = 0, type = "h",
              border = "transparent", col = clr, asp = 0.25,
              xlab = "", ylab = "Precipitation [mm]",
              lwd = 1.5, ylim = c(-260, 260), as.table = TRUE,
              scales = list(x = list(axs = "i")),
              xscale.components = xscale.components.subticks,
              yscale.components = yscale.components.subticks,
              #             main = paste(toupper(station[i]),
              #                          "(deviation from long-term monthly mean)"),
              panel = function(x, y, ...) {
                panel.xblocks(x, y < 0,
                              col = c("#fee0d2"))
                panel.xblocks(x, y > 0,
                              col = c("#c6dbef"))
                panel.xyplot(x, y, ...)
                panel.smoother(x, y, method = "lm",
                               col = "black",
                               col.se = "black",
                               alpha.se = 0.3, lty = 2)
                panel.text(x = as.Date("1974-01-01"), y = 210,
                           labels = paste(panel.nmbr[i], toupper(station[i]),
                                          " (",
                                          substr(range(tmp4$YEAR)[1], 1, 7),
                                          " - ",
                                          substr(range(tmp4$YEAR)[2], 1, 7),
                                          ")", sep = ""),
                           adj = c(0, 0.5))
              })

  return(p)

})

p_out <- latticeCombineGrid(out, layout = c(1, 3))

png("figures/precip_series_kia_moshi_mean.png", width = 30, height = 25,
    units = "cm", res = 300)
print(p_out)
dev.off()
