### WATER ###
  repo <- '/share/code/geospatial/adesh/mbg/'
  indicator_group <- 'wash'

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
  source('mbg_central/stacking_functions.R')
  source('mbg_central/categorical_variable_functions.R')
  source('mbg_central/seegMBG_transform_functions.R')     # Using Roy's edit for now that can take temporally varying covariates,
  #   TODO: will need to send pull request to seegMBG of github
  package_list <- c('foreign', 'rgeos', 'data.table','raster','rgdal','INLA','seegSDM','seegMBG','plyr','dplyr')
  for(package in package_list) {
    library(package, lib.loc = package_lib, character.only=TRUE)
  }
  
Regions <- c('cwssa','sssa', 'na_essa')
indicator_group <- 'wash'
indicator <- 'w_piped'
run_date <- '2017_02_11_10_45_09'
#gaul_list <- get_gaul_codes("africa")

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
writeRaster(m, file = '/homes/adesh/w_piped', format = 'GTiff',overwrite = T)


#shiny_data_and_preds(gaul_list = gaul_list,
#                     run_date = run_date,
#                     indicator = indicator,
#                     indicator_group = indicator_group,
#                     pred_file = paste0(indicator, '_mean_raster.tif'),
#                     layer_name = paste0(indicator, '_mean_raster.')) 


					 
## HANDWASHING ####					 
Regions <- c('cwssa','na_essa','sssa')
indicator_group <- 'wash'
indicator <- 'hw_no_facility'

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
