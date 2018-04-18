# stat check vvi

vvi <- lapply(list.files("D:/VVIStats/", full.names = TRUE), read.csv)
names(vvi) <- list.files("D:/VVIStats/", full.names = FALSE)


vvi_stats <- lapply(vvi, function(x){
  data.frame(class_1 = x[1,2], class_2 = x[2,2], class_3 = x[3,2], class_4 = x[4,2])
})
vvi_stats <- do.call(rbind, vvi_stats)
vvi_stats$dif_1_2 <- vvi_stats$class_1 - vvi_stats$class_2

thresh <- quantile(vvi_stats$dif_1_2, 0.25) - IQR(vvi_stats$dif_1_2)*1.5

rownames(vvi_stats[vvi_stats$dif_1_2 < thresh,])
