## Set repo location and indicator group
repo <- '/share/code/geospatial/adesh/mbg/'
indicator_group <- 'wash'
indicator <- 'w_treat'
Regions=c(217)

## Load libraries and miscellaneous MBG project functions.
setwd(repo)
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
package_lib <- paste0(root,'/temp/geospatial/packages') # Library for all MBG versioned packages. Ensures that none of this code is
#    dependent on the machine where the user runs the code.
.libPaths(package_lib)                                  # Ensures packages look for dependencies here when called with library(). 
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
source('mbg_central/seegMBG_transform_functions.R')     # Using Roy's edit for now that can take temporally varying covariates,
#   TODO: will need to send pull request to seegMBG of github
package_list <- c('foreign', 'rgeos', 'snow','snowfall',
                  'sp', 'data.table','raster','rgdal','INLA','seegSDM','seegMBG','plyr','dplyr')
for(package in package_list) {
  library(package, lib.loc = package_lib, character.only=TRUE)
}
sharedir       <- sprintf('/share/geospatial/mbg/%s/%s',indicator_group,indicator)
## Read config file and save all parameters in memory
config <- load_config(repo = repo,
                      indicator_group = indicator_group,
                      indicator = indicator)

## Create run date in correct format
run_date <- make_time_stamp(time_stamp)

## Create directory structure for this model run
create_dirs(indicator_group = indicator_group,
            indicator = indicator)

## Load simple polygon template to model over
gaul_list <- 217
simple_polygon_list <- load_simple_polygon(gaul_list = gaul_list,
                                           buffer = 0.4)
subset_shape   <- simple_polygon_list[[1]]
simple_polygon <- simple_polygon_list[[2]]
raster_list    <- build_simple_raster_pop(subset_shape)
simple_raster  <- raster_list[['simple_raster']]
pop_raster     <- raster_list[['pop_raster']]

## Load input data and make sure it is cropped to modeling area
df <- load_input_data(indicator = indicator,
                      simple = simple_polygon,
                      removeyemen = TRUE)

## Add GAUL_CODE and region to df given the lat/longs. We need this to stratify in holdout function.
#   df <- add_gauls_regions(df = df,
#                           simple_raster = simple_raster)
# 
# ## Run function to create holdouts (returns list of data.frames with an additional "folds" column)
#   table(df$region, df$year)
#   long_col = 'longitude'
#   lat_col = 'latitude'
#   n_folds = as.numeric(n_folds)
#   stratum_qt <- make_folds(data = df, n_folds = n_folds, spat_strat = spat_strat,
#                            temp_strat = temp_strat, strat_cols = "region",
#                            ts = 20, mb = 10)

## Set strata as character vector of each strata (in my case, just stratifying by region whereas U5M stratifies by region/age)
strata <- Regions

## ~~~~~~~~~~~~~~~~~~~~~~~~  Parallel MBG  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## ~~~~~~~~~~~~~~~~~ Submit job by strata/holdout  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# get gbd estimates for raking
# gbd <- load_gbd_data(gbd_type = "output",
#                      gbd_name = 322,
#                      gaul_list = get_gaul_codes('africa'),
#                      measure_id = 5,
#                      age_group_id = 1,
#                      metric_id = 3)

## This is where we begin to do things by region
# if(stacking_method=='brt') parallel_script <- 'mbg_byregion_brt'
# if(stacking_method=='gam') parallel_script <- 'mbg_byregion'
parallel_script <- 'run_parallel_stacking_sen'
slots=48
n_folds = 0
slots=48
n_folds = 0
loopvars <- NULL

for(r in strata){
  for(holdout in 0:n_folds) {
    
    qsub <- make_qsub(code = parallel_script,
                      reg = r,
                      saveimage = T,
                      test = T,
                      holdout = holdout)
    
    #system(qsub)
    
    loopvars <- rbind(loopvars, c(r,holdout))
  }
}

waitformodelstofinish()

mean_ras_list <- list()
for (i in 1:length(Regions)) {
load(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/', 
                                              indicator, '_', Regions[i], '_mean_raster.RData'))
  mean_ras_list[[i]] <- mean_raster
}

if(length(mean_ras_list)>1) {
  m <- do.call(raster::merge,mean_ras_list) }

if (length(mean_ras_list)==1) {m <- mean_ras_list[[1]]}

save_post_est(m,'raster','mean_raster')

shiny_data_and_preds(gaul_list = gaul_list,
                     run_date = run_date,
                     indicator = indicator,
                     
                     indicator_group = indicator_group,
                     pred_file = paste0(indicator, '_mean_raster.tif'),
                     layer_name = paste0(indicator, '_mean_raster.')) 