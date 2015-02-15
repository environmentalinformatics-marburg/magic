
glcmPerPatch= function (x,patches,nrasters=1:nlayers(x),var=c("mean", "variance", "homogeneity", 
                                                              "contrast", "dissimilarity", 
                                                              "entropy","second_moment"),n_grey=32){
  require(doParallel)
  registerDoParallel(detectCores())
  results=c()
  library(glcm)
  if (dim(x)[[1]]%%2==0){
    dimx=dim(x)[[1]]-1
  }
  if (dim(x)[[2]]%%2==0){
    dimy=dim(x)[[2]]-1
  }
  for (i in 1:max(values(patches),na.rm=TRUE)){
    xperPatch<-x
    values(xperPatch)[values(patches)!=i]=NA
    if  (sum(!is.na(values(xperPatch[[1]])))<9) {next}
    xperPatch[170/2,250/2]=apply(values(xperPatch),2,function(x){mean(x,na.rm=TRUE)})
    glcm_filter=foreach(k=nrasters,.packages= c("glcm","raster"))%dopar%{
      glcm(xperPatch[[k]], window = c(dimx, dimy), #n_grey kleiner dann schneller
           shift=list(c(0,1), c(1,1), c(1,0)),statistics=var,n_grey=n_grey,na_opt="ignore")
    }
    resultsNew=as.data.frame(cbind(i,as.data.frame(lapply(glcm_filter,function(x){values(x)[!is.na(values(x))]}))))
    names(resultsNew)=c("PatchID",names(x))
    
    resultsNew=unlist(resultsNew)
    names(resultsNew)=c(rep("ID",length(var)),paste0(expand.grid(var,names(x))[,1],"_",expand.grid(var,names(x))[,2]))
    resultsNew=resultsNew[-c(2:length(var))]
 #   rownames(resultsNew)=var
    results=rbind(results,resultsNew)

 #   print(i)
  }

    return(results)
}
