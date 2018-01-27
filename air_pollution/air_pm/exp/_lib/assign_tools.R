#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 03/22/2016
# Project: RF: air_pm
# Purpose: Helper functions for 01_assign_location_ids.R, which takes the gridded dataset and cuts it into IHME countries
# source("/homes/jfrostad/_code/risks/air_pm/rr/prep.R", echo=T)
#***********************************************************************************************************************
 
#***********************************************************************************************************************
# this function is used to estimate pollution for islands or small countries that dont have large enough borders to pick up a grid
# the way it works is by walking around the border using 1 degree of padding (+.5 degree everytime it fails) until we pick up more than 10 grids
# we use the average of these grids as the estimate
estimateIslands <- function(country,
                            borders,
                            location_id.list) {
  
  # Get a rectangle around the island in question
  poly <- borders@polygons[[which(borders$location_id == country)]]
  
  # Begin with 5 degrees of padding in every direction
  distance.to.look <- 1
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
  
  # this loop will continue to add a half degree of padding in every direction as long as we are unable to find 10 surrounding grids
  while (looping) {
    
    #print loop status
    cat(location_id.list[location_id==country, location_name], 
        "-trying w/ degrees of padding:", 
        distance.to.look, 
        "\n"); flush.console			
    
    #add the padding to your island polygon
    padded.min.long <- min.long - distance.to.look
    padded.min.lat <- min.lat - distance.to.look
    padded.max.long <- max.long + distance.to.look
    padded.max.lat <- max.lat + distance.to.look
    
    # find out how many grids fall within the current (padded) extent
    temp <- pollution[which(pollution$long <= padded.max.long 
                            & pollution$long >= padded.min.long 
                            & pollution$lat <= padded.max.lat 
                            & pollution$lat >= padded.min.lat), ]
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
  
  # must convert location IDs from factor in order to collapse them, take as character to avoid returning the underlying values which seem to be incorrect
  temp$location_id <- as.numeric(as.character(temp$location_id))
  
  temp$one <- 1      
  temp <- aggregate(temp, by=list(temp$one), FUN=mean)
  temp$Group.1 <- temp$one <- NULL
  
  # Prep to be added on to the dataset
  temp$location_id <- country
  temp$long <- round(mean(max.long, min.long) * 20) / 20 # All real grids are at .05 units of latitude/longitude. 
  temp$lat <- round(mean(max.lat, min.lat) * 20) / 20
  
  return(temp)
  
}	  
#***********************************************************************************************************************
 
#***********************************************************************************************************************
# this function is used to forecast pollution (since we only have it up to 2011 at this time)
# we fit splines to the data from 1990-2011 and then use them to predict 2012-2015
# TODO current issue is that i cant predict any grids that have a missing observation from 1990-2011
# spline can only be fit with 4 obvs, so because of that i just decided to skip any grids that have missing data
# the missing data is usually in the earlier years
# future fix could be to use a different method to pred these but right now i dont think it is worth it
splinePred <- function(dt,
                       this.grid,
                       pred.vars,
                       start.year,
                       end.year) {
  
  #cat("~",this.grid); flush.console() #toggle for troubleshooting/monitoring loop status
  
  pred.length <- (end.year - start.year) + 1
  
  pred.dt <- dt[grid==this.grid & year %in% c(1990, 2000, 2010)] # these are the only values that haven't already been predicted using splines (IE real data)
  
  forecast <- dt[grid==this.grid, -c("year", pred.vars), with=F]
  forecast[1:pred.length, "year" := start.year:end.year]
  
  forecast[1:pred.length, 
           c(pred.vars) := lapply(pred.vars, 
                                  function(var) 
                                    ifelse(rep(any(is.na(pred.dt[, var, with=F])), #test if any obv is NA, spline needs 4+ obvs to fit
                                               pred.length), # note i had to add the rep*pred.length because ifelse returns things in shape of test
                                           NA, #if so, return NA for the pred
                                           predict(lm(get(var) ~ ns(year), data=pred.dt), 
                                                   newdata=data.frame(year=year)))),
           with=F]
  
  return(na.omit(forecast))
  
}
#***********************************************************************************************************************
 
#***********************************************************************************************************************
#this function is used to forecast pollution using GBD2013 methods, given that the splines were too unstable
#it used the annualized rate of change (AROC) from 2010-2011 to forecast out to 2015
arocPred <- function(dt,
                     this.grid,
                     pred.vars,
                     start.year,
                     end.year) {
  
  #cat("~",this.grid); flush.console() #toggle for troubleshooting/monitoring loop status
  
  pred.length <- (end.year - start.year) + 1
  pred.dt <- dt[grid==this.grid]
  
  forecast <- dt[grid==this.grid, -c("year", pred.vars), with=F]
  forecast[1:pred.length, "year" := start.year:end.year]
  
  predictVar <- function(var, year) {
    
    #calculate the annualized rate of change from 2010 to 2011
    rate.of.change <- -log(pred.dt[year==2011, get(var)]/pred.dt[year==2010, get(var)])/(2011-2010)
    pred.dt[year==2010, get(var)] * exp(-rate.of.change * (year-2010))
    
  }  
  
  forecast[1:pred.length, 
           c(pred.vars) := lapply(pred.vars,
                                  predictVar,
                                  year = year),
           with=F]
  
  return(na.omit(forecast))
  
}
#***********************************************************************************************************************
 
#***********************************************************************************************************************
# this is a wrapper for splinePred that subsets to country, reshapes wide, runs splinePred, and then appends the forecasts and saves a csv
castAndSave <- function(global.dt,
                        country) {
  
  cat(country, "\n"); flush.console()
  
  #subset to country
  #TODO there is a bug here that does not allow NA as an input for country, for now i am just omitting NAs
  #later it might be interesting to analyze NA countries (IE grids that are not within an IHME border)
  #as such i will want to fix this
  temp <- global.dt[country, ]
  
  #reshape the dt wide
  temp <- dcast(temp, 
                location_id + ihme_loc_id + long + y + perurban + year ~ var, #formula to cast over
                value.var="value") %>% as.data.table() #TODO BUG for some reason was converted to df after dcast, why?
  
  # create a grid ID variable, splines can only be done on a single grid at a time
  temp[, grid := as.numeric(as.factor(paste0(long,y)))]
  
  # ensure that year is a numeric, after cast it is becoming character and it needs to be a number to be used in the extrapolation formula
  temp[, year := as.numeric(year)]
  
  #wrapper function to supply which prediction function we want to use based on an argument at the top
  choosePred <- function(type) {
    
    switch(type,
           spline = splinePred,
           aroc = arocPred)
    
  }
  
  #generate forecasts using your spline prediction function
  forecasts <- lapply(unique(temp$grid),
                      choosePred(prediction.method),
                      dt = temp,
                      pred.vars = c("fus", "pop", "o3"),
                      start.year = 2012,
                      end.year = 2015)
  
  #add the forecasts to the dt
  temp <- rbind(rbindlist(forecasts), #first use rbindlist to turn the output of lapply into a dt 
                temp) # there may be a better way to do this...
  
  #write the country CSV so we can run in parallel at later stages
  write.csv(temp, 
            file.path(out.dir, paste0(country, ".csv")), 
            row.names=F)
  
  #also return each country to a list in case we want to look at them interactively or do testing
  return(temp)
  
}
#***********************************************************************************************************************
 
#***********************************************************************************************************************
# use this function instead of castAndSave if you don't care about forecasts
# simply splits the dt into countries, creates draws based on uncertainty interval, and saves a CSV
saveCountry <- function(global.dt,
                        country,
                        method,
                        fx.cores,
                        draws.required=1000,
                        test.toggle=T) {
  
  cat(country, "\n"); flush.console()
  
  #subset to country
  temp <- global.dt[country, ]
  
  # add index
  temp[, index := seq_len(.N)]
  
  # create a list of draw names based on the required number of draws for this run
  draw.colnames <- c(paste0("draw_",1:draws.required))
  
  #divide into a list where each piece is a chunk of the dt (4 ~equal pieces in total)
  chunks <- split(temp, as.numeric(as.factor(temp$index)) %% fx.cores)
  
  #break DT into 1000 grid chunks in order to parallelize this calculation
  chunkWrapper <- function(this.chunk,
                           transformation=method,
                           ...) {

  if (transformation == "log_space") {
    
    #create draws of exposure based on provided uncertainty
    #may need to make changes to this step to take into account spatial covariance
    #note changed this step on 06132016 in response to 05272016 email that the modelling is done in log and therefore draws
    #must be created in log and then exponeniated
    this.chunk[, draw.colnames := rnorm(draws.required, mean=log(median), sd=(log(upper)-log(lower))/3.92) %>% exp %>% as.list, 
         by="index", with=F]
    
  } else if (transformation == "normal_space") {
  
    this.chunk[, draw.colnames := rnorm(draws.required, mean=median, sd=(upper-lower)/3.92) %>% as.list, 
       by="index", with=F]
    
  }
  
    if (test.toggle == TRUE) {
      
      #test work
      this.chunk[, "mean_calc" := rowMeans(.SD), .SDcols=draw.colnames, by="index"]
      this.chunk[, "lower_calc" := quantile(.SD, c(.025)), .SDcols=draw.colnames, by="index"]
      this.chunk[, "upper_calc" := quantile(.SD, c(.975)), .SDcols=draw.colnames, by="index"]
      
      this.chunk[, "diff_mean" := median - mean_calc]  
      this.chunk[, "diff_lower" := lower - lower_calc]  
      this.chunk[, "diff_upper" := upper - upper_calc]  
      
    }
  
    return(this.chunk)
  
  }
  
  output <- mclapply(chunks, chunkWrapper, mc.cores=fx.cores) %>% rbindlist
  
  #write the country CSV so we can run in parallel at later stages
  write.csv(output, 
            file.path(out.dir, paste0(country, ".csv")), 
            row.names=F)
  
  #also return the 2015 values for country to a list in case we want to look at them interactively or do testing
  return(output[year==2015, -draw.colnames, with=F])
  
}
#***********************************************************************************************************************