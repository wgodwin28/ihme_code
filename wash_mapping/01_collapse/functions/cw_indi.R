cw_indi <- function(mydat = ptdat, var_family = indi_fam, agg = agg_level, proj = project) {
  if (var_family == 'water') {
  
    attach(mydat)
    if ((mean(spring_imp, na.rm = T) + mean(spring_unimp, na.rm = T)) == 0) {
      mydat$spring_cw <- 0
      ratio_sp <- 1
    } else {
      ratio_sp <- mean(spring_imp, na.rm = T)/(mean(spring_imp, na.rm = T) + mean(spring_unimp, na.rm = T))
    }
    
    if ((mean(well_imp, na.rm = T) + mean(well_unimp, na.rm = T)) == 0) {
      mydat$well_cw <- 0
      ratio_wl <- 1
    } else {
      ratio_wl <- mean(well_imp, na.rm = T)/(mean(well_imp, na.rm = T) + mean(well_unimp, na.rm = T)) 
    }
    detach(mydat)
  
  if (agg == 'country' & proj != 'gbd') {
    mydat <- mydat %>%
      mutate(unimp = bottled + bottled_sp*(1 - ratio_sp) + bottled_wl*(1 - ratio_wl) +
               spring_unimp + spring_cw*(1 - ratio_sp) + well_cw*(1 - ratio_wl) +
               well_unimp + unimp,
             imp = bottled_sp*(ratio_sp) + bottled_wl*(ratio_wl) + well_imp + well_cw*(ratio_wl) +
               spring_cw*(ratio_sp) + spring_imp + imp) %>%
      dplyr::select(nid, iso3, survey_series, year_start,
             piped, surface, imp, unimp, total_hh)
  
  } else if(proj == 'gbd') {
    mydat <- mydat %>%
      mutate(unimp = bottled + bottled_sp*(1 - ratio_sp) + bottled_wl*(1 - ratio_wl) +
               spring_unimp + spring_cw*(1 - ratio_sp) + well_cw*(1 - ratio_wl) +
               well_unimp + unimp,
             imp = bottled_sp*(ratio_sp) + bottled_wl*(ratio_wl) + well_imp + well_cw*(ratio_wl) +
               spring_cw*(ratio_sp) + spring_imp + imp) %>%
      dplyr::select(nid, iso3, survey_series, year_start, piped,
                    se_piped, surface, se_surface, imp, se_imp, unimp, se_unimp)
  } else {
  mydat <- mydat %>%
           mutate(unimp = bottled + bottled_sp*(1 - ratio_sp) + bottled_wl*(1 - ratio_wl) +
                          spring_unimp + spring_cw*(1 - ratio_sp) + well_cw*(1 - ratio_wl) +
                          well_unimp + unimp,
                  imp = bottled_sp*(ratio_sp) + bottled_wl*(ratio_wl) + well_imp + well_cw*(ratio_wl) +
                        spring_cw*(ratio_sp) + spring_imp + imp) %>%
           dplyr::select(id_short, nid, iso3, lat, long, shapefile, location_code, survey_series, urban, year_start,
                  piped, surface, imp, unimp, total_hh)
  }
  return(mydat)
  
  } else {message("Other indicator families coming soon...")}
  
  
}

