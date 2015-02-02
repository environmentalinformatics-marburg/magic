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
     #perimeter:
     perimeter <- reclassify(cloudPatches, cbind(cloudStats$patchID,cloudStats$perimeter))
     #core.area.index
     coreAreaIndex <- reclassify(cloudPatches, cbind(cloudStats$patchID,cloudStats$core.area.index))
     #the ratio of the patch perimeter (m) to area (m2)
     perimAreaRatio <- reclassify(cloudPatches, cbind(cloudStats$patchID,cloudStats$perim.area.ratio))
     #distance to edge:
     edges<-boundaries(cloudPatches, type='inner')
     distEdges<- gridDistance(edges,origin=1) 
     values(distEdges)[is.na(values(cloudPatches))]=NA
     #innerCircle (largest circle)= maximum distance from edge
     tmp=zonal(distEdges,cloudPatches,fun="max")
     innerCircle=cloudPatches
     innerCircle=reclassify(innerCircle,tmp)
     ##### outer circle
     oci=c()
  
     for (i in 1:max(values(cloudPatches),na.rm=TRUE)){
      cp=cloudPatches
      cp[cp!=i]=NA
      cpp=rasterToPolygons(cp,dissolve=TRUE)
      centroid=gCentroid(cpp, byid=TRUE,id=attributes(cpp)$plotOrder)
      
      dist<- distanceFromPoints(cloudPatches, centroid)
      dist[is.na(cp)]=NA
      oci[i]=max(values(dist),na.rm=TRUE)
     }
     outerCircle <- reclassify(cloudPatches, cbind(cloudStats$patchID,oci))
     outerInnerCircle <- outerCircle-innerCircle

  ### Indices listed and/or developed by Borg 98
    borg<-borg_indices(Ar=cloudArea,Ur=perimeter,De=innerCircle*2,Du=outerCircle*2)
    
  
  ##############################################################################  
     result<-stack(cloudPatches,cloudArea,shapeIndex,coreArea,perimeter,
                   coreAreaIndex, perimAreaRatio,innerCircle,distEdges,outerCircle,
                   outerInnerCircle,borg)
     names(result)=c("cloudPatches","cloudArea","shapeIndex","coreArea",
                     "perimeter", "coreAreaIndex","perimAreaRatio",
                     "innerCircle","distEdges","outerCircle","outerInnerCircle",names(borg))
     return(result)  
}