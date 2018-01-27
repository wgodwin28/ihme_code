#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 03/24/2016
# Project: RF: HAP
# Purpose: Miscellaneous helper functions related to household air pollution RR calculation
# source("/homes/wgodwin/risk_factors/jfrostad/air_hap/rr/_lib/misc.R", echo=T)
#***********************************************************************************************************************

#----LIBRARY------------------------------------------------------------------------------------------------------------
# load packages necessary
#pacman::p_load()

# this function gives all the age.cause pairs currently used
# it assumes the full age range, but if you set that opt to F, it will return a lite version
ageCauseLister <- function(cause.code = c("cvd_ihd", "cvd_stroke", "neo_lung", "resp_copd", "lri"),
                           full.age.range = T) {
  
  age.cause <- NULL
  
  for (cause.code in c("cvd_ihd", "cvd_stroke", "neo_lung", "resp_copd", "lri")) {
    
    if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
      
      # CVD and Stroke have age specific results
      ages <- c(25, 50, 80) 
      all.ages <- seq(25, 95, by=5) # CVD and Stroke have age specific results
      
    } else {
      
      # LRI, COPD and Lung Cancer all have a single age RR (though they reference different ages...)
      ages <- c(99) 
      all.ages <- c(99)
    }
    
    if (full.age.range == T) ages <- all.ages
    
    for (age.code in ages) {
      
      age.cause <- rbind(age.cause, c(cause.code, age.code))
      
    }
  }
  
  return(age.cause)
  
}

# this function takes PAFs or RRs that are not age-specific and expands them to the appropriate ages so that they can be merged onto burden
expandAges <- function(input.table, cause.code) {  
  
  # Take out this cause
  temp <- input.table[cause == cause.code, ]
  
  if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
    
    temp[, age_group_id := age]
    
    # switch the ages from age_code to new age_group_id
    age.codes <- seq(25, 95, by=5) 
    age.ids <- c(10:20, 30:32, 235)
    
    # then pass to your custom function
    temp <- findAndReplace(temp,
                           age.codes,
                           age.ids,
                           "age_group_id",
                           "age_group_id")
    
  } else {
    
    # Add back in with proper ages
    if (cause.code == "lri") age.ids <- c(2:20, 30:32, 235) # LRI is now being calculated for all ages based off the input data for LRI and smokers
    if (cause.code == "otitis") age.ids <- c(2:7)  # otitis is between 0 and 15 (decided to increase it from <9 after looking @ meta input studies)
    if (cause.code %in% c("neo_lung", "resp_copd", "neo_breast", "neo_colorectal", "tb", 
                          "diabetes")) age.ids <- c(10:20, 30:32, 235) # others are between 25 and 80
    
    temp <- lapply(age.ids, function(age.id) temp[, age_group_id := age.id] %>% copy) %>% rbindlist  
    
  }  
  
  return(temp)
  
}

#********************************************************************************************************************************
# calculate RRs due to PM exposure 
# currently this is only used for HAP IER curving
calculateRRs <- function(age.cause.number,
                         exposure.object,
                         metric.type,
                         sex.specific,
                         function.cores,
                         draws.required) {
  
  # pull cause/age of interest from list defined by loop
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  print(function.cores)
  
  # create ratios by which to adjust RRs for morbidity for applicable causes (these are derived from literature values) NOTE ERROR, CVD_IHD ratios are not being applied correctly, must correct this for GBD 2014
  if (cause.code == "cvd_ihd" & metric.type == "yld") {
    
    ratio <- 0.141
    
  } else if (cause.code == "cvd_stroke" & metric.type == "yld") {
    
    ratio <- 0.553
    
  } else {
    
    ratio <- 1
    
  }
  
  if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
    sexes <- c(1,2)
  } else {
    sexes <- c(1,2,3)
  }
  
  sexLoop <- function(sex.code) {
    
    if (sex.code == 1 & sex.specific == T) {
      
      exposure <- exposure.object[sex=="men"] # male exposure -> taken from Astha
      
    } else if (sex.code == 2 & sex.specific == T) {
      
      exposure <- exposure.object[sex=="women"]  # female exposure -> taken from Astha
      
    } else if (sex.code == 3 & sex.specific == T) {
      
      exposure <- exposure.object[sex=="child"] # child exposure -> taken from average of IAP LRI PM concentrations for the input dataset
      
    } else {exposure <- exposure.object}
    
    # display loop status
    print(paste0("Cause:", cause.code, " - Age:", age.code, " - Sex:", sex.code))
    # Generate the RRs using the evaluation function and then scale them using the predefined ratios
    RR.object <- mclapply(1:draws.required,
                          mc.cores = function.cores,
                          function(draw.number) {
                            
                            ratio * fobject$eval(as.numeric(exposure[draw==draw.number, exposure]), 
                                                 all.rr[[age.cause.number]][draw.number, ]) - ratio + 1
                            
                          }
                          
    ) %>% as.data.table # Use function object, the exposure, and the RR parameters to calculate PAF 
    
    # Set up variables
    RR.object[, cause := cause.code]
    RR.object[, age := age.code]
    RR.object[, sex := sex.code]

    return(RR.object)
    
  }
  print(sexes)
  all.sex <- lapply(sexes, sexLoop) %>% rbindlist
  print("success sex loop")
  
  return(all.sex)
  
}

#********************************************************************************************************************************
# generalized post preparations and summary of draws - currently only used for HAP
formatAndSummRR <- function(RR.output, 
                            metric.type,
                            draws.required,
                            year) {
  
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
  
  RR.draw.colnames <- c(paste0("draw_", metric.type, "_", 1:draws.required))
  setnames(RR.output, paste0("V", 1:1000), RR.draw.colnames)
  RR.output <- RR.output[, year_id := year]
  # generate mean and CI for summary figures
  RR.output[,RR_lower := apply(.SD, 1, quantile, probs=.025), .SDcols=RR.draw.colnames]
  RR.output[,RR_mean := rowMeans(.SD), .SDcols=RR.draw.colnames]
  RR.output[,RR_upper := apply(.SD, 1, quantile, probs=.975), .SDcols=RR.draw.colnames]
  
  #Order columns to your liking
  RR.output <- setcolorder(RR.output, c("cause", 
                                        "age",
                                        "sex",
                                        "year_id",
                                        "RR_lower", 
                                        "RR_mean", 
                                        "RR_upper", 
                                        RR.draw.colnames))
  
  # Save summary version of RR output for experts 
  RR.output.summary <- RR.output[, c("age",
                                     "cause",
                                     "sex",
                                     "year_id",
                                     "RR_lower",
                                     "RR_mean",
                                     "RR_upper"), 
                                 with=F]
  
  # create lite version for graphing distributions
  RR.output.lite <- RR.output[age == 25 | age == 80 | age == 99]
  
  # Convert from age 99 to the correct ages
  # LRI is between 0 and 5
  for (cause.code in c("lri", "neo_lung", "resp_copd")) {
    
    # Take out this cause
    temp.RR <- RR.output[RR.output$cause == cause.code, ]
    RR.output <- RR.output[!RR.output$cause == cause.code, ]    
    
    # Add back in with proper ages
    if (cause.code == "lri") ages <- c(0, 0.01, 0.1, 1, seq(5, 95, by=5)) # LRI is between 0 and 5 # LRI is now being calculated for all ages based off the input data for LRI and smokers
    if (cause.code %in% c("neo_lung", "resp_copd")) ages <- seq(25, 95, by=5) # others are between 25 and 80
    
    for (age.code in ages) {
      
      temp.RR$age <- age.code
      RR.output <- rbind(RR.output, temp.RR)
      
    }
  }
  
  output.list <- setNames(list(RR.output, RR.output.summary, RR.output.lite),  c("draws", "summary", "lite"))
  
  return(output.list)
  
}
#********************************************************************************************************************************