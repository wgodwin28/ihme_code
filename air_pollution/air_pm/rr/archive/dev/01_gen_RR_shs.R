#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 06/25/2015
# Purpose: Parallelized calculation of secondhand smoking RRs 
# based on country exposure from Marie, literature values to transform to PM and the IER curve
# source("/home/j/WORK/05_risk/01_database/02_data/smoking_shs/02_rr/04_models/code/01_gen_SHS_RR.R", echo=T)
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

if (Sys.info()["sysname"] == "Linux") {
  root <- "/home/j" 
  arg <- commandArgs()[-(1:3)]  # First args are for unix use only
} else { 
  root <- "J:"
  arg <- c("GTM", "2000", "10", "stan", "power2", 100, 1, "SHS")
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

# clean working environment (prepped by 01_load.R)
prepped.environment <-  paste0(root, "/WORK/05_risk/01_database/02_data/smoking_shs/02_rr/04_models/data/prepped/clean.Rdata")
#objects imported:
#SHS.global.exp - calculated PM exposure for smokers in a given country year, see calculation steps in master file 00_master_shs.R
#age.cause - list of all age-cause pairs currently being calculated in IER
#rr.curves - compiled list of all the RR curves for the ages/causes of interest)t

functions.file <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/functional_forms_updated.r")
ier.curve.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/output")
rr.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/smoking_shs/02_rr/04_models/output")
# custom functions
function.library <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/lib/functions")

# Get the function object from the functions file. This will provide information about the functional
# form that we are estimating, like the formula, parameters, and initializing values.
source(functions.file)
fobject <- get(functional.form)	

# Bring in RR calculation/formatting functions
source(paste0(function.library, "/analysis.R"))

# LOAD IN THE CLEAN ENVIRONMENT HERE, THEN SUBSET TO COUNTRY/YEAR
load(prepped.environment)

# define the country cigarettes per capita using marie's dataset
SHS.country.exp <- SHS.global.exp[iso3==this.country & year==this.year]
  
age.cause.sex <- NULL

for (cause.code in c("cvd_ihd", "cvd_stroke", "neo_lung", "lri")) {
  if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
    ages <- seq(25, 80, by=5) # CVD and Stroke have age specific results
    sexes <- c(3)
  } else {
    ages <- c(99) # LRI, COPD and Lung Cancer all have a single age RR (though they reference different ages...)
    sexes <- c(3)
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
                    exposure.object = SHS.country.exp, 
                    metric.type = "yll", 
                    sex.specific = F,
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
                    exposure.object = SHS.country.exp, 
                    metric.type = "yll", #note that now morbidity is being calculated the same as mortality, with the rationale that the ratio came from air_PM literature and does not apply to the levels of exposure seen in smoking
                    sex.specific = F,
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

#country.cigs.pc <- cigs.ps[ which(cigs.ps$iso3==this.country),]
#country.year.cigs.ps <- country.cigs.pc$cig_ps[ which(country.cigs.pc$year==this.year)] #reverted to cigarettes per smoker based on the addition of the Semple paper, which defines PM based on a smoking household (no ref to number of smokers)

# shs.RR <- as.data.frame(matrix(as.integer(NA), nrow=nrow(age.cause.sex), ncol=1000+3))
# for (iii in 1:nrow(age.cause.sex)) {
#   ccc <- age.cause.sex[iii, 1]
#   aaa <- age.cause.sex[iii, 2]
#   sss <- age.cause.sex[iii, 3] 
#   
# #   if (sss == 3) {shs.exp.dist <- data.frame(runif(1000, 20, 50))} # SHS exposure -> a distribution of estimated SHS (low household: 20, high household: 50)
#   print(paste0("Cause:", ccc, " - Age:", aaa, " - Sex:", sss))
#   
#   for (jjj in 1:1000) {
# #     shs.exp <- tmred.dist[jjj,] + country.year.cigs.pc * pm.cig.spengler # SHS exposure defined here as the additional contribution per cigarette if living with a smoking (only toggle if using the Spengler estimate) 
#     shs.exp <- country.year.cigs.ps * pm.cig.semple[jjj,] # SHS exposure defined here as the additional contribution per cigarette if living with a smoking (only toggle if using the Semple estimate)     
#     RR <- fobject$eval(shs.exp, rr.curves[[paste0(ccc, "_", aaa)]][jjj, ]) # Use function object, the exposure, and the RR parameters to calculate PAF (1 at a time, probs could be speeded up if vectorized)
#     shs.RR[iii, jjj] <- RR
#   }
#   
#   # Set up variables
#   shs.RR[iii, 1001] <- as.numeric(aaa)
#   shs.RR[iii, 1002] <- ccc
#   shs.RR[iii, 1003] <- sss
# }
# 
# names(shs.RR) <- c(paste0("draw_", 0:999), "age", "acause", "sex")
# 
# # save a lite version for graphing
# shs.RR.lite <- data.table(shs.RR)
# shs.RR.lite <- shs.RR.lite[age == 25 | age == 99]
# write.csv(shs.RR.lite, paste0(rr.dir, "/", rr.version, "/lite/", this.country, "_", this.year, ".csv"))
# 
# # create a list of draw names based on the required number of draws for this run
# rr.draw.colnames <- c(paste0("draw", 0:999))
# 
# # generate mean and CI for summary shs.RR.summary
# shs.RR <- as.data.table(shs.RR)
# shs.RR[,draw_yll_lower := quantile(.SD ,c(.025)), .SDcols=rr.draw.colnames, by=list(cause,age,sex)]
# shs.RR[,draw_yll_mean := rowMeans(.SD), .SDcols=rr.draw.colnames, by=list(cause,age,sex)]
# shs.RR[,draw_yll_upper := quantile(.SD ,c(.975)), .SDcols=rr.draw.colnames, by=list(cause,age,sex)]
# 
# #Order columns to your liking
# shs.RR <- setcolorder(shs.RR.summary, c("cause", 
#                                             "age",
#                                         "sex",
#                                             "draw_yll_lower", 
#                                             "draw_yll_mean", 
#                                             "draw_yll_upper", 
#                                             RR.draw.colnames))
# 
# # Create summary version of PAF output for experts 
# shs.RR.summary <- shs.RR[, c("age", 
#                                        "cause", 
#                              "sex",
#                                          "draw_yll_lower", 
#                                          "draw_yll_mean", 
#                                          "draw_yll_upper"), 
#                                      with=F]
# 
# write.csv(shs.RR.summary, paste0(rr.dir, "/", rr.version, "/summary/", this.country, "_", this.year, ".csv"))
# 
# # Convert from age 99 to the correct ages
# # LRI is between 0 and 5
# for (ccc in c("lri", "neo_lung")) {
#   # Take out this cause
#   temp.RR <- shs.RR[shs.RR$acause == ccc, ]
#   shs.RR <- shs.RR[!shs.RR$acause == ccc, ]  	
#   
#   # Add back in with proper ages
#   if (ccc == "lri") ages <- c(0, 0.01, 0.1, 1, seq(5, 80, by=5)) # LRI is between 0 and 5 # LRI is now being calculated for all ages based off the input data for LRI and smokers
#   if (ccc %in% c("neo_lung", "resp_copd")) ages <- seq(25, 80, by=5) # others are between 25 and 80
# 
#   for (aaa in ages) {
#     temp.RR$age <- aaa
#     shs.RR <- rbind(shs.RR, temp.RR)
#   }
# }
# 
# write.csv(shs.RR, paste0(rr.dir, "/", rr.version, "/", this.country, "_", this.year, ".csv"))
# 
# }