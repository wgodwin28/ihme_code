cw_indi <- function(mydat = ptdat, var_family = indi_fam) {
  if (var_family == 'water') {
  attach(mydat)
  ratio_sp <- mean(spring_imp)/(mean(spring_imp) + mean(spring_unimp))
  ratio_wl <- mean(well_imp)/(mean(well_imp) + mean(well_unimp)) 
  detach(mydat)
  
  mydat <- mydat %>%
           mutate(unimp = bottled + bottled_sp*(1 - ratio_sp) + bottled_wl*(1 - ratio_wl) +
                          spring_unimp + spring_cw*(1 - ratio_sp) + well_cw*(1 - ratio_wl) +
                          well_unimp + unimp,
                  imp = bottled_sp*(ratio_sp) + bottled_wl*(ratio_wl) + well_imp + well_cw*(ratio_wl) +
                        spring_cw*(ratio_sp) + spring_imp + imp) %>%
           select(id_short, nid, iso3, lat, long, survey_series, urban, year_start, total_hh,
                  piped, surface, imp, unimp)
  return(mydat)
  
  } else {message("Other indicator families coming soon...")}
  
  
}

