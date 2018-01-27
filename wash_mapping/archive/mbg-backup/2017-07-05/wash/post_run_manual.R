repo <- '/share/code/geospatial/adesh/mbg/'
indicator_group <- 'wash'
indi <- c('w_piped','w_imp','w_unimp','w_surface')
Regions=c('sssa_hi','cssa','name_hi')
validation <- F
raking <- F
rd <- c('2017_06_20_11_09_36','2017_06_20_11_09_41','2017_06_20_11_09_32','2017_06_20_11_09_36')
strata <- Regions

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


for (i in 1:4) {
  run_date <- rd[i]
  indicator <- indi[i]
  
  message(run_date)
  message(indicator)
  for (reg in strata) {

    ## Save strata for Shiny to use in producing aggregated fit statistics
    dir.create(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/fit_stats'))
    save(strata, file = paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/fit_stats/strata.RData'))

    message(paste(reg,": Loading Data"))
    load(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/', indicator, '_cell_draws_eb_bin0_', reg, '_0.RData'))

    message("Making Simple Raster")
    ## Load simple rasters
    gaul_list <- get_gaul_codes(reg)
    suppressMessages(suppressWarnings(simple_polygon_list <- load_simple_polygon(gaul_list = gaul_list,
                                                                             buffer = 0.4)))
    subset_shape     <- simple_polygon_list[[1]]
    raster_list <- suppressMessages(suppressWarnings(build_simple_raster_pop(subset_shape)))
    simple_raster <- raster_list[['simple_raster']]

    message('Making Mean Raster')
    mean_raster <- make_cell_pred_summary( draw_level_cell_pred = cell_pred,
                                       mask                 = simple_raster,
                                       return_as_raster     = TRUE,
                                       summary_stat         = 'median')

    message("Saving Mean Raster")
    save_post_est(mean_raster,'raster',paste0(reg,'mean_raster'))
  }
}
