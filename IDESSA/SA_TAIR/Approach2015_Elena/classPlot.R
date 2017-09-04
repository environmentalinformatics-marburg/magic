classPlot <- function(input, x, y, col, ret = F){
  # erzeugt einen xyplot in dem die Daten nach einer bestimmten Spalte 
  # klassifiziert sind
  
  # Args:
  #   input = data.frame mit den Daten
  #   x = Name der Spalte mit den x-Werten
  #   y = Name der Spalte mit den y-Werten
  #   col = Name der Spalte nach der die Daten klassifiziert werden sollen
  
  # Returns:
  #   optionally: the created plot_list for access of individual class plots

  
  # Spaltennummern herausfinden
  if(col %in% colnames(input))
    a <- match(col, colnames(input))
  else
    stop("Spaltenname fuer Klassen ungueltig")
  if(x %in% colnames(input))
    x <- match(x, colnames(input))
  else
    stop("Spaltenname fuer x-Werte ungueltig")
  if(y %in% colnames(input))    
    y <- match(y, colnames(input))
  else
    stop("Spaltenname fuer y-Werte ungueltig")
  
  # alles in einen plot packen
  groups <- unique(input[[a]])
  colors <- c("red", "green", "blue", "orange","purple", "brown", "pink")
  colors <- colors[1:length(groups)]
  
  xmin <- min(input[[x]], na.rm = T)
  xmax <- max(input[[x]], na.rm = T)
  ymin <- min(input[[y]], na.rm = T)
  ymax <- max(input[[y]], na.rm = T)
  
  plot_list <- lapply(seq(groups), function(i) {
    xyplot(input[[y]][input[[a]] == groups[i]] ~ 
             input[[x]][input[[a]] == groups[i]],      
           xlab = "LST °C", ylab = "Ta °C",
           main = "Landoberflächentemperatur & Lufttemperatur",
           col = colors[i], fill = colors[i], pch=21,
           #xlim = seq(-10, 60, length.out = 8),
           #ylim = seq(-10, 60, length.out = 8),
           
           xlim = seq(xmin-2, xmax+2, length.out = 8),
           ylim = seq(ymin-2, ymax+2, length.out = 8),
           
           key = list(points = list(pch = rep(21, 3), 
                                    col = colors,
                                    fill = colors),
                      text = list(labels = as.character(groups)), 
                      x = 0.05, y = 0.95, corner = c(0, 1)))
  })
  
  latticeCombineLayer(plot_list)
  
  if(ret == T)
    return(plot_list)
}
