#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 01/08/2016
# Purpose: Launch the parallelized calculation of PAF calculation for air PM for GBD2015
# source("/homes/jfrostad/_code/risks/air_pm/paf/master.R", echo=T)
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
#pacman::p_load(data.table, magrittr)
require(data.table)
require(magrittr)

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
setwd(home.dir)

# Settings
rr.data.version <- 7
rr.model.version <- "power2_simsd_source"
rr.functional.form <- "power2"
exp.grid.version <- 16
draws.required <- 1000

###in/out###
##in##
code.dir <- file.path(h_root, '_code/risks/air_pm/paf')
  calc.script <- file.path(code.dir, "calc.R")
r.shell <- file.path(h_root, "_code/_lib/shells/rshell.sh")

# version history
output.version <- 1 # first version of air PM PAFs, using the power2 model with updated 2015 data (rr data v2)
output.version <- 2 # second version of air PM PAFs, updated exposure shapefile to include india urb/rural
output.version <- 3 # should be the same as v2 but need a rerun due to error in a function
output.version <- 4 # new version, using an IER with power2 model with source specific uncertainty term and rr data v5
output.version <- 5 #new test version, should match v5 but also generate summ exposure
output.version <- 6 #new version using grid v13 which should has exp(log()) created draws
output.version <- 7 #rerun of version 4/5, summ exposure was messed up (used v11 exposure)
output.version <- 8 #rerun of v6, using exp v13 (some of them still arent saved so i use a try call to submit)
output.version <- 9 #new run with the updated v7 IER and v14 exposure (uses the logspace draws and new version from mike)
output.version <- 10 #run using v15 exposure (updated version from mike but with draws in normal)
output.version <- 11 #logspace draws in parallelized version. should match v9
output.version <- 12 #should match GBD2015 final but include annual pafs
#********************************************************************************************************************************	

#----FUNCTIONS----------------------------------------------------------------------------------------------------------  
##function lib##
#general functions#
central.function.dir <- file.path(h_root, "_code/_lib/functions/")
# this pulls the general misc helper functions
file.path(central.function.dir, "misc.R") %>% source()
# this pulls the current locations list
file.path(central.function.dir, "get_locations.R") %>% source()
#----LAUNCH CALC--------------------------------------------------------------------------------------------------------
 
#********************************************************************************************************************************	
# Get the list of most detailed GBD locations
location_id.list <- get_locations() %>% data.table # use a function written by mortality (modified by me to use epi db) to pull from SQL
locations <- unique(location_id.list[location_id!=6, ihme_loc_id]) %>% sort
#locations <- unique(location_id.list[location_id==97, ihme_loc_id]) #toggle for smaller test runs
#locations <- c("CHN_492") #targetted run
#locations <- c("GNQ", "IND_43910", "IND_43918", "HUN", "RUS", "ECU", "COD")

  launchModel <- function(country) {
    
    #define the number of cores to be provided to a given job by the size of the country gridded file
    #larger countries are going to be more memory intensive
    #TODO make this more accurate, right now you are kind of just eyeballing it
    
    #currently using ifelse to launch with low cores if exp file doesnt exist (will break anyways)
    grid.size <- ifelse(file.path("/share/gbd/WORK/05_risk/02_models/02_results/air_pm/exp/gridded", exp.grid.version, paste0(country, ".csv")) %>% file.exists,
                        file.info(file.path("/share/gbd/WORK/05_risk/02_models/02_results/air_pm/exp/gridded", exp.grid.version, paste0(country, ".csv")))$size,
                        1)

    if (grid.size > 1e9) { 
      cores.provided <- 50 #give 50 cores and 200gb of mem to any files larger than 1gb
    } else if(grid.size > 25e6) {
      cores.provided <- 40 #give 40 cores and 160gb of mem to any files larger than 25mb
    } else if(grid.size > 25e5) {
      cores.provided <- 20 #give 20 cores and 80gb of mem to any files larger than 2.5mb
    } else cores.provided <- 10 #give 10 cores and 40gb of mem to any files less than 2.5mb
    
    
    message("launching PAF calc for loc ", country, "\n --using ", cores.provided*2, " slots and ", cores.provided*4, "GB of mem")

    	# Launch jobs
    	jname <- paste0("calc_paf_v", output.version, "_loc_", country)
    	sys.sub <- paste0("qsub ", project, sge.output.dir, " -N ", jname, " -pe multi_slot ", cores.provided*2, " -l mem_free=", cores.provided*4, "G")
    	args <- paste(country,
                    rr.data.version,
    	              rr.model.version,
    	              rr.functional.form,
    	              exp.grid.version,
    	              output.version,
    	              draws.required,
    	              cores.provided)
    	
    	system(paste(sys.sub, r.shell, calc.script, args))

  }

  lapply(locations, launchModel)

#********************************************************************************************************************************

