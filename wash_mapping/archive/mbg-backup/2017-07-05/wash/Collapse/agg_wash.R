agg_indi <- function(mydat = ptdat, var_family = indi_fam) {
  
  if (var_family == 'water') {
  levels <- c('piped', 'surface','imp','unimp','bottled','bottled_sp','bottled_wl','well_cw',
             'well_imp','well_unimp','spring_cw','spring_imp','spring_unimp')
  }
  
  if (var_family == 'sani') {
    levels <- levels <- c('imp', 'imp_cw','shared','unimp','od','latrine_cw','latrine_imp','latrine_unimp')
  }
  
  results <- list()
  for (i in levels) {
    message(paste("Aggregating",i))
    names(mydat)[which(names(mydat) == i)] <- 'indi'
    
    mydatresults <- mydat %>% mutate(wt_indi = indi*hh_size) %>% 
      group_by(id_short, nid, iso3, lat, long, survey_series, urban, year_start) %>% 
      summarize(wtavg_indi = sum(wt_indi, na.rm = T)/sum(hh_size, na.rm = T),
                total_hh = sum(hh_size))
    
    
    names(mydatresults)[which(names(mydatresults) == 'wtavg_indi')] <- paste0(i)
    results[[length(results)+1]] <- mydatresults
    names(mydat)[which(names(mydat) == 'indi')] <- i
    
    
  }
  
  message("Merging all results...")
  mydat <- Reduce(function(x,y) merge(x,y,all = T),results)
  
  return(mydat)
  
}
