rmse=function(observed,predicted){sqrt(mean((observed - predicted)^2, na.rm = TRUE))}

rmsePerScene=function(modeldata,dateField="chDate"){
  RMSE=matrix(nrow=length(unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))),ncol=2)
  for (scene in 1:length(unique(eval(parse(text=paste("modeldata$",dateField,sep="")))))){
    RMSE[,1]=unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))
    RMSE[scene,2]=rmse(modeldata$observed[modeldata$chDate==unique(modeldata$chDate)[scene]],
                            modeldata$prediction[modeldata$chDate==unique(modeldata$chDate)[scene]])
  
  
  }
  RMSE
}