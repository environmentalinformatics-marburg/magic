


#####Tests

# mit POSIXlt immer von date bis date+3300 = 1 h
#von date bis 

date+3300

#####Plots



plot(c(paste0(station$hour[1:288], station$minute[1:288])), station$Temp[1:288], "l")

plot(c(0:23), res[1:24], "l")

plot(c(0:23), result$temp[1:24], "l")


colors <- c("red", "green", "blue")

plot(c(0:23), 
     res[1:24], "l",
     xlab = "Zeit", ylab = "Temperatur",
     main = "Temperaturverlauf der Klimastation Brandvlei, \n Südafrika, 01.01.2010",
     col = colors[1], bg = colors[1], pch=21, log = "y")


points(c(1:24), 
       result$temp[1:24], "l",
       col = colors[2], bg = colors[2], pch=21)


points(c(as.numeric(paste0(station$hour[1:288], station$minute[1:288]))/100), 
       station$Temp[1:288], "l",
       col = colors[3], bg = colors[3], pch=21)

legend("topleft", pch=16, col=colors, legend=groups, bty = "n")
