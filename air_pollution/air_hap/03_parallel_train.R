#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 06/1/2016
# Purpose: Launch RR calculation for household air pollution based on the exposure from Yi and the IER curve
# this is an update of source("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/00_master_hap.R", echo=T)
# source("/homes/wgodwin/risk_factors/air_pollution/air_hap/rr/master.R", echo=T)
#***********************************************************************************************************************

#----CONFIG-------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j_root <- "/home/j" 
  h_root <- "/homes/wgodwin"
  
} else { 
  
  j_root <- "J:"
  h_root <- "H:"
  
}
  
project <- "-P proj_custom_models " # -p must be set on the production cluster in order to get slots and not be in trouble
#project <- "-P proj_crossval"
sge.output.dir <- "-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors"


# load packages, install if missing
pacman::p_load(data.table, magrittr, stringr, reshape2)

# System settings
cores.provided <- 6
rshell <- paste0(h_root, "/risk_factors2/air_pollution/air_hap/rr/_lib/R_shell.sh")
rscript <- paste0(h_root, "/risk_factors2/air_pollution/air_hap/rr/04_calc.R")

# Job settings.
draws.required <- 1000
rr.data.version <- "20"
rr.model.version <- "power2_simsd_source"
rr.functional.form <- "power2"
prep.data <- F

# Versioning
# output.version <- 1 #first test run, using new PM 2.5 model with sdi as covariate
# output.version <- 2 #update to include ambient exposure adjustment(subtraction)
# output.version <- 3 #update after cutting out personal pm adjustment in m/w/child crosswalk
# output.version <- 4 #switching back to no ambient adjustment-should be final version
# output.version <- 5 #fixing issue with TMREL in IER

output.version <- 1 #first test run for GBD 2017
output.version <- 2 #Run through with updated IER for review week

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_hap")
setwd(home.dir)
#----LAUNCH-------------------------------------------------------------------------------------------------------------
#Create appropriate directories to save to
output.dir <- file.path("/share/epi/risk/temp/air_hap/rr")
dir.create(file.path(output.dir, output.version))
dir.create(file.path(output.dir, output.version, "draws"))
dir.create(file.path(output.dir, output.version, "lite"))
dir.create(file.path(output.dir, output.version, "summary"))	

#bring in locations
locations <- get_location_metadata(location_set_id = 22) %>% as.data.table()
locations <- locations[level >= 3,]
locations.list <- unique(locations$location_id)

for (country in locations.list) {
#country <- 10  
  # Launch jobs
  args <- paste(country, rr.functional.form, output.version, draws.required, cores.provided)
    
  jname.arg <- paste0("-N hap_RR_", country, "_", output.version)
  mem.arg <- paste0("-l mem_free=", cores.provided*2, "G")
  slot.arg <- paste0("-pe multi_slot ", cores.provided)
  sys.sub <- paste("qsub", project, sge.output.dir, jname.arg, mem.arg, slot.arg)  

	system(paste(sys.sub, rshell, rscript, args))	
}

#***********************************************************************************************************************