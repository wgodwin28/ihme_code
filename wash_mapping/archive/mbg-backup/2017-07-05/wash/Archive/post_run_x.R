## Set repo location and indicator group
repo <- '/share/code/geospatial/adesh/mbg/'
indicator_group <- 'wash'
indicator <- 'w_piped'
Regions=c('name_hi','essa_hilo','cssa','wssa','sssa_hi')

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
run_date <- as.character(commandArgs()[3])

## Set strata as character vector of each strata (in my case, just stratifying by region whereas U5M stratifies by region/age)
strata <- Regions

# get gbd estimates for raking
gbd <- load_gbd_data(gbd_type = "covariate",
                     gbd_name = 'water_prop',
                     gaul_list = get_gaul_codes('africa'),
                     measure_id = 6,
                     age_group_id = 1,
                     metric_id = 3,
                     year_ids = c(2000:2015))

## Save strata for Shiny to use in producing aggregated fit statistics
dir.create(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/fit_stats'))
save(strata, file = paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/fit_stats/strata.RData'))

rf_list <- list()
m_list <- list()
m_raked_list <- list()

for(reg in strata){
  message(reg)
  message('Loading Data')
  load(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/', indicator, '_cell_draws_eb_bin0_', reg, '_0.RData'))
  
  ## get aggregated estimates for all admin0. Aggregate to level you rake to
  message('Loading Polygons and Building Raster')
  simple_polygon_list <- load_simple_polygon(gaul_list = get_gaul_codes(reg), buffer = 0.4)
  subset_shape   <- simple_polygon_list[[1]]
  simple_polygon <- simple_polygon_list[[2]]
  raster_list    <- build_simple_raster_pop(subset_shape)
  simple_raster  <- raster_list[['simple_raster']]
  pop_raster     <- raster_list[['pop_raster']]
  
  ## Pull 2000-2015 annual population brick using new covariates function
  message('Loading WorldPop')
  pop_raster_annual <- load_and_crop_covariates_annual(covs = 'worldpop',
                                                       measures = 'total',
                                                       simple_polygon = simple_polygon,
                                                       start_year  = 2000,
                                                       end_year    = 2015,
                                                       interval_mo = 12,
                                                       agebin=1)
  pop_raster_annual  <- pop_raster_annual[[1]]
  pop_raster_annual  <- crop(pop_raster_annual, extent(simple_raster))
  pop_raster_annual  <- setExtent(pop_raster_annual, simple_raster)
  pop_raster_annual  <- mask(pop_raster_annual, simple_raster)
  
  ## Copy GBD values across years (because GBD2015 nonfatal didn't produce annual... could interpolate later)
  # new_gbd <- list()
  # for(this_year in c(2000:2015)) {
  #   if(this_year %in% 2000:2004) copied_data <- gbd[year == 2000, ]
  #   if(this_year %in% 2005:2009) copied_data <- gbd[year == 2005, ]
  #   if(this_year %in% 2010:2014) copied_data <- gbd[year == 2010, ]
  #   if(this_year %in% 2015:2015) copied_data <- gbd[year == 2015, ]
  #   copied_data <- copied_data[, year := this_year]
  #   new_gbd[[as.character(this_year)]] <- copied_data
  # }
  # new_gbd <- rbindlist(new_gbd)
  new_gbd <- gbd
  ## Create population weights using the annual brick and feed custom year argument to aggregation function
  message('Making Pop Weights')
  pop_wts_adm0 <- make_population_weights(admin_level   = 0,
                                          simple_raster = simple_raster,
                                          pop_raster    = pop_raster_annual,
                                          gaul_list     = get_gaul_codes(reg))
  
  cond_sim_raw_adm0 <- make_condSim(pop_wts_object = pop_wts_adm0,
                                    gaul_list      = get_gaul_codes(reg),
                                    admin_level    = 0,
                                    cell_pred      = cell_pred,
                                    summarize      = TRUE,
                                    years          = c(2000:2015))
  
  
  # Get raking factors
  # Try logit rake function from Bobby
  # rf <- calc_logit_raking_factors(pop_wts_object = pop_wts_adm0,
  #                                 gaul_list      = get_gaul_codes(reg),
  #                                 admin_level    = 0,
  #                                 cell_pred      = cell_pred)
  # Get raking factors (old method)
  message("Calculating RF")
  rf   <- calc_raking_factors(agg_geo_est = cond_sim_raw_adm0,
                              gaul_list   = gaul_list,
                              rake_to     = new_gbd)
  
  message("Raking Predictions")
  raked_cell_pred <- rake_predictions(raking_factors = rf,
                                      pop_wts_object = pop_wts_adm0,
                                      cell_pred      = cell_pred,
                                      logit_rake     = FALSE)
  
  ## summarize raked predictions for each cell
  message("Making mean raster")
  mean_raster <- make_cell_pred_summary( draw_level_cell_pred = cell_pred,
                                         mask                 = simple_raster,
                                         return_as_raster     = TRUE,
                                         summary_stat         = 'median')
  
  message("Making raked mean raster")
  raked_mean_raster <- make_cell_pred_summary( draw_level_cell_pred = raked_cell_pred,
                                               mask                 = simple_raster,
                                               return_as_raster     = TRUE,
                                               summary_stat         = 'median')
  
  assign(sprintf('%s_rf',reg),rf)
  assign(sprintf('%s_mean_raster',reg),mean_raster)
  assign(sprintf('%s_raked_mean_raster',reg),raked_mean_raster)
  
  rf_list[[length(rf_list)+1]] <- rf
  m_list[[length(m_list)+1]] <- mean_raster
  m_raked_list[[length(m_raked_list)+1]] <- raked_mean_raster
  
  
  rm(mean_raster); rm(raked_mean_raster); rm(raked_cell_pred); rm(cell_pred); rm(pop_wts)
  
}




# combine regions raster (child only for now)
rf <- do.call(rbind.fill, rf_list)
m = do.call(raster::merge, m_list)
m_raked = do.call(raster::merge, m_raked_list)
save_post_est(rf,'csv','rf')
save_post_est(m,'raster','mean_raster')
save_post_est(m_raked,'raster','mean_raked_raster')
