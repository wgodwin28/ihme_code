###########################################################################################
###########################################################################################
## Run MBG model for proportion of women with zero years of education
## Nick Graetz
## source('/share/code/geospatial/ngraetz/mbg/lri/launch_has_lri_region.R')
## qsub -e /share/temp/sgeoutput/ngraetz/errors -o /share/temp/sgeoutput/ngraetz/output -cwd -pe multi_slot 30 -P proj_geospatial -N diarrhea_nug_all_fes /share/code/geospatial/ngraetz/mbg/lri/r_shell.sh /share/code/geospatial/ngraetz/mbg/diarrhea/launch.R config_had_diarrhea  
###########################################################################################
###########################################################################################

## Set repo location and indicator group
  repo <- '/share/code/geospatial/adesh/mbg/'
  indicator_group <- 'wash'
  indicator <- commandArgs()[3]
  Regions=c('essa_hilo', 'sssa_hi','wssa','cssa','name_hi')
  validation <- F
  raking <- F
  
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
  source('mbg_central/validation_functions.R') 
  source('mbg_central/seegMBG_transform_functions.R')     # Using Roy's edit for now that can take temporally varying covariates,
  #   TODO: will need to send pull request to seegMBG of github
  package_list <- c('foreign', 'rgeos', 'data.table','raster','rgdal','INLA','seegSDM','seegMBG','plyr','dplyr')
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

  if (validation) {
## Load simple polygon template to model over
  gaul_list <- get_gaul_codes('africa')
  simple_polygon_list <- load_simple_polygon(gaul_list = gaul_list,
                                        buffer = 0.4)
  subset_shape   <- simple_polygon_list[[1]]
  simple_polygon <- simple_polygon_list[[2]]
  raster_list    <- build_simple_raster_pop(subset_shape)
  simple_raster  <- raster_list[['simple_raster']]
  pop_raster     <- raster_list[['pop_raster']]
  
## Load input data and make sure it is cropped to modeling area
  df_list <- load_input_data(indicator = indicator,
                             simple = simple_polygon,
                             removeyemen = TRUE,
                             update_run_date = TRUE)
  df <- df_list[[1]]
  run_date <- df_list[[2]]

## Add GAUL_CODE and region to df given the lat/longs. We need this to stratify in holdout function.
  df <- add_gauls_regions(df = df,
                          simple_raster = simple_raster)

## Run function to create holdouts (returns list of data.frames with an additional "folds" column)
  table(df$region, df$year)
  # long_col = 'longitude'
  # lat_col = 'latitude'
  # n_folds = as.numeric(n_folds)
  # stratum_qt <- make_folds(data = df, n_folds = n_folds, spat_strat = spat_strat,
  #                          temp_strat = temp_strat, strat_cols = "region",
  #                          ts = 20, mb = 10)
  }
  
## ~~~~~~~~~~~~~~~~~~~~~~~~  Parallel MBG  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## ~~~~~~~~~~~~~~~~~ Submit job by strata/holdout  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  strata <- Regions
  slots <- as.numeric(slots)
  sharedir       <- sprintf('/share/geospatial/mbg/%s/%s',indicator_group,indicator)
  loopvars <- NULL
  
  for(r in strata){
    for(holdout in 0) {
      
      qsub <- make_qsub(code = 'parallel_model_full',
                        reg = r,
                        saveimage = TRUE,
                        test = TRUE,
                        holdout = holdout,
                        log_location = 'sharedir')
      
      system(qsub)
      
      loopvars <- rbind(loopvars, c(r,holdout))
      
    }
  }