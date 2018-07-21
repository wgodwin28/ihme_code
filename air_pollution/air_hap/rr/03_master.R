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

if (Sys.getenv('SGE_CLUSTER_NAME') == "prod" ) {
  
  project <- "-P proj_custom_models " # -p must be set on the production cluster in order to get slots and not be in trouble
  #project <- "-P proj_crossval"
  sge.output.dir <- "-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors"
  #sge.output.dir <- "" # toggle to run with no output files
  
} else {
  
  project <- "-P proj_custom_models " # dev cluster has project classes now too
  sge.output.dir <- "-o /homes/wgodwin/output/ -e /homes/wgodwin/errors/"
  #sge.output.dir <- "" # toggle to run with no output files
  
}

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
  
#----FUNCTIONS----------------------------------------------------------------------------------------------------------  
##function lib##
#PAF functions#
paf.function.dir <- file.path(h_root, 'risk_factors2/air_pollution/air_pm/paf/_lib')  
file.path(paf.function.dir, "paf_helpers.R") %>% source  
  
#RR functions#
rr.function.dir <- file.path(h_root, 'risk_factors2/air_pollution/air_pm/rr/_lib') 
file.path(rr.function.dir, "functional_forms.R") %>% source
fobject <- get(rr.functional.form)  

#AiR HAP functions#
hap.function.dir <- file.path(h_root, 'risk_factors2/air_pollution/air_hap/rr/_lib')
# this pulls the miscellaneous helper functions for air pollution
file.path(hap.function.dir, "misc.R") %>% source()

#general functions#
central.function.dir <- file.path(h_root, "risk_factors2/air_pollution/air_hap/rr/_lib")
get.locations.dir <- file.path(j_root, "temp/central_comp/libraries/current/r")
# this pulls the general misc helper functions
file.path(central.function.dir, "misc.R") %>% source()
# this pulls the current locations list
file.path(get.locations.dir, "get_location_metadata.R") %>% source()
#***********************************************************************************************************************  
 
#----PREP DATA----------------------------------------------------------------------------------------------------------
if (prep.data == TRUE) {

	exposure.dir <- file.path(home.dir, "02_rr/02_output/01_pm_mapping/lit_db/xwalk_output")
	exposure.version <- "010818"
	#exposure.version <- format(Sys.Date(), "%m%d%y")
	# results of RR curve fitting analysis
	# parameters that define these curves are used to generate age/cause specific RRs for a given exposure level
	rr.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm", 'data/rr/output', paste0(rr.data.version, rr.model.version))
	
	out.environment <- paste0(exposure.dir, "/clean.Rdata") #this file will be read in by each parallelized run in order to preserve draw covariance
	#objects exported:
	#HAP.global.exp = file created by Yi containing HAP PM2.5 exposure estimates for all country years
	#age.cause - list of all age-cause pairs currently being calculated
	#all.rr - compiled list of all the RR curves for the ages/causes of interest
	
	# Make a list of all cause-age pairs that we have.
	age.cause <- ageCauseLister(full.age.range = T) 

	# Prep the RR curves into a single object, so that we can loop through different years without hitting the files extra times.
	all.rr <- lapply(1:nrow(age.cause), prepRR, rr.dir=rr.dir)

	# bring in yi's file to scale HAP exposure by region
	HAP.global.exp <- fread(paste0(exposure.dir, "/PM2.5_draws_", exposure.version, ".csv"), stringsAsFactors=F)
	HAP.global.exp <- melt(HAP.global.exp, id=c("location_id", "year_id"), variable.factor = F)
	HAP.global.exp[,c("sex","draw") := as.data.table(str_split_fixed(variable, fixed("_"), 2)[,1:2])]
	HAP.global.exp[is.na(as.numeric(draw))==F, draw := as.numeric(draw) + 1] #this step is done to convert from the weird draw numbering of 0-999 vs 1-1000
	setnames(HAP.global.exp, "value", "exposure")
	HAP.global.exp[,variable := NULL]
	
	
	save(HAP.global.exp,
	     all.rr,
	     age.cause,
	     file=out.environment)
	
}

#***********************************************************************************************************************
 
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