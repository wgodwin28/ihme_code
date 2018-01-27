
rm_miss <- function(mydat = ptdat, var_family = indi_fam, agg = agg_level, dt_type = data_type) {
  
  if (var_family == 'water') {
    mydat <- rename(mydat, indi = piped)
  }
  
  if (var_family == 'sani') {
    mydat <- rename(mydat, indi = od)
  }
  
  # Calculate data missingness by cluster
  missing <- mutate(mydat, miss = ifelse(is.na(mydat$indi), 1, 0))
  missing <- mutate(missing, miss_wt = miss*hh_size)
  missing <- missing %>% group_by(id_short) %>% summarise(pct_miss = sum(miss_wt)/sum(hh_size))
  # Remove clusters with more than 20% weighted missingness
  miss_clusters <- dplyr::select(filter(missing, pct_miss > 0.2), id_short)
  mydat <- filter(mydat, !(id_short %in% miss_clusters$id_short))
  
  if(agg == 'country' & dt_type == 'pt') {
    # Calculate weight missingness by cluster for country agg & pts
    missing <- mutate(mydat, miss = ifelse(is.na(mydat$hhweight), 1, 0))
    missing <- mutate(missing, miss_wt = miss*hh_size)
    missing <- missing %>% group_by(id_short) %>% summarise(pct_miss = sum(miss_wt)/sum(hh_size))
  
    miss_clusters <- select(filter(missing, pct_miss > 0.2), id_short)
    mydat <- filter(mydat, !(id_short %in% miss_clusters$id_short))
  }
  
  if (var_family == 'water') {
    mydat <- rename(mydat, piped = indi)
  }
  
  if (var_family == 'sani') {
    mydat <- rename(mydat, od = indi)
  }
  
  return(mydat)
}
  
  
impute_indi <- function(mydat = ptdat, var_family = indi_fam) {
  
  if (var_family == 'water') {
  levels <- c('piped', 'surface','imp','unimp','bottled','bottled_sp','bottled_wl','well_cw',
             'well_imp','well_unimp','spring_cw','spring_imp','spring_unimp')
  }
  
  if (var_family == 'sani') {
    levels <- c('imp', 'imp_cw','shared','unimp','od','latrine_cw','latrine_imp','latrine_unimp')
  }
  
  for (i in levels) {
    message(paste("Imputing",i))
    names(mydat)[which(names(mydat) == i)] <- 'indi'
    
    # Calculated household size weighted means for all clusters
    wtavg <-  mydat %>% mutate(wt_indi = hhweight*indi*hh_size, wt_denom = hhweight*hh_size) %>% group_by(id_short) %>% 
      summarize(wtavg_indi = sum(wt_indi, na.rm = T)/sum(wt_denom, na.rm = T))
    
    # Assign observations with NA indicator value the weighted average for the cluster
    mydat <- left_join(mydat, wtavg, by = "id_short")
    mydat$indi <- ifelse(is.na(mydat$indi), mydat$wtavg_indi, mydat$indi)
    mydat <- dplyr::select(mydat, -wtavg_indi)
    
    names(mydat)[which(names(mydat) == 'indi')] <- i
    
  }
  
  return(mydat)
  
}