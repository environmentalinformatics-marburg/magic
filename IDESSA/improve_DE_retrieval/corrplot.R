library(corrplot)
#### Check for correlations between all variables ##############################
correlation <- cor(datatable[,4:ncol(datatable)], use ="complete.obs")

pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/corrplot.pdf",width=30,height=30)
corrplot(correlation,type="lower",tl.cex=1)
dev.off()



correlation <- cor(datatable[,substr(names(datatable),1,2)=="f3"|substr(names(datatable),1,2)=="f5"], use ="complete.obs")

pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/results/corrplot_filter.pdf",width=30,height=30)
corrplot(correlation,type="lower",tl.cex=1)
dev.off()

