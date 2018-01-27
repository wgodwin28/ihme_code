###########################################################################################
###########################################################################################
## Run MBG model for proportion of women with zero years of education
## Nick Graetz
## source('/share/code/geospatial/ngraetz/mbg/lri/launch_has_lri_region.R')
## qsub -e /share/temp/sgeoutput/ngraetz/errors -o /share/temp/sgeoutput/ngraetz/output -cwd -pe multi_slot 30 -P proj_geospatial -N bw_annual /share/code/geospatial/ngraetz/mbg/lri/r_shell.sh /share/code/geospatial/ngraetz/mbg/child_growth_failure/launch.R   
###########################################################################################
###########################################################################################

## Set repo location and indicator group
repo <- '/share/code/geospatial/adesh/mbg/'
indicator_group <- 'wash'
indicator <- as.character(commandArgs()[3])
Regions=c('sssa', 'cwssa', 'name', 'essa')

## Load libraries and miscellaneous MBG project functions.
setwd(repo)
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
package_lib <- "/homes/azimmer/geos_server_R_libs" # Library for all MBG versioned packages. Ensures that none of this code is
#    dependent on the machine where the user runs the code.
.libPaths(package_lib)                                  # Ensures packages look for dependencies here when called with library(). 

# TEMP FIX #
#install.packages('dplyr', dependencies = T, lib = package_lib, repos = "http://cran.us.r-project.org")
library('dplyr')

#    Necessary for seeg libraries.
source('mbg_central/mbg_functions.R')                   # Functions to run MBG model.
source('mbg_central/prep_functions.R')                  # Functions to setup MBG run
source('mbg_central/covariate_functions.R')             # Functions to prep and transform 5*5 covariates
source('mbg_central/misc_functions.R')                  # Other computational MBG-related functions.
source('mbg_central/post_estimation_functions.R')
source('mbg_central/gbd_functions.R')
source('mbg_central/shiny_functions.R')
source('mbg_central/holdout_functions.R')
source('mbg_central/categorical_variable_functions.R')
source('mbg_central/validation_functions.R') 
source('mbg_central/seegMBG_transform_functions.R')     # Using Roy's edit for now that can take temporally varying covariates,
#   TODO: will need to send pull request to seegMBG of github
package_list <- c('foreign', 'rgeos', 'data.table','raster','rgdal','INLA','seegSDM','seegMBG','plyr', 'dplyr')
for(package in package_list) {
  library(package, lib.loc = package_lib, character.only=TRUE)
}



## Read config file and save all parameters in memory
config <- load_config(repo = repo,
                      indicator_group = indicator_group,
                      indicator = indicator)

## Create run date in correct format
run_date <- make_time_stamp(time_stamp)

## Create directory structure for this model run
create_dirs(indicator_group = indicator_group,
            indicator = indicator)

## Set strata as character vector of each strata (in my case, just stratifying by region whereas U5M stratifies by region/age)
strata <- Regions

## ~~~~~~~~~~~~~~~~~~~~~~~~  Parallel MBG  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## ~~~~~~~~~~~~~~~~~ Submit job by strata/holdout  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

parallel_script <- 'run_stack_nocv'
slots <- as.numeric(slots)
sharedir       <- sprintf('/share/geospatial/mbg/%s/%s',indicator_group,indicator)

reg=as.character(commandArgs()[3])
age=as.numeric(commandArgs()[4])
run_date=as.character(commandArgs()[5])
test=as.character(commandArgs()[6])
holdout=as.character(commandArgs()[7])
indicator=as.character(commandArgs()[8])
indicator_group=as.character(commandArgs()[9])


loopvars <- NULL
for(r in strata){
  for(holdout in 0) {
    
    reg <- r; age <- 0; 
    paste("nohup Rscript", parallel_script, '&')
    
    system(qsub)
    
    loopvars <- rbind(loopvars, c(r,holdout))
    
  }
}
  ## check to make sure models are done before continuing
  waitformodelstofinish()
  
for(r in strata){
    
  load(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/', indicator, '_cell_draws_eb_bin0_', reg, '_0.RData'))
  
  ## summarize raked predictions for each cell
  mean_raster <- make_cell_pred_summary( draw_level_cell_pred = cell_pred,
                                         mask                 = simple_raster,
                                         return_as_raster     = TRUE,
                                         summary_stat         = 'median')
  
 
  assign(sprintf('%s_mean_raster',reg),mean_raster)
  rm(mean_raster); rm(cell_pred);
}

## ~~~~~~~~~~~~~~~~~~~~~~~~ Post-Estimation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# combine regions raster
m = do.call(raster::merge,list(name_mean_raster,
                               essa_mean_raster,
                               sssa_mean_raster,
                               wssa_mean_raster,
                               cssa_mean_raster))

save_post_est(m,'raster','mean_raster')
