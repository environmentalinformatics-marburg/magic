geometry.variables <- function(x){
  #' Calculate selected geometry variables for clouds
  #' 
  #' @param x A rasterLayer containing NA for non clouds and any value for clouded areas
     #' @return A list of RasterStacks containing the texture parameters for each combination of channel and filter  
     #' @author Hanna Meyer
     #' @seealso \code{?SDMTools} and \code{?clump}
     require(SDMTools)
     cloudPatches<-clump(x)
     cloudStats=PatchStat(cloudPatches)
     # patch area:
     cloudArea <- reclassify(cloudPatches, cbind(cloudStats$patchID,cloudStats$area))
     #shape index:
     shapeIndex <- reclassify(cloudPatches, cbind(cloudStats$patchID,cloudStats$shape.index))
     #core area:
     coreArea <- reclassify(cloudPatches, cbind(cloudStats$patchID,cloudStats$core.area.index))
     #the ratio of the patch perimeter (m) to area (m2)
     perimAreaRatio <- reclassify(cloudPatches, cbind(cloudStats$patchID,cloudStats$perim.area.ratio))
     #distance to edge:
     edges<-boundaries(cloudPatches, type='inner')
     distEdges<- gridDistance(edges,origin=1) 
     values(distEdges)[is.na(values(cloudPatches))]=NA
     result<-stack(cloudArea,shapeIndex,coreArea,perimAreaRatio,distEdges)
     names(result)=c("cloudArea","shapeIndex","coreArea","perimAreaRatio","distEdges")
     return(result)  
}