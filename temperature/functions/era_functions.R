era_daily_mean = function(ras, ls_mask, minmax = F, cores = 1){
  #get the unique days in the raster
  uniq_days = unique(substr(names(ras), 1, 11))
  
  #for each day, find the mean
  day_means = brick(mclapply(uniq_days, function(x) calc_raster_mean_array(ras[[grep(x, names(ras))]],ls_mask = ls_mask, minmax = minmax, return_ras =T), mc.cores =cores))
  #object <- lapply(uniq_days, function(x) grep(x, names(ras))) 
  names(day_means) = uniq_days
  
  return(day_means)
  
}

calc_raster_mean_array = function(rrr, ls_mask = NULL, minmax =F, return_ras = F){
  #convert to array
  #save extent
  rrr_extent = extent(rrr)
  rrr_crs = crs(rrr)
  rrr = as.array(rrr)
  
  if(minmax){
    rrr = (apply(rrr, 1:2, function(x) max(x,na.rm=T))+apply(rrr, 1:2, function(x) min(x,na.rm=T)))/2
  } else{
    rrr = apply(rrr, 1:2, function(x) mean(x,na.rm=T))
  }
  
  #Mask Values-- set to NA if not on land
  if(!is.null(ls_mask)){
    rrr = rrr * as.matrix(ls_mask)
  }
  
  if(return_ras){
    rrr = raster(rrr)
    extent(rrr) = rrr_extent
    crs(rrr) = rrr_crs
  }
  return(rrr)
  
}