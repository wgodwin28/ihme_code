agg_indi <- function(mydat, var_family, dt_type, agg, proj) {
  
  if (var_family == 'water') {
  levels <- c('piped', 'surface','imp','unimp','bottled','bottled_sp','bottled_wl','well_cw',
             'well_imp','well_unimp','spring_cw','spring_imp','spring_unimp')
  }
  
  if (var_family == 'sani') {
    levels <- c('imp', 'imp_cw','shared','unimp','od','latrine_cw','latrine_imp','latrine_unimp')
  }

if(proj != "gbd"){
  results <- list()
  for (i in levels) {
    message(paste("Aggregating",i))
    names(mydat)[which(names(mydat) == i)] <- 'indi'
    
    if (dt_type == 'pt') {
      if(agg == 'country') {
        
        mydatresults <- mydat %>% mutate(wt_indi = hhweight*indi*hh_size, wt_denom = hhweight*hh_size) %>% 
          group_by(nid, iso3, survey_series, year_start) %>% 
          summarize(wtavg_indi = sum(wt_indi, na.rm = T)/sum(wt_denom, na.rm = T),
                    total_hh = sum(hh_size)) %>%
          mutate(urban = NA)
        
      } else {
        
          mydatresults <- mydat %>% mutate(wt_indi = hhweight*indi*hh_size, wt_denom = hhweight*hh_size) %>% 
                          group_by(id_short, nid, iso3, lat, long, survey_series, urban, year_start, shapefile, location_code) %>% 
                          summarize(wtavg_indi = sum(wt_indi, na.rm = T)/sum(wt_denom, na.rm = T),
                          total_hh = sum(hh_size))
      }
    }

    
    if (dt_type == 'poly') {
      
      if(agg == 'country') {
        
        mydatresults <- mydat %>% mutate(wt_indi = hhweight*indi*hh_size, wt_denom = hhweight*hh_size) %>% 
          group_by(nid, iso3, survey_series, year_start) %>% 
          summarize(wtavg_indi = sum(wt_indi, na.rm = T)/sum(wt_denom, na.rm = T),
                    total_hh = sum(hh_size)) %>%
          mutate(urban = NA)
        
      } else {
      
      mydatresults <- mydat %>% mutate(wt_indi = hhweight*indi*hh_size, wt_denom = hhweight*hh_size) %>% 
                      group_by(id_short, nid, iso3, lat, long, survey_series, year_start, shapefile, location_code) %>% 
                      summarize(wtavg_indi = sum(wt_indi, na.rm = T)/sum(wt_denom, na.rm = T),
                      total_hh = sum(hh_size)) %>%
                      mutate(urban = NA)
      }
    }
    
    names(mydatresults)[which(names(mydatresults) == 'wtavg_indi')] <- paste0(i)
    results[[length(results)+1]] <- mydatresults
    names(mydat)[which(names(mydat) == 'indi')] <- i
    
    
  }
  
  message("Merging all results...")
  mydat <- Reduce(function(x,y) merge(x,y,all = T),results)
  return(mydat)
}  
####Need to confirm that hhweight is multiplied times hhsize!!!###
  if(proj == "gbd"){
    collapsed_gbd <- data.frame()
    mydat <- as.data.table(mydat)
    #levels <- c("piped", "surface")
    for (ind in levels) {
      message(paste("Aggregating",ind))
      surveys <- unique(mydat$nid, na.rm = T)
      surveys <- setdiff(surveys, c(93806, 235215, 286657, 31786, 45549, 11848)) ## problem surveys to debug
      for(id in surveys){
        temp_dat <- filter(mydat, nid == id)
        
        ## Set admin 1 and admin 2 locations to loop over for certain surveys
        ifelse(any(colnames(temp_dat) =="admin_1_id"), admin1_ids <- unique(temp_dat$admin_1_id), admin1_ids <- NULL)
        ifelse(any(colnames(temp_dat) =="admin_1_urban_id"), admin1_urban_ids <- unique(temp_dat$admin_1_urban_id), admin1_urban_ids <- NULL)
        ifelse(any(colnames(temp_dat) =="admin_2_id"), admin2_ids <- unique(temp_dat$admin_2_id), admin2_ids <- NULL)
        
        temp_dat <- as.data.table(temp_dat)
        #setup_design(df = temp_dat, var = ind)
        by_vars <- c('year_start', 'iso3', 'survey_series','nid')
        temp <- collapse_by(df = temp_dat,
                            var = ind,
                            by_vars = by_vars)
        print(paste(id, ind))
        collapsed_gbd <- rbind(collapsed_gbd, temp[, c(by_vars, 'mean', 'se', 'var', 'deff')])
      }  
    }
    return(collapsed_gbd)
  }
}
#31786-all strata missing
#45549-only one psu
#11848-sum(sapply(covmats, ncol)) : invalid 'type' (list) of argument