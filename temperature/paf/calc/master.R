#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: WG
# Date: 02/16/2018
# Purpose: Launch the parallelized calculation of PAF calculation for temperature for GBD2017
# source("/homes/wgodwin/temperature/paf/calc/master.R", echo=T)
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j <- "/home/j/" 
  h <- "/homes/wgodwin/"
  
} else { 
  
  j <- "J:"
  h <- "H:"
  
}

#Set project and error log paths
project <- "-P proj_paf " # -p must be set on the production cluster in order to get slots and not be in trouble
sge.output.dir <- "-o /share/temp/sgeoutput/wgodwin/output/ -e /share/temp/sgeoutput/wgodwin/errors/ "

#pack_lib = '/snfs2/HOME/wgodwin/R'
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
# load packages, install if missing
#pacman::p_load(data.table, magrittr)
require(data.table)
require(magrittr)
require(mapproj)
require(ggplot2)

# set working directories
home.dir <- file.path(j, "WORK/05_risk/risks/temperature/")
setwd(home.dir)

# version history
output.version <- 1 # first version of temperature  PAFs
output.version <- 2 # editing to exponentiate the RR...
output.version <- 3 # testing out saving pafs for save_results
output.version <- 4 # hopefully formatted for save_results correctly now..
output.version <- 5 # with all small islands too
output.version <- 6 # with NZA and mex on just ihd with sdi at .2
output.version <- 7 # with NZA and mex on just ihd with sdi at .5
output.version <- 8 # with NZA and mex on just ihd with sdi at .9
output.version <- 9 # with NZA and mex on just ihd with sdi at location sdi
output.version <- 10 # with NZA and mex with sdi, population fixes
output.version <- 11 # going back to stata model
output.version <- 12 # new mmt tmrel using gompertz formula
output.version <- 13 # new stop-gap on mmt below 0
output.version <- 14 # mmt_dif as tmrel, big changes
output.version <- 15 # back to mmt with gompertz as tmrel, age adjusted model
output.version <- 16 # mmt_dif as tmrel, with age adjusted model
output.version <- 17 # added uncertainty to exposure, testing out
output.version <- 18 # parallelized by cause, pulling betas automatedly
output.version <- 19 # running with models of redistributed data
output.version <- 20 # run with truncated SDI
#output.version <- 21 # run with BRA RR curves
#output.version <- 22 # run with seasonality adjustment in RR curves
output.version <- 23 # run on tier 2s
#output.version <- 24 #

# Settings
rr.data.version <- 7
draws.required <- 1000
years <- c(1990,2005,2017)
in.dir <- paste0("/share/epi/risk/temp/temperature/exp/gridded/")
sdi.dir <- paste0("/share/epi/risk/temp/temperature/exp/sdi/")
pop.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/paf/")
rr.model.version <- 2
rr.functional.form <- "cubspline.sdi.mmt3"
out.dir <- paste0("/share/epi/risk/temp/temperature/paf/", output.version)
lag <- 30
#beta.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/model_output/")
beta.dir <- paste0(j, "temp/Jeff/temperature/combinedAnalysis/")
config_path <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/rr_model_config.csv")
exp.se.dir <- paste0("/share/epi/risk/temp/temperature/exp/standard_error/")
suffix <- ifelse(output.version == 20, "_mmtDif_prPop_braMexNzl.csv", "_mmtDif_prPop_braMexNzl_knots25_season.csv")

#other toggles
prep.se <- F
draw_check <- F
test <- F

###in/out###
##in##
code.dir <- file.path(h, 'temperature/paf/calc')
calc.script <- file.path(code.dir, "paf_calc_child.R")
r.shell <- file.path(h, "risk_factors2/air_pollution/air_hap/rr/_lib/R_shell.sh")

#----FUNCTIONS----------------------------------------------------------------------------------------------------------  
##function lib##
#general functions#
central.function.dir <- file.path(h, "_code/_lib/functions/")

# this pulls the current locations list
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
location_id.list <- get_location_metadata(location_set_id=22)[most_detailed == 1,.(location_id, ihme_loc_id, location_name, parent_id)]
#location_id.list <- get_location_metadata(location_set_id=22)[parent_id == "130",.(location_id, ihme_loc_id)]
#location_id.list <- get_location_metadata(location_set_id=22)[level == 3,.(location_id, ihme_loc_id)]

#Create out directories
dir.create(file.path(out.dir, "summary"), recursive = T)
dir.create(file.path(out.dir, "rr_max"))
dir.create(file.path(out.dir, "save_results/1"), recursive = T)
dir.create(file.path(out.dir, "save_results/0"))

##SDI
source(paste0(j, "temp/central_comp/libraries/current/r/get_covariate_estimates.R"))
dt.sdi <- get_covariate_estimates(covariate_id = 881)
write.csv(dt.sdi, paste0(out.dir, "/sdi.csv"), row.names = F)

###MATCH CAUSE_ID WITH ACAUSE
source(paste0(j, "temp/central_comp/libraries/current/r/get_cause_metadata.R"))
cause.dt <- get_cause_metadata(cause_set_version_id = 264)[,.(acause,cause_id)]
write.csv(cause.dt, paste0(out.dir, "/causes.csv"), row.names = F)

#Draw checker
check_draws <- function(out.dir){  
  cause_ids <- c(494, 587, 589, 493, 322, 698, 387, 509, 328, 297, 515)
  #cause_ids <- c(328, 297, 515)
  dt <- CJ(location_id = unique(location_id.list$location_id), sex_id = c(1,2), year_id = years, cause_id = cause_ids)
  dt[, file_name := paste0("paf_yll_", location_id,"_", year_id,"_", sex_id,"_", cause_id, ".csv")]
  files.pres <- list.files(paste0(out.dir, "/save_results/1/"))
  not.pres <- setdiff(dt$file_name, files.pres)
  dt[file_name %in% not.pres, run := 1]
  dt <- dt[run == 1]
  return(dt)
}
if(draw_check){
  dt.missing <- check_draws(out.dir = out.dir)
  locations <- unique(dt.missing$location_id)
}
#----PREP EXP ERROR DRAWS-----------------------------------------------------------------------------------------------------  
if(prep.se){
  dt.se <- fread(paste0(j, "WORK/05_risk/risks/temperature/data/exp/paf_ready/era_interim_standard_error.csv"))
  hemis <- unique(dt.se$hemi)
  for(hemisph in hemis){
    dt.temp <- dt.se[hemi == hemisph]
    error.colnames <- c(paste0("error_",1:draws.required))
    dt.temp[, (error.colnames) := lapply(1:draws.required, function(x){rnorm(1) * dt.temp[, temp_se] * qnorm(.975)})]
    write.csv(dt.temp, paste0(exp.se.dir, hemisph, "_draws.csv"), row.names = F)
  }
}
#----LAUNCH CALC--------------------------------------------------------------------------------------------------------------
#********************************************************************************************************************************	
# Get the list of most detailed GBD locations
locations <- unique(location_id.list[, location_id]) %>% sort

#Toggles for each run
#causes <- c("cvd_ihd", "ckd", "diabetes", "cvd_stroke","resp_copd", "inj_drowning", "nutrition_pem", "lri")
#causes <- c("lri", "ckd", "diabetes", "cvd_ihd")
#causes <- c("lri", "inj_drowning")
#causes <- c("resp_copd", "lri")
#causes <- c("cvd_htn", "cirrhosis", "resp_asthma", "neonatal", "uri", "sids", "mental_alcohol", "inj_suicide", "tb")
causes <- c("resp_asthma", "uri", "tb")
#locations <- unique(location_id.list[location_id==97, ihme_loc_id]) #toggle for smaller test runs
#locations <- c("197") #targetted run-CHN_492
#locations <- c("7", "197","101", "23", "71", "349", "44979", "44973", "36", "44539")
#locations.remove <- c("101", "23", "71", "349", "44979", "44973", "36", "44539") #Huge locations
#locations <- setdiff(locations, locations.remove)
if(test){
  #years <- 1990
  causes <- "cvd_ihd"
  locations <- c("197")
}

###begin loop that submits jobs by location, year, cause
for(cause in causes) {
  for (year in years) {
    for (location in locations) {
      #define the number of cores to be provided to a given job by the size of the country gridded file
      #larger countries are going to be more memory intensive
      #currently using ifelse to launch with low cores if exp file doesnt exist (will break anyways)
      grid.size <- ifelse(paste0(in.dir, "/loc_", location, "_", year, ".feather") %>% file.exists,
                          file.info(paste0("/share/epi/risk/temp/temperature/exp/gridded/loc_", location, "_", year, ".feather"))$size,
                          1)
      
      ##allocate appropriate number of cores
      if (grid.size > 3.5e7) { 
        cores.provided <- 10 #give 56 cores and 600gb of mem to any files larger than 30mb (canada, some china subnats)
      } else if(grid.size > 2.0e7) {
        cores.provided <- 8 #give 30 cores and 120gb of mem to any files larger than 20mb
      } else if(grid.size > 5.0e6) {
        cores.provided <- 6 #give 10 cores and 80gb of mem to any files larger than 5.0mb
      } else if(grid.size > 1.0e6) {
        cores.provided <- 2 #give 4 cores and 16gb of mem to any files larger than 1mb
      }  else if(grid.size > 5.0e5) {
        cores.provided <- 1 #give 2 cores and 8gb of mem to any files larger than 0.5mb
      }  else cores.provided <- .5 #give 1 core and 4gb of mem to any files less than 0.5mb
      
      if(draws.required<=100){
        cores.provided <- cores.provided/2
        cores.provided <- ifelse(cores.provided < .5, .5, cores.provided)
      }
      message("launching", cause, "PAF calc for loc ", location, "/n --using ", cores.provided*2, " slots")
      
      # Launch jobs for all other locations
      jname <- paste0("paf_v", output.version, "_loc_", location, "_", year, "_", cause)
      if(cores.provided > 9){
        sys.sub <- paste0("qsub ", project, sge.output.dir, " -N ", jname, " -pe multi_slot ", cores.provided*2, " -q all.q@@c2-nodes")
      } else{sys.sub <- paste0("qsub ", project, sge.output.dir, " -N ", jname, " -pe multi_slot ", cores.provided*2)}
      args <- paste(location,
                    year,
                    in.dir,
                    sdi.dir,
                    pop.dir,
                    out.dir,
                    rr.model.version,
                    rr.functional.form,
                    output.version,
                    draws.required,
                    cores.provided,
                    lag,
                    cause,
                    beta.dir,
                    config_path,
                    exp.se.dir,
                    suffix)
      
      system(paste(sys.sub, r.shell, calc.script, args))
    }
  }
} 
#********************************************************************************************************************************
###########################################################################################
#################################################
########################SCRAP####################
#################################################
copy <- F
if(copy){
  old.version <- 23
  new.version <- 20
  old.dir <- paste0("/share/epi/risk/temp/temperature/paf/", old.version)
  new.dir <- paste0("/share/epi/risk/temp/temperature/paf/", new.version)
  cause_ids <- c(297, 515)
  
  for(i in c(0,1)){
    files.all <- list.files(paste0(old.dir, "/save_results/", i,"/"), full.names = T)
    new.dir.temp <- paste0(new.dir, "/save_results/", i, "/")
    for(c in cause_ids){
      files.old <- files.all[grep(c, str_sub(files.all, start = -8))]
      file.copy(files.old, new.dir.temp)
      print(paste0(c, " done"))
    }
  }
}
#uri=328, tb=297, resp_asmtha=515
# tmrel_function <- function(x){
#   35.81728 * exp(-exp(-0.0630098 * (x - 4.76978)))}
# t_1990 <- calc(t_1990, fun=tmrel_function)
# 
# 
# pdf(paste0(j, "WORK/05_risk/risks/temperature/diagnostics/paf/tmrel_map_", date, ".pdf"))
# plot(t_1990, main= "Mean Monthly Temperature TMREL in 1990")
# plot(t_2005, main= "Mean Monthly Temperature TMREL in 2005")
# plot(t_2017, main= "Mean Monthly Temperature TMREL in 2017")
# dev.off()
