# Greg Freedman
# Calculate Ambient Air Pollution PAFs
# Complete rewrite of J:\Project\GBD\RISK_FACTORS\Code\ambient_air_pollution\cluster\moredata\simulate_paf_by_age.r
# 2/24/2014

# source("/home/j/WORK/05_risk/01_database/02_data/air_pm/04_paf/04_models/code/01_calculate_paf.r", echo=T)

#####RUNTIME CONFIGURATION#####

# clear memory
 rm(list=ls())

if (Sys.info()["sysname"] == "Linux") {
  root <- "/home/j" 
  arg <- commandArgs()[-(1:3)]                  # First args are for unix use only
  #arg <- c("CHN_354", 2014, "power2", "gbd2010", "3", "adv_regress_draws2014_12_15.csv", 26, 100, 100, TRUE, TRUE, FALSE)
} else { 
  root <- "J:"
  arg <- c("DEU", 2013, "power2", "gbd2010", "3", "adv_regress_draws2014_12_15.csv", 27, 100, 5, TRUE, FALSE, FALSE)
}


library(data.table)

# Set parameters
country <- arg[1]
year <- arg[2]
rr.functional.form <- arg[3]
rr.version <- arg[4]
exp.grid.version <- arg[5]
exp.reg.version <- arg[6]
output.version <- arg[7]
draws.required <- as.numeric(arg[8])
scenario.pm <- arg[9]
write.exposure <- arg[10]
write.pafs <- arg[11]
write.rrs <- arg[12]


# set analytical options
if (year==2014) {
  
  analysis.year <- 2013 # for future scenarios, use 2013 as the comparison point to calcluate burden averted in case of scenario
  #calc.scenarios <- "relative" #this version of the scenario calculation estimates the ratio of scenario RR / current RR, effectively 
                                #calculating the burden averted by a change in scenarios
  calc.scenarios <- "absolute" #this version actually calculates the absolute burden when any grids over the scenario are set to scenario
                                #this version is currently preferred by Chris/Haidong for the ensuing life expectancy calculation
  write.exposure <- FALSE
  scenario.pm <- as.numeric(scenario.pm)
  scenario.pm.filename <- paste0("_scenario_", scenario.pm, "ug")
    
} else {
  
  analysis.year <- year # use current year to calculate air PM burden
  calc.scenarios <- "none"
  scenario.pm.filename <- NULL
  
}   

# quality control check
if (year != 2014 & scenario.pm != "NA") {
  
  stop("ERROR: FUTURE PM IS BEING PASSED ERRONEOUSLY TO PRESENT/PAST ANALYTICAL YEAR")
  
}

#store directories in objects
rr.dir <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/02_rr/04_models/output")

if (rr.version == "stan") {
  
  rr.functions <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/functional_forms_updated.r") # GBD 2013 version of RR (which uses Rstan) has a modified evaluation function which divides all parameters by 1e10 to avoid numbers that are too large for STAN to store in memory
  
} else {
  
  rr.functions <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/functional_forms.r") 
  
}

exp.grid.dir <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/01_exp/02_nonlit/03_temp/gridded")
exp.reg.dir <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/01_exp/04_models/results")
out.paf.dir <-  "/clustertmp/WORK/05_risk/03_outputs/02_results/air_pm"
out.exp.dir <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/01_exp/05_products/iso3_draws")
out.rr.dir <- paste0(root, "/WORK/2013/05_risk/01_database/02_data/air_pm/02_rr/05_products/")

# Prep directories to save outputs
# Prep directory to save exposure
dir.create(paste0(out.exp.dir,"/", output.version))
dir.create(paste0(out.exp.dir,"/", output.version, "/summary"))
dir.create(paste0(out.exp.dir,"/", output.version, "/draws"))
dir.create(paste0(out.exp.dir,"/", output.version, "/gridded"))

# Prep directory to save PAFs
dir.create(paste0(out.paf.dir,"/", output.version))
dir.create(paste0(out.paf.dir,"/", output.version, "/summary"))
dir.create(paste0(out.paf.dir,"/", output.version, "/draws"))

# Prep directory to save RRs
dir.create(paste0(out.rr.dir,"/", output.version))
dir.create(paste0(out.rr.dir, "/", output.version, "/summary"))
dir.create(paste0(out.rr.dir, "/", output.version, "/draws"))

#####FUNCTION LIBRARY#####

# find and replace values in your data (also gives you the option to change the variable name)
findAndReplace <- function(table, #data table that you want to replace values in
                           input.vector, # vector of the old values you want to replace
                           output.vector, # vector of the new values you want to replace them with
                           input.variable.name, # the current variable name
                           output.variable.name, # new variable name (same as previous if no change required)
                           expand.option=FALSE) { # set this option TRUE if you are doing a one:many replace (IE expanding rows)
  
  values <- input.vector
  new.values <- output.vector
  
  # Replacement data table
  replacement.table = data.table(variable = values, new.variable = new.values, key = "variable")
  
  # Replace the values (note the data table must be keyed on the value to replace)
  setkeyv(table, input.variable.name) #need to use setkeyv (verbose) in order to pass the varname this way
  table <- setnames(
    replacement.table[table, allow.cartesian=expand.option][is.na(new.variable), new.variable := variable][,variable := NULL],
    'new.variable',
    output.variable.name)
  
  return(table)
  
}    

#####PREP DATA####

# Make a list of all cause-age pairs that we have.
age.cause <- NULL
for (cause.code in c("cvd_ihd", "cvd_stroke", "neo_lung", "resp_copd", "lri")) {
  
  if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
    
    ages <- seq(25, 80, by=5) # CVD and Stroke have age specific results
    
  } else {
    
    ages <- c(99) # LRI, COPD and Lung Cancer all have a single age RR (though they reference different ages...)
    
  }
  
  for (age.code in ages) {
    
    age.cause <- rbind(age.cause, c(cause.code, age.code))
    
  }
}

# Bring in RR function and parameters
source(rr.functions)
fobject <- get(rr.functional.form)  

# Prep gridded exposure dataset
exp <- read.csv(paste0(exp.grid.dir, "/", exp.grid.version, "/", country, ".csv"))
exp <- exp[, c("whereami_id","year", "pop", "fus","o3","x","y")] # Don't need other variables for this analysis
colnames(exp) <- c("iso3","year", "pop", "fus","o3","x","y") #rename iso3 var 
exp <- exp[!is.na(exp$pop) & !is.na(exp$fus) & !is.infinite(exp$fus) & !is.infinite(exp$pop), ] # Get rid of missings and infinites
exp <- exp[exp$pop != 0, ] # Drop rows with 0 population, since they'll have a weight of 0 when aggregating.
exp[exp$fus <= 0, "fus"] <- 0.1 # Set fused values of 0 or smaller to be 0.1 (This will have a PAF of 0, so we don't wnat to drop.) 

# Prep exposure regression draws
all.regression.draws <- read.csv(paste0(exp.reg.dir, "/", exp.reg.version))
reg.draws <- data.table(all.regression.draws)

# Prep the RR curves into a single object, so that we can loop through different years without hitting the files extra times.
rr.curves <- list()
for (age.cause.number in 1:nrow(age.cause)) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  rr.curves[[paste0(cause.code, "_", age.code)]] <- read.csv(paste0(rr.dir, "/", rr.version, "/rr_curve_", rr.functional.form, "_", cause.code, "_a", age.code, ".csv"))
  
  rr.curves[[paste0(cause.code, "_", age.code)]]$draw <- NULL # Get rid of the draw numbers
  
  if (rr.version == "gbd2010") {
    
    rr.curves[[paste0(cause.code, "_", age.code)]] <- rr.curves[[paste0(cause.code, "_", age.code)]][-1, ] # Get rid of the point estimate row, created during the GBD2010 rr curve estimation process
    
  }
  
}

# Calculate PM2.5 exposure
# Set up this year's exposure.

# create a list of draw names based on the required number of draws for this run
calib.draw.colnames <- c(paste0("calib_",1:draws.required))

exposure.data <- data.table(exp[exp$year==analysis.year,]) #NEW METHOD

#NEW METHOD: calculate exposure using draws of the betas from the calibration regression and the exposure for each grid (updated method that maintains covariance properly and delivers a more accurate confidence interval)
exposure.data[, c(calib.draw.colnames) := lapply(1:draws.required, function(draw.number) {
  
  exp(reg.draws[draw.number, X.Intercept.] + log(fus) * reg.draws[draw.number, log.fused.])
  
}
)]

#####MORTALITY-PAFS####

# Prep out datasets
out.paf.mort <- as.data.frame(matrix(as.integer(NA), nrow=nrow(age.cause), ncol=draws.required+2)) 
RR.dataset.mort <- data.table(exp[exp$year==analysis.year,]) # toggle to save RRs for external review
RR.dataset.scenario <- data.table(exp[exp$year==analysis.year,]) # toggle to save RRs for external review (SCENARIO)
exposure.data.scenario <- exposure.data

# Loop through the various age cause groups and calculate relative risks (at the grid level) 
# then PAFs (population weighted and collapsed to country level) 

for (age.cause.number in 1:nrow(age.cause)) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  print(paste0("Cause:", cause.code,  " - Age:", age.code))
  
  RR.draw.colnames <- c(paste0("RR_", 1:draws.required))
  
  # Generate the RRs using the evaluation function    
  RR.dataset.mort[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
    
    fobject$eval(exposure.data[, calib.draw.colnames[draw.number], with=FALSE], rr.curves[[paste0(cause.code, "_", age.code)]][draw.number, ])
    
  }    
  )] # Use function object, the exposure, and the RR parameters to calculate PAF
  
if (calc.scenarios == "relative") {  
  
# SCENARIO: Generate the RRs using the evaluation function and a proposed future scenario value for PM2.5
  RR.dataset.scenario[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
    
    fobject$eval(scenario.pm, rr.curves[[paste0(cause.code, "_", age.code)]][draw.number, ])
    
  }    
  )] # Use function object, the exposure, and the RR parameters to calculate PAF  
  
  # Scale the RRs using the current working scenario (RRcurrent/RRscenario == RRratio, then use the RRratio to calculate the PAFs 
  # NOTE that if the scenario RR > current RR, RRratio is set automatically to be 1, as there can be no negative PAFs from a logical perspective)
  RR.dataset.mort[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
    
    ifelse(scenario.pm < exposure.data[, calib.draw.colnames[draw.number], with=FALSE],
           as.matrix(RR.dataset.mort[,RR.draw.colnames[draw.number], with=FALSE] / RR.dataset.scenario[,RR.draw.colnames[draw.number], with=FALSE]),
           1)
    
  }    
  )]

}
  
  if (calc.scenarios == "absolute") {    
    
    exposure.data.scenario[, c(calib.draw.colnames) := lapply(1:draws.required, function(draw.number) {
      
      
      ifelse(scenario.pm > exposure.data[, calib.draw.colnames[draw.number], with=FALSE],
             as.matrix(exposure.data[, calib.draw.colnames[draw.number], with=FALSE]),
             scenario.pm)
      
    }
    )]
    
    # Generate the RRs using the evaluation function    
    RR.dataset.mort[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
      
      fobject$eval(exposure.data.scenario[, calib.draw.colnames[draw.number], with=FALSE], rr.curves[[paste0(cause.code, "_", age.code)]][draw.number, ])
      
    }    
    )] # Use function object, the exposure, and the RR parameters to calculate PAF
    
  }
    
  if (write.rrs == TRUE) {
    
    # Toggle to create summary variables (takes a long time)
    RR.dataset.mort[,RR_lower := quantile(.SD ,c(.025)), .SDcols=RR.draw.colnames, by=list(x,y)]
    RR.dataset.mort[,RR_mean := rowMeans(.SD), .SDcols=RR.draw.colnames, by=list(x,y)]
    RR.dataset.mort[,RR_upper := quantile(.SD ,c(.975)), .SDcols=RR.draw.colnames, by=list(x,y)]
    
    # Order columns to your liking 
    RR.dataset.mort <- setcolorder(RR.dataset.mort, c("location_id", 
                                                      "whereami_id", 
                                                      "x", 
                                                      "y", 
                                                      "perurban", 
                                                      "year", 
                                                      "fus", 
                                                      "o3", 
                                                      "pop", 
                                                      "RR_lower", 
                                                      "RR_mean", 
                                                      "RR_upper", 
                                                      RR.draw.colnames))
    
    # Create summary version of RR
    RR.dataset.mort.summary <- RR.dataset.mort[, c("location_id", 
                                                   "whereami_id", 
                                                   "x", 
                                                   "y", 
                                                   "perurban", 
                                                   "year", 
                                                   "fus", 
                                                   "o3", 
                                                   "pop", 
                                                   "RR_lower", 
                                                   "RR_mean", 
                                                   "RR_upper"),
                                               with=F]    
    
    # Save RR dataset for external review
    write.csv(RR.dataset.mort, paste0(out.rr.dir, "/", output.version, "/draws/yld_", country, "_", year, "_", cause.code, "_", age.code, ".csv"))
    write.csv(RR.dataset.mort.summary, paste0(out.rr.dir, "/", output.version, "/summary/yld_", country, "_", year, "_", cause.code, "_", age.code, ".csv"))    
    
  }
  
  # generate PAFs at the country level using the grid-level RRs and population
  out.paf.mort[age.cause.number,] <- lapply(1:draws.required, function(draw.number) {
    
    sum((RR.dataset.mort[,RR.draw.colnames[draw.number], with=FALSE] - 1)*exposure.data[,pop]) / sum(RR.dataset.mort[,RR.draw.colnames[draw.number], with=FALSE] * exposure.data[,pop])
    
  }
  )  # new aggregation formula created by Mehrdad to address the issue that population at the grid level doesn't necessarily reflect the number of cases at a grid level
  
  # Set up variables
  out.paf.mort[age.cause.number, draws.required + 1] <- cause.code
  out.paf.mort[age.cause.number, draws.required + 2] <- as.numeric(age.code)
  
}

names(out.paf.mort) <- c(paste0("draw_yll_", 1:draws.required), "cause", "age")

# create a list of draw names based on the required number of draws for this run
paf.draw.colnames <- c(paste0("draw_yll_", 1:draws.required))


# generate mean and CI for summary figures
out.paf.mort <- as.data.table(out.paf.mort)
out.paf.mort[,paf_yll_lower := quantile(.SD ,c(.025)), .SDcols=paf.draw.colnames, by=list(cause,age)]
out.paf.mort[,paf_yll_mean := rowMeans(.SD), .SDcols=paf.draw.colnames, by=list(cause,age)]
out.paf.mort[,paf_yll_upper := quantile(.SD ,c(.975)), .SDcols=paf.draw.colnames, by=list(cause,age)]

#Order columns to your liking
out.paf.mort <- setcolorder(out.paf.mort, c("cause", 
                                            "age", 
                                            "paf_yll_lower", 
                                            "paf_yll_mean", 
                                            "paf_yll_upper", 
                                            paf.draw.colnames))

# Create summary version of PAF output for experts 
out.paf.mort.summary <- out.paf.mort[, c("age", 
                                         "cause", 
                                         "paf_yll_lower", 
                                         "paf_yll_mean", 
                                         "paf_yll_upper"), 
                                     with=F]

# Convert from age 99 to the correct ages
# LRI is between 0 and 5
for (cause.code in c("lri", "neo_lung", "resp_copd")) {
  
  # Take out this cause
  temp.paf <- out.paf.mort[out.paf.mort$cause == cause.code, ]
  out.paf.mort <- out.paf.mort[!out.paf.mort$cause == cause.code, ]  	
  
  # Add back in with proper ages
  if (cause.code == "lri") ages <- c(0, 0.01, 0.1, 1, seq(5, 80, by=5)) # LRI is between 0 and 5 # LRI is now being calculated for all ages based off the input data for LRI and smokers
  if (cause.code %in% c("neo_lung", "resp_copd")) ages <- seq(25, 80, by=5) # others are between 25 and 80
  
  for (age.code in ages) {
    
    temp.paf$age <- age.code
    out.paf.mort <- rbind(out.paf.mort, temp.paf)
    
  }
}

# Save Mortality PAFs/RRs
# Mortality is the same as the PAFs calculated.
if (write.pafs == TRUE) {
  
  write.csv(out.paf.mort.summary, paste0(out.paf.dir, "/", output.version, "/summary/paf_yll_", country, "_", year, scenario.pm.filename, ".csv"))  
  write.csv(out.paf.mort, paste0(out.paf.dir, "/", output.version, "/draws/paf_yll_", country, "_", year, scenario.pm.filename, ".csv"))
  
}

#####MORBIDITY-PAFS####

# Prep out datasets - Morbidity
out.paf.morb <- as.data.frame(matrix(as.integer(NA), nrow=nrow(age.cause), ncol=draws.required+2))
RR.dataset.morb <- data.table(exp[exp$year==analysis.year,]) # toggle to save RRs for external review
  
# Loop through the various age cause groups and calculate relative risks (at the grid level) 
# then PAFs (population weighted and collapsed to country level) 

for (age.cause.number in 1:nrow(age.cause)) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  print(paste0("Cause:", cause.code, " - Age:", age.code))
  
  # create ratios by which to adjust RRs for morbidity for applicable causes (these are derived from literature values) NOTE ERROR, CVD_IHD ratios are not being applied correctly, must correct this for GBD 2014
  if (cause.code == "cvd_ihd") {
    
    ratio <- 0.141
    
  } else if (cause.code == "cvd_stroke") {
    
    
    ratio <- 0.553
    
  } else {
    
    ratio <- 1
    
  }
  
  RR.draw.colnames <- c(paste0("RR_", 1:draws.required))
  
  # Generate the RRs using the evaluation function and then scale them using the predefined ratios
  RR.dataset.morb[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
    
    ratio * fobject$eval(exposure.data[, calib.draw.colnames[draw.number], with=FALSE], rr.curves[[paste0(cause.code, "_", age.code)]][draw.number, ]) - ratio + 1
    
  }
  
  )] # Use function object, the exposure, and the RR parameters to calculate PAF 
  
  if (calc.scenarios == "relative") {  
    
    # SCENARIO: Generate the RRs using the evaluation function and a proposed future scenario value for PM2.5, then scale them using the predefined ratios
    RR.dataset.scenario[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
      
      ratio * fobject$eval(scenario.pm, rr.curves[[paste0(cause.code, "_", age.code)]][draw.number, ]) - ratio + 1
      
    }    
    )] # Use function object, the exposure, and the RR parameters to calculate PAF  
    
    # Scale the RRs using the current working scenario (RRcurrent/RRscenario == RRratio, then use the RRratio to calculate the PAFs 
    # NOTE that if the scenario RR > current RR, RRratio is set automatically to be 1, as there can be no negative PAFs from a logical perspective)
    RR.dataset.morb[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
      
      ifelse(scenario.pm < exposure.data[, calib.draw.colnames[draw.number], with=FALSE],
             as.matrix(RR.dataset.morb[,RR.draw.colnames[draw.number], with=FALSE] / RR.dataset.scenario[,RR.draw.colnames[draw.number], with=FALSE]),
             1)
      
    }    
    )]
    
  }
  
  if (calc.scenarios == "absolute") {    
    
    exposure.data.scenario[, c(calib.draw.colnames) := lapply(1:draws.required, function(draw.number) {
      
      
      ifelse(scenario.pm > exposure.data[, calib.draw.colnames[draw.number], with=FALSE],
             as.matrix(exposure.data[, calib.draw.colnames[draw.number], with=FALSE]),
             scenario.pm)
      
    }
    )]
    
    # Generate the RRs using the evaluation function    
    RR.dataset.mort[, c(RR.draw.colnames) := lapply(1:draws.required, function(draw.number) {
      
      fobject$eval(exposure.data.scenario[, calib.draw.colnames[draw.number], with=FALSE], rr.curves[[paste0(cause.code, "_", age.code)]][draw.number, ])
      
    }    
    )] # Use function object, the exposure, and the RR parameters to calculate PAF
    
  }  
  
  if (write.rrs == TRUE) {
    
    # Toggle to create summary variables (takes a long time)
    RR.dataset.morb[,RR_lower := quantile(.SD ,c(.025)), .SDcols=RR.draw.colnames, by=list(x,y)]
    RR.dataset.morb[,RR_mean := rowMeans(.SD), .SDcols=RR.draw.colnames, by=list(x,y)]
    RR.dataset.morb[,RR_upper := quantile(.SD ,c(.975)), .SDcols=RR.draw.colnames, by=list(x,y)]
    
    # Order columns to your liking 
    RR.dataset.morb <- setcolorder(RR.dataset.morb, c("location_id", 
                                                      "whereami_id", 
                                                      "x", 
                                                      "y", 
                                                      "perurban", 
                                                      "year", 
                                                      "fus", 
                                                      "o3", 
                                                      "pop", 
                                                      "RR_lower", 
                                                      "RR_mean", 
                                                      "RR_upper", 
                                                      RR.draw.colnames))
    
    # Create summary version of RR
    RR.dataset.morb.summary <- RR.dataset.morb[, c("location_id", 
                                                   "whereami_id", 
                                                   "x", 
                                                   "y", 
                                                   "perurban", 
                                                   "year", 
                                                   "fus", 
                                                   "o3", 
                                                   "pop", 
                                                   "RR_lower", 
                                                   "RR_mean", 
                                                   "RR_upper"),
                                               with=F]    
    
    # Save RR dataset for external review
    write.csv(RR.dataset.morb, paste0(out.rr.dir, "/", output.version, "/draws/yld_", country, "_", year, "_", cause.code, "_", age.code, ".csv"))
    write.csv(RR.dataset.morb.summary, paste0(out.rr.dir, "/", output.version, "/summary/yld_", country, "_", year, "_", cause.code, "_", age.code, ".csv"))    
    
  }    
  # generate PAFs at the country level using the grid-level RRs and population
  out.paf.morb[age.cause.number,] <- lapply(1:draws.required, function(draw.number) {
    
    sum((RR.dataset.morb[,RR.draw.colnames[draw.number], with=FALSE] - 1)*exposure.data[,pop]) / sum(RR.dataset.morb[,RR.draw.colnames[draw.number], with=FALSE] * exposure.data[,pop])
    
  }
  )  # new aggregation formula created by Mehrdad to address the issue that population at the grid level doesn't necessarily reflect the number of cases at a grid level
  
  # Set up variables
  out.paf.morb[age.cause.number, draws.required + 1] <- cause.code
  out.paf.morb[age.cause.number, draws.required + 2] <- as.numeric(age.code)
  
}

names(out.paf.morb) <- c(paste0("draw_yld_", 1:draws.required), "cause", "age")

paf.draw.colnames <- c(paste0("draw_yld_",1:draws.required))

# generate mean and CI for summary figures
out.paf.morb <- as.data.table(out.paf.morb)
out.paf.morb[,paf_yld_lower := quantile(.SD ,c(.025)), .SDcols=paf.draw.colnames, by=list(cause,age)]
out.paf.morb[,paf_yld_mean := rowMeans(.SD), .SDcols=paf.draw.colnames, by=list(cause,age)]
out.paf.morb[,paf_yld_upper := quantile(.SD ,c(.975)), .SDcols=paf.draw.colnames, by=list(cause,age)]

#Order columns to your liking
out.paf.morb <- setcolorder(out.paf.morb, c("cause", 
                                            "age", 
                                            "paf_yld_lower", 
                                            "paf_yld_mean", 
                                            "paf_yld_upper", 
                                            paf.draw.colnames))

# Save summary version of PAF output for experts 
out.paf.morb.summary <- out.paf.morb[, c("age",
                                         "cause",
                                         "paf_yld_lower",
                                         "paf_yld_mean",
                                         "paf_yld_upper"), 
                                     with=F]

# Convert from age 99 to the correct ages
# LRI is between 0 and 5
for (cause.code in c("lri", "neo_lung", "resp_copd")) {
  
  # Take out this cause
  temp.paf <- out.paf.morb[out.paf.morb$cause == cause.code, ]
  out.paf.morb <- out.paf.morb[!out.paf.morb$cause == cause.code, ]  	
  
  # Add back in with proper ages
  if (cause.code == "lri") ages <- c(0, 0.01, 0.1, 1, seq(5, 80, by=5)) # LRI is between 0 and 5 # LRI is now being calculated for all ages based off the input data for LRI and smokers
  if (cause.code %in% c("neo_lung", "resp_copd")) ages <- seq(25, 80, by=5) # others are between 25 and 80
  
  for (age.code in ages) {
    
    temp.paf$age <- age.code
    out.paf.morb <- rbind(out.paf.morb, temp.paf)
    
  }
}    

#   Save Morbidity PAFs
if (write.pafs == TRUE) {
  
  write.csv(out.paf.morb.summary, paste0(out.paf.dir, "/", output.version, "/summary/paf_yld_", country, "_", year, scenario.pm.filename, ".csv"))
  write.csv(out.paf.morb, paste0(out.paf.dir, "/", output.version, "/draws/paf_yld_", country, "_", year, scenario.pm.filename, ".csv"))
  
  # Combine and format both types of PAFs to prep for a run through the DALYnator
  out.paf <- merge(out.paf.mort,out.paf.morb,by=c("cause","age"))
  out.paf$iso3 <- country
  out.paf$year <- year
  out.paf$acause <- out.paf$cause
  out.paf$risk <- "air_pm"
  out.paf <- out.paf[, c("risk",
                         "age",
                         "iso3",
                         "year",
                         "acause",
                         paste0("draw_yll_",1:draws.required),
                         paste0("draw_yld_",1:draws.required)),
                     with=F]
  
  # expand cvd_stroke to include relevant subcauses in order to prep for merge to YLDs, using your custom find/replace function
  # first supply the values you want to find/replace as vectors
  old.causes <- c('cvd_stroke')   
  replacement.causes <- c('cvd_stroke_cerhem', 
                          "cvd_stroke_isch")
  
  # then pass to your custom function
  out.paf <- findAndReplace(out.paf,
                            old.causes,
                            replacement.causes,
                            "acause",
                            "acause",
                            TRUE) #set this option to be true so that rows can be duplicated in the table join (expanding the rows) 
  
  write.csv(out.paf, paste0(out.paf.dir, "/", output.version, "/draws/", country, "_", year, scenario.pm.filename, ".csv"))
  
}

#####EXPOSURE####

# Save average PM2.5 at the country level
# Prep datasets
out.exp <- rep(NA, draws.required)
out.exp.summary <- as.data.frame(matrix(as.integer(NA), nrow=1, ncol=3))

# calculate population weighted draws
out.exp <- sapply(1:draws.required, function(draw.number) weighted.mean(exposure.data[[calib.draw.colnames[draw.number]]], exposure.data[,pop]))

# calculate mean and CI for summary figures
out.exp.summary[,1] <- quantile(out.exp, .025)
out.exp.summary[,2] <- mean(out.exp)
out.exp.summary[,3] <- quantile(out.exp, .975)
names(out.exp.summary) <- c("exposure_lower","exposure_mean","exposure_upper")

# Also save the mean/CI of gridded PM2.5
# generate mean and CI for summary figures
exposure.data[,exp_lower := quantile(.SD ,c(.025)), .SDcols=calib.draw.colnames, by=list(x,y,year)]
exposure.data[,exp_mean := rowMeans(.SD), .SDcols=calib.draw.colnames, by=list(x,y,year)]
exposure.data[,exp_upper := quantile(.SD ,c(.975)), .SDcols=calib.draw.colnames, by=list(x,y,year)]

#Order columns to your liking
exposure.data <- setcolorder(exposure.data, c("iso3", 
                                        "year",
                                        "x",
                                        "y",
                                        "pop",
                                        "fus",
                                        "o3",
                                        "exp_lower", 
                                        "exp_mean", 
                                        "exp_upper", 
                                        calib.draw.colnames))

# Save summary version of PAF output for experts 
gridded.exp.summary <- exposure.data[, c("iso3", 
                                          "year",
                                          "x",
                                          "y",
                                          "pop",
                                          "exp_lower", 
                                          "exp_mean", 
                                          "exp_upper"), 
                                 with=F]

if (write.exposure == TRUE) {
  
  write.csv(out.exp, paste0(out.exp.dir, "/", output.version, "/draws/", country, "_", year, ".csv"))
  write.csv(out.exp.summary, paste0(out.exp.dir, "/", output.version, "/summary/", country, "_", year, ".csv"))
  write.csv(gridded.exp.summary, paste0(out.exp.dir, "/", output.version, "/gridded/", country, "_", year, ".csv"))
  
}

#####IMPUTE MISSING COUNTRIES (MHL <- Copy of SLB // MDV <- Copy of SYC)####

#MORTALITY/MORBIDITY
if (write.pafs == TRUE & country == "SLB") { # Marshall Islands will be imputed as Solomon Islands, because it is missing in the satellite dataset
  
  out.paf.morb$iso3 <- "MHL"
  out.paf.mort$iso3 <- "MHL"
 
  write.csv(out.paf.morb.summary, paste0(out.paf.dir, "/", output.version, "/summary/paf_yll_MHL_", year, scenario.pm.filename, ".csv"))  
  write.csv(out.paf.morb, paste0(out.paf.dir, "/", output.version, "/draws/paf_yll_MHL_", year, scenario.pm.filename, ".csv"))  
  write.csv(out.paf.mort.summary, paste0(out.paf.dir, "/", output.version, "/summary/paf_yll_MHL_", year, scenario.pm.filename, ".csv"))  
  write.csv(out.paf.mort, paste0(out.paf.dir, "/", output.version, "/draws/paf_yll_MHL_", year, scenario.pm.filename, ".csv"))
  print("FINISHED SUCCESSFULLY, IMPUTED COPY OF RESULTS AS MARSHALL ISLANDS (PAF)")
    
} else if (write.pafs == TRUE & country == "SYC") { # The Maldives will be imputed as Seychelles, because it is missing in the satellite dataset
  
  out.paf.morb$iso3 <- "MDV"
  out.paf.mort$iso3 <- "MDV"
  
  write.csv(out.paf.morb.summary, paste0(out.paf.dir, "/", output.version, "/summary/paf_yll_MDV_", year, scenario.pm.filename, ".csv"))  
  write.csv(out.paf.morb, paste0(out.paf.dir, "/", output.version, "/draws/paf_yll_MDV_", year, scenario.pm.filename, ".csv"))
  write.csv(out.paf.mort.summary, paste0(out.paf.dir, "/", output.version, "/summary/paf_yll_MDV_", year, scenario.pm.filename, ".csv"))  
  write.csv(out.paf.mort, paste0(out.paf.dir, "/", output.version, "/draws/paf_yll_MDV_", year, scenario.pm.filename, ".csv"))
  print("FINISHED SUCCESSFULLY, IMPUTED COPY OF RESULTS AS MALDIVES (PAF)")
  
} else {
    
    print("FINISHED SUCCESSFULLY, NO PAF IMPUTATION NECESSARY")
    
  }  
  
#EXPOSURE  
  
if (write.exposure == TRUE & country == "SLB") {
  
  write.csv(out.exp, paste0(out.exp.dir, "/", output.version, "/draws/MHL_", year, ".csv"))
  write.csv(out.exp.summary, paste0(out.exp.dir, "/", output.version, "/summary/MHL_", year, ".csv"))
  print("FINISHED SUCCESSFULLY, IMPUTED COPY OF RESULTS AS MARSHALL ISLANDS (EXP)")
  
} else if (write.exposure == TRUE & country == "SYC") {
  
  write.csv(out.exp, paste0(out.exp.dir, "/", output.version, "/draws/MDV_", year, ".csv"))
  write.csv(out.exp.summary, paste0(out.exp.dir, "/", output.version, "/summary/MDV_", year, ".csv"))
  print("FINISHED SUCCESSFULLY, IMPUTED COPY OF RESULTS AS MALDIVES (EXP)")  
  
} else {
  
  print("FINISHED SUCCESSFULLY, NO EXP IMPUTATION NECESSARY")
  
}


######SCRAP CODE######

# this.exp <- exp[exp$year==analysis.year,] #OLD METHOD
# this.exp[, calib.draw.colnames] <- exp(reg.draws$X.Intercept. + outer(log(this.exp$fus), reg.draws$log.fused.)) #OLD METHOD: toggle if using advanced regression (this is an old way of calculating the calibrated exposure, I have determined that it applies the x.intercepts incorrectly and therefore does not take covariance into account correctly. this leads to inaccurate confidence intervals. For now we are sticking with this method to maintain consistence, fix it in the future)
# exposure.data <- data.table(this.exp) #OLD METHOD

# out.burden.dir <- "/homes/jfrostad/air_pm/CHN/attributable_burden"
# 
# # Prep directory to save burden
# dir.create(paste0(out.burden.dir,"/", output.version))
# dir.create(paste0(out.burden.dir,"/", output.version, "/summary"))
# dir.create(paste0(out.burden.dir,"/", output.version, "/draws"))

# # Bring in and prep country disease burden files
# deaths.dir <- paste0(root, "/Project/COAL/data/deaths") # this is a place where I have prepped and saved CHN deaths for another project, eventually save this in a more logical place or better yet create a database pull for it
# ylds.dir <- paste0(root, "/Project/COAL/data/epi") # this is a place where I have prepped and saved CHN deaths for another project, eventually save this in a more logical place or better yet create a database pull for it
# country.deaths <- fread(paste0(deaths.dir,"/CHN_deaths_compiled.csv"))
# country.deaths$cause <- country.deaths$acause #change to match your variable naming structure (potentially revisit to reduce complexity)
# country.ylds <-fread(paste0(ylds.dir,"/CHN_ylds_compiled.csv"))
# country.ylds$cause <- country.ylds$acause #change to match your variable naming structure (potentially revisit to reduce complexity)
