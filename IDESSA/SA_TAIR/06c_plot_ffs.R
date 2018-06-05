# this is a quick&dirty script that plots the ffs results
# from a ffs that was built with an early version of CAST
# before a tidy plotting method was implemented

rm(list=ls())
load("/home/hanna/Documents/Projects/IDESSA/airT/forPaper/modeldat/ffs_model.RData")

model <- ffs_model

library(qpcR)
library(viridis)
library(ggplot2)

# output list as it is now
perf_all <- model$perf_all


# split the list
variables <- lapply(perf_all, '[[', 1)
rmse <- lapply(perf_all, '[[', 2)
rmse_sd <- lapply(perf_all, '[[', 3)

# create new output dataframe
output_df <- as.data.frame(do.call(qpcR:::rbind.na, variables))
# count the number of variables
output_df$n_var <- apply(output_df, 1, function(x) sum(!is.na(x)))

# add the rmse and sd  
output_df$rmse <- do.call(c, rmse)
output_df$rmse_sd <- do.call(c, rmse_sd)



# add id for easier plotting

output_df$nvar <- output_df$n_var
metric=model$metric

palette=viridis
reverse=FALSE
marker="red"
size=1.5
lwd=0.5
pch=21

output_df$run <- seq(nrow(output_df))
names(output_df)[which(names(output_df)=="rmse")] <- "value"
  bestmodels <- c()
  for (i in unique(output_df$nvar)){
    if (ffs_model$maximize){
      bestmodels <- c(bestmodels,
                      output_df$run[output_df$nvar==i][which(output_df$value[
                        output_df$nvar==i]==max(output_df$value[output_df$nvar==i]))][1])
    }else{
      bestmodels <- c(bestmodels,
                      output_df$run[output_df$nvar==i][which(output_df$value[
                        output_df$nvar==i]==min(output_df$value[output_df$nvar==i]))][1])
    }
  }
  bestmodels <- bestmodels[1:(length(ffs_model$selectedvars)-1)]
  if (!reverse){
    cols <- palette(max(output_df$nvar)-1)
  }else{
    cols <- rev(palette(max(output_df$nvar)-1))
  }
  ymin <- output_df$value - output_df$rmse_sd
  ymax <- output_df$value + output_df$rmse_sd
  if (max(output_df$nvar)>11){
    p <- ggplot2::ggplot(output_df, ggplot2::aes_string(x = "run", y = "value"))+
      ggplot2::geom_errorbar(ggplot2::aes(ymin = ymin, ymax = ymax),
                             color = cols[output_df$nvar-1],lwd=lwd)+
      ggplot2::geom_point(ggplot2::aes_string(colour="nvar"),size=size)+
      ggplot2::geom_point(data=output_df[bestmodels, ],
                          ggplot2::aes_string(x = "run", y = "value"),
                          pch=pch,colour=marker,lwd=size)+
      ggplot2::scale_x_continuous(name = "Model run", breaks = pretty(output_df$run))+
      ggplot2::scale_y_continuous(name = metric)+
      ggplot2::scale_colour_gradientn(breaks=seq(2,max(output_df$nvar),
                                                 by=ceiling(max(output_df$nvar)/5)),
                                      colours = cols, name = "variables",guide = "colourbar")
  }else{
    dfint <- output_df
    dfint$nvar <- as.factor(dfint$nvar)
    p <- ggplot2::ggplot(dfint, ggplot2::aes_string(x = "run", y = "value"))+
      ggplot2::geom_errorbar(ggplot2::aes(ymin = ymin, ymax = ymax),
                             color = cols[output_df$nvar-1],lwd=lwd)+
      ggplot2::geom_point(ggplot2::aes_string(colour="nvar"),size=size)+
      ggplot2::geom_point(data=output_df[bestmodels, ],
                          ggplot2::aes_string(x = "run", y = "value"),
                          pch=pch,colour=marker,lwd=size)+
      ggplot2::scale_x_continuous(name = "Model run", breaks = pretty(dfint$run))+
      ggplot2::scale_y_continuous(name = metric)+
      ggplot2::scale_colour_manual(values = cols, name = "variables")
    
  }
p

pdf("/home/hanna/Documents/Projects/IDESSA/airT/forPaper/visualizations/ffs_plot.pdf",
    width=7,height=6)
p
dev.off()




