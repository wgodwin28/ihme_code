#----DEPENDENCIES-----------------------------------------------------------------------------------------------------------------
# load packages, install if missing
pacman::p_load(data.table, parallel, plyr, reshape2)

# # function that generates the RRs using the above parameter outputs
# rr.functions <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/functional_forms_updated.r")
# 
# # Bring in RR function and parameters
# source(rr.functions)
# fobject <- get(rr.functional.form)
#********************************************************************************************************************************

#********************************************************************************************************************************
#this function preps the various RR curves by reading their output files and then appending into a single list
prepRR <- function(age.cause.number, 
                   rr.dir) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  # parameters that define these curves are used to generate age/cause specific RRs for a given exposure level
  fitted.parameters <- fread(paste0(rr.dir, "/params_", cause.code, "_", age.code, ".csv"))
  
  setnames(fitted.parameters, "V1", "draws")
  
  return(fitted.parameters)
  
}
#********************************************************************************************************************************

#********************************************************************************************************************************
# calculate RRs due to air PM exposure using various methods and 
calculatePAFs <- function(age.cause.number,
                          exposure.object,
                          rr.curves,
                          metric.type,
                          function.draws=draws.required,
                          function.cores=1){
  
  # pull cause/age of interest from list defined by loop#
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  # display loop status
  if (year.cores == 1) message(paste0(metric.type, " - Cause:", cause.code, " - Age:", age.code))
  
  # Prep out datasets (only applies to first loop)
    
    PAF.object <- as.data.frame(matrix(as.integer(NA), nrow=nrow(age.cause), ncol=function.draws+2))
    RR.object <- exposure.object[, c("lat", # this should match the dimensions of your exposure object, i also included iso3/year/pop/raw exposure
                                     "long", # in case i later want to output this dataset, the above listed vars make it more useful
                                     "ihme_loc_id",
                                     "year",
                                     "pop",
                                     "median"),
                                 with=F]

      # create ratios by which to adjust RRs for morbidity for applicable causes (these are derived from literature values)
  # TODO, remove hardcoding of these values, should be pulled from a location to aid future changes
  if (cause.code == "cvd_ihd" & metric.type == "yld") {
    
    ratio <- 0.141
    
  } else if (cause.code == "cvd_stroke" & metric.type == "yld") {
    
    ratio <- 0.553
    
  } else {
    
    ratio <- 1
    
  }
  
  calib.draw.colnames <- c(paste0("draw_",1:function.draws))
  RR.draw.colnames <- c(paste0("RR_", 1:function.draws))
  
  # Generate the RRs using the evaluation function and then scale them using the predefined ratios
  RR.object[, c(RR.draw.colnames) := mclapply(1:function.draws,
                                              mc.cores = function.cores,
                                              function(draw.number) {
                                                
                                                ratio * fobject$eval(exposure.object[, calib.draw.colnames[draw.number], with=FALSE], 
                                                                     rr.curves[[age.cause.number]][draw.number, ]) - ratio + 1
                                                
                                              }
                                              
  )] # Use function object, the exposure, and the RR parameters to calculate PAF
  
  # generate PAFs at the country level using the grid-level RRs and population
  PAF.object <- mclapply(1:function.draws,
                         mc.cores = function.cores,
                         function(draw.number) {
                           
                           (sum((RR.object[,RR.draw.colnames[draw.number], with=FALSE] - 1) * exposure.object[,pop]) 
                            / 
                              sum(RR.object[,RR.draw.colnames[draw.number], with=FALSE] * exposure.object[,pop]))
                           
                         }
                         
  ) 
  
  # Set up variables
  PAF.object[function.draws + 1] <- cause.code
  PAF.object[function.draws + 2] <- as.numeric(age.code)
  
  rm(RR.object)
    #gc()
  
  return(PAF.object)

  
}

#********************************************************************************************************************************
arocPred <- function(dt,
                     this.grid,
                     pred.vars,
                     start.year,
                     end.year) {
  
  #cat("~",this.grid); flush.console() #toggle for troubleshooting/monitoring loop status
  
  pred.length <- (end.year - start.year) - 1
  pred.dt <- dt[grid==this.grid]
  
  forecast <- dt[grid==this.grid & year==start.year, -c("year", pred.vars), with=F]
  forecast <- forecast[rep(seq(.N), pred.length)]
  forecast[, "year" := (start.year+1):(end.year-1)]
  
  predictVar <- function(var, year) {
    
    #calculate the annualized rate of change from start.year to end.year
    rate.of.change <- -log(pred.dt[year==end.year, get(var)]/pred.dt[year==start.year, get(var)])/(end.year-start.year)
    pred.dt[year==start.year, get(var)] * exp(-rate.of.change * (year-start.year))
    
  }  
  
  forecast[, c(pred.vars) := lapply(pred.vars,
                                  predictVar,
                                  year = year),
           with=F]
  
  return(na.omit(forecast))
  
}

#********************************************************************************************************************************
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
                location_id + ihme_loc_id + x + y + perurban + year ~ var, #formula to cast over
                value.var="value") %>% as.data.table() #TODO BUG for some reason was converted to df after dcast, why?
  
  temp <- copy(RR.object)
  
  # create a grid ID variable, splines can only be done on a single grid at a time
  temp[, grid := as.numeric(as.factor(paste0(lat,long)))]
  
  # ensure that year is a numeric, after cast it is becoming character and it needs to be a number to be used in the extrapolation formula
  temp[, year := as.numeric(year)]

  #generate forecasts using your spline prediction function
  forecasts <- lapply(unique(temp$grid),
                      arocPred,
                      dt = temp,
                      pred.vars = RR.draw.colnames,
                      start.year = this.year,
                      end.year = that.year)
  
  #add the forecasts to the dt
  temp <- rbind(rbindlist(forecasts), #first use rbindlist to turn the output of lapply into a dt 
                temp) # there may be a better way to do this...
  
  #also return each country to a list in case we want to look at them interactively or do testing
  return(temp)
  
}  
#********************************************************************************************************************************
# calculate RRs due to air PM exposure using various methods and 
calculatePAFsAnnual <- function(age.cause.number,
                                exposure.object,
                                rr.curves,
                                metric.type,
                                function.draws=draws.required,
                                function.cores=1){
  
  # pull cause/age of interest from list defined by loop#
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  # display loop status
  if (year.cores == 1) message(paste0(metric.type, " - Cause:", cause.code, " - Age:", age.code))
  
  # Prep out datasets (only applies to first loop)
  
  PAF.object <- as.data.frame(matrix(as.integer(NA), nrow=nrow(age.cause), ncol=function.draws+2))
  RR.object <- exposure.object[, c("lat", # this should match the dimensions of your exposure object, i also included iso3/year/pop/raw exposure
                                   "long", # in case i later want to output this dataset, the above listed vars make it more useful
                                   "ihme_loc_id",
                                   "year",
                                   "pop",
                                   "median"),
                               with=F]
  
  # create ratios by which to adjust RRs for morbidity for applicable causes (these are derived from literature values)
  # TODO, remove hardcoding of these values, should be pulled from a location to aid future changes
  if (cause.code == "cvd_ihd" & metric.type == "yld") {
    
    ratio <- 0.141
    
  } else if (cause.code == "cvd_stroke" & metric.type == "yld") {
    
    ratio <- 0.553
    
  } else {
    
    ratio <- 1
    
  }
  
  calib.draw.colnames <- c(paste0("draw_",1:function.draws))
  RR.draw.colnames <- c(paste0("RR_", 1:function.draws))
  
  # Generate the RRs using the evaluation function and then scale them using the predefined ratios
  RR.object[, c(RR.draw.colnames) := mclapply(1:function.draws,
                                              mc.cores = function.cores,
                                              function(draw.number) {
                                                
                                                ratio * fobject$eval(exposure.object[, calib.draw.colnames[draw.number], with=FALSE], 
                                                                     rr.curves[[age.cause.number]][draw.number, ]) - ratio + 1
                                                
                                              }
                                              
  )] # Use function object, the exposure, and the RR parameters to calculate PAF
  
  # Now, interpolate RRs by grid if year is between 1990 and 2010 (other years already have )
  
  # generate PAFs at the country level using the grid-level RRs and population
  PAF.object <- mclapply(1:function.draws,
                         mc.cores = function.cores,
                         function(draw.number) {
                           
                           (sum((RR.object[,RR.draw.colnames[draw.number], with=FALSE] - 1) * exposure.object[,pop]) 
                            / 
                              sum(RR.object[,RR.draw.colnames[draw.number], with=FALSE] * exposure.object[,pop]))
                           
                         }
                         
  ) 
  
  # Set up variables
  PAF.object[function.draws + 1] <- cause.code
  PAF.object[function.draws + 2] <- as.numeric(age.code)
  
  rm(RR.object)
  #gc()
  
  return(PAF.object)
  
  
}
#********************************************************************************************************************************
# generalized post preparations and summary of draws
formatAndSummPAF <- function(PAF.output, 
                               metric.type,
                               ...) {
  
  ##purpose##
  #this function is used as a wrapper for some general formatting steps that need to be taken for both mortality and morbidity calculations
  #these steps include:
  #1: naming columns
  #2: summarization; need to generate means and CIs for review
  #3: order columns and final formatting of the summary file
  #4: expanding the dataset to match proper GBD age groups for each cause that does not have an age-specific PAF
  # further details on these steps can be found below
  
  ##inputs##
  #PAF.output = a list of PAFs calculated for each age/cause variation, this file is raw draws of the distribution and needs some final prepping/summarization
  #metric type (yll/yld) = selects the kind of analysis done for PAF.output. this is either yll (mortality) or yld (morbidity).
  
  ##outputs##
  #output.list = this is a list object that has two dataframes in it. the first is 1000 draws of the distribution, the second is a lite file with just mean/CI
  
  PAF.output <- do.call(rbind.data.frame, PAF.output) # the previous function created a list of lists
  # this command coerces that list to a simple dataframe
  
  #pafs must be saved in this stupid way (0-999 instead of 1-1000)
  PAF.draw.colnames <- c(paste0("paf_", 0:(draws.required-1)))
  
  names(PAF.output) <- c(PAF.draw.colnames, "cause", "age")
  
  # generate mean and CI for summary figures
  PAF.output <- as.data.table(PAF.output)
  PAF.output[,PAF_lower := quantile(.SD ,c(.025)), .SDcols=PAF.draw.colnames, by=list(cause,age)]
  PAF.output[,PAF_mean := rowMeans(.SD), .SDcols=PAF.draw.colnames, by=list(cause,age)]
  PAF.output[,PAF_upper := quantile(.SD ,c(.975)), .SDcols=PAF.draw.colnames, by=list(cause,age)]
  
  # create variable to store type
  PAF.output[, type := metric.type]
  
  #Order columns to your liking
  PAF.output <- setcolorder(PAF.output, c("cause", 
                                          "age",
                                          "type",
                                          "PAF_lower", 
                                          "PAF_mean", 
                                          "PAF_upper", 
                                          PAF.draw.colnames))
  
  # Save summary version of PAF output for experts 
  PAF.output.summary <- PAF.output[, c("age",
                                       "cause",
                                       "type",
                                       "PAF_lower",
                                       "PAF_mean",
                                       "PAF_upper"), 
                                   with=F]
  
  PAF.output <- lapply(unique(age.cause[,1]), expandAges, input.table = PAF.output) %>% rbindlist(use.names=T)
  
  output.list <- setNames(list(PAF.output, PAF.output.summary),  c("draws", "summary"))
  
  return(output.list)
  
}
#********************************************************************************************************************************
