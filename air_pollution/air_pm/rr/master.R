#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 01/08/2016
# Purpose: Launch the parallelized calculation of IER curve fitting for GBD2015
# source("/homes/jfrostad/_code/risks/air_pm/rr/master.R", echo=T)
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j_root <- "/home/j/" 
  h_root <- "/homes/jfrostad/"
  
} else { 
  
  j_root <- "J:"
  h_root <- "H:"
  
}

if (Sys.getenv('SGE_CLUSTER_NAME') == "prod" ) {
  
  project <- "-P proj_custom_models " # -p must be set on the production cluster in order to get slots and not be in trouble
  sge.output.dir <- "-o /homes/jfrostad/output/ -e /homes/jfrostad/errors/ "
  #sge.output.dir <- "" # toggle to run with no output files
  
} else {
  
  project <- "-P proj_custom_models " # dev cluster has project classes now too
  project <- "" # but proj_gbd_maps doesn't exist, ask kimberly to create
  sge.output.dir <- "-o /homes/jfrostad/output/ -e /homes/jfrostad/errors/ "
  #sge.output.dir <- "" # toggle to run with no output files
  
}

# load packages, install if missing
pacman::p_load(data.table, magrittr)

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
setwd(home.dir)

# Settings
cores.provided <- 12 #number of cores to request (this number x2 in ordert o request slots, which are a measure of computational time that roughly equal 1/2core)
draws.required <- 1000 #number of draws to create to show distribution, default is 1000 - do less for a faster run
prep.environment <- FALSE #toggle to launch prep code and compile the IER data
age.cause.full <- TRUE #toggle to calculate all age cause combinations, FALSE runs the lite version for testing
models <- c("power2_simsd_source") #power2 function with a source-specific heterogeneity parameter

###in/out###
##in##
code.dir <- file.path(h_root, '_code/risks/air_pm/rr')
  prep.script <- file.path(code.dir, "prep.R")
  model.script <- file.path(code.dir, "fit.R")
r.shell <- file.path(h_root, "_code/_lib/shells/rshell.sh")

# version history
version <- 7 #updated SHS exposure db, updated age_median for stroke/ihd, updated some incorrect data, dropped incidence
#version <- 6 # updated sourcing so NIDs should never be missing
#version <- 5 # outliered some incorrect data points, fixed misextracted ages, and now modifying SD with age age extrap
#version <- 4 # using the model to fit TMREL, so don't define TMREL, and define conc_den as very small if not extracted
#version <- 3 # using average SD for all to see how model follows data generally
#version <- 2 # using the new TMREL and new data
#version <- 1 # using the old TMREL and new data
#********************************************************************************************************************************	
 
#----LAUNCH LOAD-----------------------------------------------------------------------------------------------------------------
# Launch job to prep the clean environment if necessary
if (prep.environment != FALSE) {
  
  # Launch job
  jname.arg <- paste0("_N prep_data_v", version)
  slot.arg <- paste0("-pe multi_slot ", cores.provided/4)
  mem.arg <- paste0("-l mem_free=", cores.provided/2, "G")
  sys.sub <- paste("qsub", project, sge.output.dir, jname.arg, slot.arg, mem.arg)
  args <- paste(version,
                draws.required)
  
  system(paste(sys.sub, r.shell, prep.script, args))
  
  # Prep hold structure
  hold.text <- paste0(" -hold_jid ", jname)
  
} else {
  
  hold.text <- ""
  
}
#********************************************************************************************************************************
 
#----LAUNCH CALC-----------------------------------------------------------------------------------------------------------------
#Launch the jobs to fit IER curves
launchModel <- function(model) {
  
  message("launching IER calculation using ", model)
  
	# Launch jobs
	jname <- paste0("fit_ier_v", version, "_m", model)
	sys.sub <- paste0("qsub ", project, sge.output.dir, " -N ", jname, " -pe multi_slot ", cores.provided*2, " -l mem_free=", cores.provided*4, "G", hold.text)
	args <- paste(model,
	              version,
	              cores.provided,
	              draws.required,
	              age.cause.full)
	
	system(paste(sys.sub, r.shell, model.script, args))
	
}

lapply(models, launchModel)
#*******************************************************************************************************************************