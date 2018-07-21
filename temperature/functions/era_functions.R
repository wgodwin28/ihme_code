era_daily_mean = function(ras, ls_mask, minmax, cores){
  #get the unique days in the raster
  uniq_days = unique(substr(names(ras), 1, 11))
  
  #for each day, find the mean
  day_means = brick(mclapply(uniq_days, function(x) calc_raster_mean_array(ras[[grep(x, names(ras))]],ls_mask = ls_mask, minmax = minmax, return_ras =T), mc.cores =cores))
  #object <- lapply(uniq_days, function(x) grep(x, names(ras))) 
  names(day_means) = uniq_days
  
  return(day_means)
  
}

calc_raster_mean_array = function(rrr, ls_mask = NULL, minmax = F, return_ras = F){
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
  print("masked 1")
  return(rrr)
  
}

mask_sea <- function(ras, ls_mask, cores){
  uniq_days = unique(substr(names(ras), 1, 11))
  era <- brick(mclapply(uniq_days, function(x) mask_sea_child(ras[[grep(x, names(ras))]],ls_mask = ls_mask), mc.cores =cores))
}

mask_sea_child <- function(rrr, ls_mask){
  t <- mask(rrr, ls_mask)
  print("1 done")
  return(t)
}

##########################################################################################################################################
# this function is used to estimate pollution for islands or small countries that dont have large enough borders to pick up a grid
# the way it works is by walking around the border using 1 degree of padding (+.5 degree everytime it fails) until we pick up more than 10 grids
# we use the average of these grids as the estimate
estimateIslands <- function(location,
                            borders,
                            ras) {
  
  # Get a rectangle around the island in question
  poly <- borders@polygons[[which(borders$adm2_code == location)]]
  t <- as.data.table(borders@data)
  loc.name <- t[adm2_code == location, as.character(adm2_name)]
  
  # this loop will continue to add a half degree of padding in every direction as long as we are unable to find 10 surrounding grids
  out <- data.table(adm2_id = numeric(),
                    adm2_name = character(),
                    day = numeric(),
                    temperature = numeric())
  for(i in seq(1:nlayers(ras))){
    r <- as.data.table(rasterToPoints(ras[[i]]))
    
    # Begin with 5 degrees of padding in every direction
    distance.to.look <- .5
    looping <- TRUE
  
    #define the true extent of the island polygon
    min.long <- 1000
    min.lat <- 1000
    max.long <- -1000
    max.lat <- -1000
    
    for (iii in 1:length(poly@Polygons)) {
      max.long <- max(max.long, max(poly@Polygons[[iii]]@coords[,1]))
      max.lat <- max(max.lat, max(poly@Polygons[[iii]]@coords[,2]))
      min.long <- min(min.long, min(poly@Polygons[[iii]]@coords[,1]))
      min.lat <- min(min.lat, min(poly@Polygons[[iii]]@coords[,2]))
    }
    
    while (looping) {
      
      #print loop status
      cat(location, 
          "-trying w/ degrees of padding:", 
          distance.to.look, 
          "\n"); flush.console			
      
      #add the padding to your island polygon
      padded.min.long <- min.long - distance.to.look
      padded.min.lat <- min.lat - distance.to.look
      padded.max.long <- max.long + distance.to.look
      padded.max.lat <- max.lat + distance.to.look
      
      # find out how many grids fall within the current (padded) extent
      temp <- r[which(r$x <= padded.max.long 
                              & r$x >= padded.min.long 
                              & r$y <= padded.max.lat 
                              & r$y >= padded.min.lat), ]
      # drop missing grids
      temp <- na.omit(temp)
      
      # add a half degree to the distance in case we end up needing to reloop
      distance.to.look <- distance.to.look + .5
      
      # inform the loop whether we have discovered more than 10 grids nearby using the current padding
      looping <- !(nrow(temp) > 10)
      
      # output loop status and if we were successful how many grids were found
      loop.output <- ifelse(looping==TRUE, "FAILED", paste0("SUCCESS, pixels found #", nrow(temp)))
      cat(loop.output, "\n"); flush.console()
      
    }
  
    # find mean of the resulting pixels
    names(temp)[3] <- "temperature"
    avg <- temp[, mean(temperature, na.rm = T)]
    temp <- data.table(adm2_id = location,
                       adm2_name = loc.name,
                       temperature = avg)
    temp[, day := i]
    out <- rbind(out, temp)
  }
  
  return(out)
  
}	  
#***********************************************************************************************************************
estimateIslands2 <- function(location,
                            borders,
                            ras) {
  
  # Get a rectangle around the island in question
  poly <- borders@polygons[[which(borders$loc_id == location)]]
  t <- as.data.table(borders@data)
  loc.name <- t[loc_id == location, as.character(loc_name)]
  
  # this loop will continue to add a half degree of padding in every direction as long as we are unable to find 10 surrounding grids
  out <- data.table(location_id = numeric(),
                    location_name = character(),
                    long = numeric(),
                    lat = numeric(),
                    day = numeric(),
                    tmean = numeric())
  for(i in seq(1:nlayers(ras))){
    r <- as.data.table(rasterToPoints(ras[[i]]))
    
    # Begin with 5 degrees of padding in every direction
    distance.to.look <- .5
    looping <- TRUE
    
    #define the true extent of the island polygon
    min.long <- 1000
    min.lat <- 1000
    max.long <- -1000
    max.lat <- -1000
    
    for (iii in 1:length(poly@Polygons)) {
      max.long <- max(max.long, max(poly@Polygons[[iii]]@coords[,1]))
      max.lat <- max(max.lat, max(poly@Polygons[[iii]]@coords[,2]))
      min.long <- min(min.long, min(poly@Polygons[[iii]]@coords[,1]))
      min.lat <- min(min.lat, min(poly@Polygons[[iii]]@coords[,2]))
    }
    
    while (looping) {
      
      #print loop status
      cat(location, 
          "-trying w/ degrees of padding:", 
          distance.to.look, 
          "\n"); flush.console			
      
      #add the padding to your island polygon
      padded.min.long <- min.long - distance.to.look
      padded.min.lat <- min.lat - distance.to.look
      padded.max.long <- max.long + distance.to.look
      padded.max.lat <- max.lat + distance.to.look
      
      # find out how many grids fall within the current (padded) extent
      temp <- r[which(r$x <= padded.max.long 
                      & r$x >= padded.min.long 
                      & r$y <= padded.max.lat 
                      & r$y >= padded.min.lat), ]
      # drop missing grids
      temp <- na.omit(temp)
      
      # add a half degree to the distance in case we end up needing to reloop
      distance.to.look <- distance.to.look + .5
      
      # inform the loop whether we have discovered more than 10 grids nearby using the current padding
      looping <- !(nrow(temp) > 2)
      
      # output loop status and if we were successful how many grids were found
      loop.output <- ifelse(looping==TRUE, "FAILED", paste0("SUCCESS, pixels found #", nrow(temp)))
      cat(loop.output, "\n"); flush.console()
      
    }
    
    # find mean of the resulting pixels
    names(temp)[3] <- "tmean"
    #avg <- temp[, mean(temperature, na.rm = T)]
    #temp <- data.table(location_id = location,
     #                  location_name = loc.name,
      #                 temperature = avg)
    temp[,location_id := location]
    temp[,location_name := loc.name]
    temp[, day := i]
    setnames(temp, c("x", "y"), c("long", "lat"))
    out <- rbind(out, temp)
  }
  
  return(out)
  
}	  
#***********************************************************************************************************************