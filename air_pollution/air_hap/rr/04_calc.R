#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 07/10/2015
# Purpose: Execute parallelized calculation of country RRs for HAP 
# Notes: Uses country/year HAP exposure from Yi and the IER curve
# update of source("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/01_gen_RR_hap.R", echo=T)
# source("/homes/wgodwin/risk_factors/jfrostad/air_hap/rr/calc.R", echo=T)
#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j_root <- "/home/j" 
  h_root <- "/homes/wgodwin"
  arg <- commandArgs()[-(1:3)]                  # First args are for unix use only
  #arg <- c(10, "power2", "1", 1000, 6)      #toggle targetted run
  output.dir <- file.path("/share/epi/risk/temp/air_hap/rr")
  
  
} else { 
  
  j_root <- "J:"
  h_root <- "H:"
  arg <- c("AFG", "power2", "3", 1000, 1)
  output.dir <- file.path("J:/WORK/05_risk/risks/air_hap/02_rr/02_output/02_final_prep")
}

print(arg)

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_hap")
#setwd(home.dir)

this.country <-  as.numeric(arg[1])
rr.functional.form <- arg[2]
output.version <- arg[3]
draws.required <- as.numeric(arg[4])
cores.provided <- as.numeric(arg[5])

message(this.country, rr.functional.form, output.version, draws.required, cores.provided)

# r configuration
options(scipen=10) # disable scientific notation because it annoys me, set to display ten digits

# load packages, install if missing
pacman::p_load(data.table, magrittr, parallel, stringr, reshape2)
#******************************************************************************************************************************** 
  
#----FUNCTIONS----------------------------------------------------------------------------------------------------------  
##function lib##
#RR functions#
rr.function.dir <- file.path(h_root, 'risk_factors/air_pollution/air_pm/rr/_lib') 
file.path(rr.function.dir, "functional_forms.R") %>% source
fobject <- get(rr.functional.form)  

#AiR HAP functions#
hap.function.dir <- file.path(h_root, 'risk_factors/air_pollution/air_hap/rr/_lib')
# this pulls the miscellaneous helper functions for air pollution
file.path(hap.function.dir, "misc.R") %>% source()

#general functions#
get.locations.dir <- file.path(j_root, "temp/central_comp/libraries/current/r")
# this pulls the current locations list
file.path(get.locations.dir, "get_location_metadata.R") %>% source()
#***********************************************************************************************************************
  # LOAD IN THE CLEAN ENVIRONMENT HERE, THEN SUBSET TO COUNTRY/YEAR
  #output.dir <- file.path(home.dir, "02_rr/02_output/02_final_prep/")
  exposure.dir <- file.path(home.dir, "02_rr/02_output/01_pm_mapping/lit_db/xwalk_output")
  out.environment <- paste0(exposure.dir, "/clean.Rdata") #this file will be read in by each parallelized run in order to preserve draw covariance

  ##Load in ambient exposure draws to subtract off of HAP exposure **Added 5/22/17** Decided to switch back to not subtracting off ambient concentrations due to negative HAP exposure issues
  # amb.dir <- file.path("/share/epi/risk/air_pm/exp/22/final_draws")
  # amb.dt <- paste0(amb.dir, "/", this.country, ".csv") %>% fread
  # cols <- paste0("draw_", seq(1, 1000, 1))
  # amb.dt <- amb.dt[, c("year", cols), with=F]
  # amb.dt <- melt(amb.dt, id=c("year"), variable.factor = F)
  # amb.dt[,c("sex","draw") := as.data.table(str_split_fixed(variable, fixed("_"), 2)[,1:2])]
  # amb.dt <- amb.dt[, c("year", "value", "draw"), with=F]
  # setnames(amb.dt, "year", "year_id") 
  
  #objects exported:
  #age.cause - list of all age-cause pairs currently being calculated
  #all.rr - compiled list of all the RR curves for the ages/causes of interest
  load(out.environment)
  HAP.country.exp <- HAP.global.exp[location_id==this.country]
  #HAP.country.exp <- merge(HAP.country.exp, amb.dt, by= c("year_id", "draw"), all.x = T)
  #HAP.country.exp[, exposure := exposure - value]
  print("starting loop over years")
  
years <- unique(HAP.global.exp$year_id)
#years <- c(1990, 1995, 2000, 2005, 2010, 2013, 2015, 2016)
for(year in years) {
  HAP.country.year.exp <- HAP.country.exp[year_id==year]

  # Calculate Mortality PAFS using custom function
  RR.mort <- mclapply(1:nrow(age.cause),
                           FUN=calculateRRs,
                           exposure.object = HAP.country.year.exp,
                           metric.type = "yll",
                           sex.specific = T,
                           function.cores = 1,
                           draws.required = draws.required,
                           mc.cores = cores.provided) %>% rbindlist

  # Call to a custom function to do some final formatting and generate a lite summary file with mean/CI
  mortality.outputs <- formatAndSummRR(RR.mort, "yll", draws.required, year)

  # Save Mortality PAFs/RRs
  print(paste0("Saving:", "yll_", this.country, "- Year:", year))
  write.csv(mortality.outputs[["summary"]], paste0(output.dir, "/", output.version, "/summary/yll_", this.country, "_", year, ".csv"))
  write.csv(mortality.outputs[["lite"]], paste0(output.dir, "/", output.version, "/lite/yll_", this.country, "_", year, ".csv"))
  write.csv(mortality.outputs[["draws"]], paste0(output.dir, "/", output.version, "/draws/yll_", this.country, "_", year, ".csv"))
}

for(year in years) {
  HAP.country.year.exp <- HAP.country.exp[year_id==year]
  # Calculate Morbidity PAFS using custom function
  RR.morb <- mclapply(1:nrow(age.cause), 
                      FUN=calculateRRs, 
                      exposure.object = HAP.country.year.exp, 
                      metric.type = "yld", 
                      sex.specific = T,
                      function.cores = 1,
                      draws.required = draws.required,
                      mc.cores = cores.provided) %>% rbindlist
  
  # Call to a custom function to do some final formatting and generate a lite summary file with mean/CI
  morbidity.outputs <- formatAndSummRR(RR.morb, "yld", draws.required, year)
  
  # Save Mortality PAFs/RRs
  print(paste0("Saving:", "yld_", this.country, "- Year:", year))
  write.csv(morbidity.outputs[["summary"]], paste0(output.dir, "/", output.version, "/summary/yld_", this.country,  "_", year, ".csv")) 
  write.csv(morbidity.outputs[["lite"]], paste0(output.dir, "/", output.version, "/lite/yld_", this.country, "_", year, ".csv"))
  write.csv(morbidity.outputs[["draws"]], paste0(output.dir, "/", output.version, "/draws/yld_", this.country, "_", year, ".csv"))
}
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

# strList <- function(list) {
#   
#   for (item in 1:length(list)) {
#     
#     print(str(list[[item]]), max = 1)
#     
#   }
# }
# strList(RR.mort)
