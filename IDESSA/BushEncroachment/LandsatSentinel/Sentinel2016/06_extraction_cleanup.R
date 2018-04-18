# aerial 16 extraction clean up

extr_fls <- list.files("F:/ludwig/aerial_16/extraction/", full.names = TRUE)
extr_nam <- list.files("F:/ludwig/aerial_16/extraction/", full.names = FALSE)

for(x in seq(length(extr_fls))){
  extr <- read.csv(extr_fls[x])
  # remove pixels with na classification
  extr <- extr[extr$class_na == 0,]
  
  # calculate bush percentage
  extr$bush_perc <- extr$class_1 / (extr$class_1 + extr$class_2 + extr$class_3 + extr$class_4)
  write.csv(extr, paste0("F:/ludwig/aerial_16/extraction_cleaned/", extr_nam[x]))
}


