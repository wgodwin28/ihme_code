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

  #all.rr - compiled list of all the RR curves for the ages/causes of interest
  load(out.environment)
  HAP.country.exp <- HAP.global.exp[location_id==this.country]
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
