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


rsquaredPerScene=function(modeldata,dateField="chDate"){
  rsquared=matrix(nrow=length(unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))),ncol=2)
  for (scene in 1:length(unique(eval(parse(text=paste("modeldata$",dateField,sep="")))))){
    rsquared[,1]=unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))
    rsquared[scene,2]=summary(lm(modeldata$observed[modeldata$chDate==unique(modeldata$chDate)[scene]]~
                       modeldata$prediction[modeldata$chDate==unique(modeldata$chDate)[scene]]))$r.squared 
    
    
  }
  rsquared
}

MEPerScene=function(modeldata,dateField="chDate"){
  library(hydroGOF)
  ME=matrix(nrow=length(unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))),ncol=2)
  for (scene in 1:length(unique(eval(parse(text=paste("modeldata$",dateField,sep="")))))){
    ME[,1]=unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))
    ME[scene,2]=me(modeldata$prediction[modeldata$chDate==unique(modeldata$chDate)[scene]],
                    modeldata$observed[modeldata$chDate==unique(modeldata$chDate)[scene]])   
  }
  ME
}

MAEPerScene=function(modeldata,dateField="chDate"){
  library(hydroGOF)
  MAE=matrix(nrow=length(unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))),ncol=2)
  for (scene in 1:length(unique(eval(parse(text=paste("modeldata$",dateField,sep="")))))){
    MAE[,1]=unique(eval(parse(text=paste("modeldata$",dateField,sep=""))))
    MAE[scene,2]=mae(modeldata$prediction[modeldata$chDate==unique(modeldata$chDate)[scene]],
                   modeldata$observed[modeldata$chDate==unique(modeldata$chDate)[scene]])   
  }
  MAE
}