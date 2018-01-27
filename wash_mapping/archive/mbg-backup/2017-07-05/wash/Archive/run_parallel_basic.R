
## GET SET UP FROM THE QSUB CALL

reg=as.character(commandArgs()[3])
age=as.numeric(commandArgs()[4])
run_date=as.character(commandArgs()[5])
test=as.character(commandArgs()[6])
holdout=as.character(commandArgs()[7])
indicator=as.character(commandArgs()[8])
indicator_group=as.character(commandArgs()[9])

pathaddin = paste0('_bin',age,'_',reg,'_',holdout)
message(pathaddin)
message(run_date)
message(test)

## Load image saved from make_qsub in launch_lri_by_region
load(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/model_image_history/pre_run_tempimage_', run_date, pathaddin,'.RData'))

## Load libraries and miscellaneous MBG project functions.
  setwd(repo)
  root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
  package_lib <- paste0(root,'/temp/geospatial/packages') # Library for all MBG versioned packages. Ensures that none of this code is
                                                          #   dependent on the machine where the user runs the code.
  .libPaths(package_lib)                                  # Ensures packages look for dependencies here when called with library(). Necessary for seeg libraries.
  source('mbg_central/mbg_functions.R')                   # Functions to run MBG model.
  source('mbg_central/prep_functions.R')                  # Functions to setup MBG run
  source('mbg_central/covariate_functions.R')             # Functions to prep and transform 5*5 covariates
  source('mbg_central/misc_functions.R')                  # Other computational MBG-related functions.
  source('mbg_central/post_estimation_functions.R')
  source('mbg_central/gbd_functions.R')
  source('mbg_central/shiny_functions.R')
  source('mbg_central/stacking_functions.R')
  source('mbg_central/categorical_variable_functions.R')
  source('mbg_central/seegMBG_transform_functions.R')     # Using Roy's edit for now that can take temporally varying covariates,
#   TODO: will need to send pull request to seegMBG of github
  package_list <- c('foreign', 'rgeos', 'snow','snowfall',
                    'sp', 'data.table','rgdal','INLA','seegSDM','seegMBG','plyr','dplyr')
  for(package in package_list) {
    library(package, lib.loc = package_lib, character.only=TRUE)
  }


## ~~~~~~~~~~~~~~~~~~~~~~~~ Prep MBG inputs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cores_to_use <- round(slots*.5)
  
## Load simple polygon template to model over
  gaul_list <- get_gaul_codes(reg)
  suppressMessages(suppressWarnings(simple_polygon_list <- load_simple_polygon(gaul_list = gaul_list,
                                                                               buffer = 0.4)))
  subset_shape     <- simple_polygon_list[[1]]
  simple_polygon   <- simple_polygon_list[[2]]

## Load list of raster inputs (pop and simple)
  raster_list <- suppressMessages(suppressWarnings(build_simple_raster_pop(subset_shape)))
  simple_raster <- raster_list[['simple_raster']]
  pop_raster <- raster_list[['pop_raster']]

## Load input data based on stratification and holdout, OR pull in data as normal and run with the whole dataset if holdout == 0.
  if(holdout==0) {
    df <- load_input_data(indicator = indicator,
                          simple = simple_polygon,
                          removeyemen = TRUE,
                          pathaddin = pathaddin)
  }


##################################################################################################
############################### STACKING #########################################################
##################################################################################################

#make covariates conditional
  cov_layers = NULL
  gbd_cov_layers = NULL
  mbg_cov_layers = NULL

# Pull all covariate bricks/layers
  if(nchar(fixed_effects)> 0){
    cov_layers <- suppressMessages(suppressWarnings(load_and_crop_covariates(fixed_effects = fixed_effects, 
                                                                             simple_raster = simple_raster)))
  }
  
  # if(nchar(gbd_fixed_effects)>0){
  #   gbd_cov_layers <- suppressMessages(suppressWarnings(load_gbd_covariates(gbd_fixed_effects, c(2000,2005,2010,2015), gaul_list)))
  # }
  # if(nchar(mbg_fixed_effects)>0){
  #   mbg_cov_layers <- suppressMessages(suppressWarnings(load_mbg_covariates(mbg_fixed_effects, simple_raster)))
  # }


## Combine all the covariate layers we want to use and combine our fixed effects formula
  all_cov_layers <- c(cov_layers) #, gbd_cov_layers, mbg_cov_layers)
  effects = c(fixed_effects) #, gbd_fixed_effects, mbg_fixed_effects)
  all_fixed_effects <- paste(effects[!is.na(effects)&effects!=""], collapse=" + ")

  ## Build spatial mesh over modeling area
  mesh_s <- build_space_mesh(d = df,
                             simple = simple_polygon,
                             max_edge = mesh_s_max_edge,
                             mesh_offset = mesh_s_offset)
  
  ## Build temporal mesh (standard for now)
  mesh_t <- build_time_mesh()
  
  ## Save all inputs for MBG model into correct location on /share
  save_mbg_input(indicator = indicator, 
                 indicator_group = indicator_group,
                 df = df,
                 simple_raster = simple_raster,
                 mesh_s = mesh_s,
                 mesh_t = mesh_t, 
                 cov_list = all_cov_layers,
                 run_date = run_date,
                 pathaddin = pathaddin,
                 all_fixed_effects = all_fixed_effects)
  load(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/model_image_history/', run_date, pathaddin, '.RData'))
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~ Run MBG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  ## Generate MBG formula for INLA call
  mbg_formula <- build_mbg_formula(fixed_effects = all_fixed_effects)
  
  ## Create SPDE INLA stack
  input_data <- build_mbg_data_stack(df = df,
                                     fixed_effects = all_fixed_effects,
                                     mesh_s = mesh_s,
                                     mesh_t = mesh_t)
  stacked_input <- input_data[[1]]
  spde <- input_data[[2]]
  cs_df <- input_data[[3]]
  
  ## Generate other inputs necessary
  outcome=df[[indicator]] # N+_i - event obs in cluster
  N=df$N                  # N_i - total obs in cluster
  
  ## Fit MBG model
  model_fit <- fit_mbg(indicator_family = indicator_family,
                       stack.obs = stacked_input,
                       spde = spde,
                       cov = outcome,
                       N = N,
                       int_prior_mn = intercept_prior,
                       f_mbg = mbg_formula,
                       run_date = run_date,
                       keep_inla_files = keep_inla_files,
                       cores = cores_to_use)
  
  predict_mbg <- predict_mbg(res_fit = model_fit,
                             cs_df = cs_df,
                             mesh_s = mesh_s,
                             mesh_t = mesh_t,
                             cov_list = all_cov_layers,
                             samples = samples,
                             simple_raster = simple_raster,
                             transform = transform)
  mean_ras <- predict_mbg[[1]]
  sd_ras <- predict_mbg[[2]]
  cell_pred <- predict_mbg[[3]]

##################################################################################################
############################### SAVE AND CROSS-VAL ##### #########################################
################################################################################################## 
  ## Save MBG outputs in standard outputs folder structure
  save_mbg_preds(config = config,
                 time_stamp = time_stamp,
                 run_date = run_date,
                 mean_ras = mean_ras,
                 sd_ras = sd_ras,
                 res_fit = model_fit,
                 cell_pred = cell_pred,
                 df = df,
                 pathaddin = pathaddin)
  

## summarize raked predictions for each cell
mean_raster <- make_cell_pred_summary( draw_level_cell_pred = cell_pred,
                                       mask                 = simple_raster,
                                       return_as_raster     = TRUE,
                                       summary_stat         = 'mean')

## save important post estimation things
save(mean_raster, file = paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/', 
                                                                indicator, '_', reg, '_mean_raster.RData'))

## Remove temporary image
file.remove(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/model_image_history/pre_run_tempimage_', run_date, pathaddin,'.RData'))

