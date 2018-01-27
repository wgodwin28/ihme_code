if (raking) {
  # get gbd estimates for raking
  gbd <- load_gbd_data(gbd_type = "covariate",
                       gbd_name = 'water_prop',
                       gaul_list = get_gaul_codes('africa'),
                       measure_id = 6,
                       age_group_id = 1,
                       metric_id = 3,
                       year_ids = c(2000:2015))
  
  
  
}

## Save strata for Shiny to use in producing aggregated fit statistics
dir.create(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/fit_stats'))
save(strata, file = paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/fit_stats/strata.RData'))

# Post estimation to be done by strata (in my case, this is just region)
# To-Do: parallelize this loop

  message(reg)
  
  load(paste0('/share/geospatial/mbg/', indicator_group, '/', indicator, '/output/', run_date, '/', indicator, '_cell_draws_eb_bin0_', reg, '_0.RData'))
  
  
  if (raking) {
    ## get aggregated estimates for all admin0. Aggregate to level you rake to
    simple_polygon_list <- load_simple_polygon(gaul_list = get_gaul_codes(reg), buffer = 0.4, subset_only = TRUE)
    subset_shape   <- simple_polygon_list[[1]]
    simple_polygon <- simple_polygon_list[[2]]
    raster_list    <- build_simple_raster_pop(subset_shape)
    simple_raster  <- raster_list[['simple_raster']]
    pop_raster     <- raster_list[['pop_raster']]
    
    ## Pull 2000-2015 annual population brick using new covariates function
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
    rf   <- calc_raking_factors(agg_geo_est = cond_sim_raw_adm0,
                                gaul_list   = gaul_list,
                                rake_to     = new_gbd)
    
    raked_cell_pred <- rake_predictions(raking_factors = rf,
                                        pop_wts_object = pop_wts_adm0,
                                        cell_pred      = cell_pred,
                                        logit_rake     = FALSE)
    
    ## summarize raked predictions for each cell
    raked_mean_raster <- make_cell_pred_summary( draw_level_cell_pred = raked_cell_pred,
                                                 mask                 = simple_raster,
                                                 return_as_raster     = TRUE,
                                                 summary_stat         = 'median')
  }
  
  mean_raster <- make_cell_pred_summary( draw_level_cell_pred = cell_pred,
                                         mask                 = simple_raster,
                                         return_as_raster     = TRUE,
                                         summary_stat         = 'median')

  save_post_est(rf,'csv',paste0(reg,'_rf'))
  save_post_est(raked_mean_raster,'raster',paste0(reg,'mean_raked_raster'))
  save_post_est(mean_raster,'raster',paste0(reg,'mean_raster'))