#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 07/10/2015
# Purpose: Execute parallelized calculation of country/year RRs for HAP 
# Notes: Uses country/year HAP exposure from Astha and the IER curve
# source("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/01_gen_RR_hap.R", echo=T)
#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration

if (Sys.info()["sysname"] == "Linux") {
  root <- "/home/j" 
  arg <- commandArgs()[-(1:3)]                  # First args are for unix use only
} else { 
  root <- "J:"
  arg <- c("GTM", "2000", "12", "stan", "power2", 100, 1, "HAP")
}

this.country <- arg[1]
this.year <- arg[2]
rr.version <- arg[3]
ier.curve.version <- arg[4]
functional.form <- arg[5]
draws.required <- as.numeric(arg[6])
cores.provided <- as.numeric(arg[7])

# r configuration
options(scipen=10) # disable scientific notation because it annoys me, set to display ten digits

#other functions in lib
library(data.table)
library(stringr)
library(reshape2)
library(parallel)
#******************************************************************************************************************************** 
  
functions.file <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/functional_forms_updated.r")
ier.curve.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/output")
rr.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_hap/02_rr/04_models/output")
# custom functions
function.library <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/lib/functions")

# Get the function object from the functions file. This will provide information about the functional
# form that we are estimating, like the formula, parameters, and initializing values.
source(functions.file)
fobject <- get(functional.form)	

# Bring in RR calculation/formatting functions
source(paste0(function.library, "/analysis.R"))

# additional code, make some household air pollution relative risks for astha

  # LOAD IN THE CLEAN ENVIRONMENT HERE, THEN SUBSET TO COUNTRY/YEAR

  data.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/data")
  out.environment <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/data/prepped/clean.Rdata")
  #objects imported:
  #HAP.global.exp = file created by Astha containing PM2.5 exposure estimates for all country 
  #rr.curves - compiled list of all the RR curves for the ages/causes of interest
  load(out.environment)

  HAP.country.exp <- HAP.global.exp[iso3==this.country & year==this.year]

  
age.cause.sex <- NULL

for (cause.code in c("cvd_ihd", "cvd_stroke", "lri")) {
  if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
    ages <- seq(25, 80, by=5) # CVD and Stroke have age specific results
    sexes <- c(1,2)
  } else {
    ages <- c(99) # LRI, COPD and Lung Cancer all have a single age RR (though they reference different ages...)
    sexes <- c(1,2,3)
  }
  
  for (sex.code in sexes) {
    for (age.code in ages) {
      age.cause.sex <- rbind(age.cause.sex, c(cause.code, age.code, sex.code))
    }
  }
}

# Calculate Mortality PAFS using custom function
RR.mort <- mclapply(1:nrow(age.cause.sex), 
                         FUN=calculateRRs, 
                         exposure.object = HAP.country.exp, 
                         metric.type = "yll",
                         sex.specific = T,
                         function.cores = 1,
                         draws.required = draws.required,
                         mc.cores = cores.provided)

# Call to a custom function to do some final formatting and generate a lite summary file with mean/CI
mortality.outputs <- formatAndSummarize(RR.mort, "yll", draws.required)

# Save Mortality PAFs/RRs
write.csv(mortality.outputs[["summary"]], paste0(rr.dir, "/", rr.version, "/summary/yll_", this.country, "_", this.year, ".csv")) 
write.csv(mortality.outputs[["lite"]], paste0(rr.dir, "/", rr.version, "/lite/yll_", this.country,"_",this.year,".csv"))
write.csv(mortality.outputs[["draws"]], paste0(rr.dir, "/", rr.version, "/yll_", this.country,"_",this.year,".csv"))

# Calculate Morbidity PAFS using custom function
RR.morb <- mclapply(1:nrow(age.cause.sex), 
                    FUN=calculateRRs, 
                    exposure.object = HAP.country.exp, 
                    metric.type = "yld", 
                    sex.specific = T,
                    function.cores = 1,
                    draws.required = draws.required,
                    mc.cores = cores.provided)

# Call to a custom function to do some final formatting and generate a lite summary file with mean/CI
morbidity.outputs <- formatAndSummarize(RR.morb, "yll", draws.required)

# Save Mortality PAFs/RRs
write.csv(morbidity.outputs[["summary"]], paste0(rr.dir, "/", rr.version, "/summary/yld_", this.country, "_", this.year, ".csv")) 
write.csv(morbidity.outputs[["lite"]], paste0(rr.dir, "/", rr.version, "/lite/yld_", this.country,"_",this.year,".csv"))
write.csv(morbidity.outputs[["draws"]], paste0(rr.dir, "/", rr.version, "/yld_", this.country,"_",this.year,".csv"))

#----SCRAPS----------------------------------------------------------------------------------------------------------------------
# periodically copy over into scrap.R as your hoarding allows
#********************************************************************************************************************************  

# # create a list of draw names based on the required number of draws for this run
# RR.draw.colnames <- c(paste0("draw_", 0:999))
# 
# # generate mean and CI for summary hap.RR.summary
# hap.RR <- as.data.table(hap.RR)
# hap.RR[,draw_yll_lower := quantile(.SD ,c(.025)), .SDcols=RR.draw.colnames, by=list(acause,age,sex)]
# hap.RR[,draw_yll_mean := rowMeans(.SD), .SDcols=RR.draw.colnames, by=list(acause,age,sex)]
# hap.RR[,draw_yll_upper := quantile(.SD ,c(.975)), .SDcols=RR.draw.colnames, by=list(acause,age,sex)]
# 
# #Order columns to your liking
# hap.RR <- setcolorder(hap.RR, c("acause", 
#                                 "age",
#                                 "sex",
#                                 "draw_yll_lower", 
#                                 "draw_yll_mean", 
#                                 "draw_yll_upper", 
#                                 RR.draw.colnames))
# 
# # Create summary version of PAF output for experts 
# hap.RR.summary <- hap.RR[, c("age", 
#                              "acause", 
#                              "sex",
#                              "draw_yll_lower", 
#                              "draw_yll_mean", 
#                              "draw_yll_upper"), 
#                          with=F]
# 
# 
# hap.RR <- as.data.frame(matrix(as.integer(NA), nrow=nrow(age.cause.sex), ncol=1000+3))
# 
# for (iii in 1:nrow(age.cause.sex)) {
#   ccc <- age.cause.sex[iii, 1]
#   aaa <- age.cause.sex[iii, 2]
#   sss <- age.cause.sex[iii, 3] 
#   
#   if (sss == 1) {hap.exp <- HAP.country.exp[sex=="men"]} # male exposure -> taken from Astha
#   if (sss == 2) {hap.exp <- HAP.country.exp[sex=="women"]} # female exposure -> taken from Astha
#   if (sss == 3) {hap.exp <- HAP.country.exp[sex=="child"]} # child exposure -> taken from average of IAP LRI PM concentrations for the input dataset
#   
#   print(paste0("Cause:", ccc, " - Age:", aaa, " - Sex:", sss))
#   
#   for (jjj in 1:1000) {
#     RR <- fobject$eval(as.numeric(hap.exp[draw==(jjj-1), value]), rr.curves[[paste0(ccc, "_", aaa)]][jjj, ]) # Use function object, the exposure, and the RR parameters to calculate PAF (1 at a time, probs could be speeded up if vectorized) note that (jjj-1) is a workaround for the weird GBD2013 standard draws of 0-999 instead of 1-1000
#     hap.RR[iii, jjj] <- RR
#   }
#   
#   # Set up variables
#   hap.RR[iii, 1001] <- as.numeric(aaa)
#   hap.RR[iii, 1002] <- ccc
#   hap.RR[iii, 1003] <- sss
# }
# 
# names(hap.RR) <- c(paste0("draw_", 0:999), "age", "acause", "sex")
# 
# # Convert from age 99 to the correct ages
# # LRI is between 0 and 5
# for (ccc in c("lri")) {
#   # Take out this cause
#   temp.RR <- hap.RR[hap.RR$acause == ccc, ]
#   hap.RR <- hap.RR[!hap.RR$acause == ccc, ]                       
#   
#   # Add back in with proper ages
#   if (ccc == "lri") ages <- c(0, 0.01, 0.1, 1, seq(5, 80, by=5)) # LRI is between 0 and 5 # LRI is now being calculated for all ages based off the input data for LRI and smokers
#   
#   for (aaa in ages) {
#     temp.RR$age <- aaa
#     hap.RR <- rbind(hap.RR, temp.RR)
#   }
# }
